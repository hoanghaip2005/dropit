import { CreatePlatformEndpointCommand, PublishCommand, SetEndpointAttributesCommand, SNSClient } from '@aws-sdk/client-sns';
import { sql } from 'kysely';
import type { DB } from '../../shared/db.js';
import type { NotificationSender, PushMessage } from './service.js';

export interface SnsTransport {
  endpoint(token: string): Promise<string>;
  enable(arn: string, token: string): Promise<void>;
  publish(arn: string, message: string): Promise<void>;
}
export class AwsSnsTransport implements SnsTransport {
  private readonly client: SNSClient;
  constructor(region: string, private readonly applicationArn: string) {
    if (!/^arn:aws(?:-cn|-us-gov)?:sns:[a-z0-9-]+:\d{12}:app\/GCM\/.+$/.test(applicationArn)) {
      throw new Error('SNS_PLATFORM_APPLICATION_ARN must identify an SNS GCM platform application');
    }
    this.client = new SNSClient({ region, maxAttempts: 2,
      requestHandler: { connectionTimeout: 3000, requestTimeout: 8000 } });
  }
  async endpoint(token: string) {
    const result = await this.client.send(new CreatePlatformEndpointCommand({ PlatformApplicationArn: this.applicationArn, Token: token }));
    if (!result.EndpointArn) throw new Error('SNS did not return an endpoint');
    return result.EndpointArn;
  }
  async enable(arn: string, token: string) {
    await this.client.send(new SetEndpointAttributesCommand({ EndpointArn: arn, Attributes: { Token: token, Enabled: 'true' } }));
  }
  async publish(arn: string, message: string) {
    await this.client.send(new PublishCommand({ TargetArn: arn, MessageStructure: 'json', Message: message }));
  }
}

/** Lock-screen text must never contain names, journal, appeals, Coins or streak data. */
export function safePush(msg: PushMessage): PushMessage {
  const allowed = ['type', 'event_id', 'session_id', 'group_id'];
  const data = Object.fromEntries(Object.entries(msg.data).filter(([k, v]) => allowed.includes(k) &&
    typeof v === 'string' && v.length <= 128 && /^[A-Za-z0-9_:.\-]*$/.test(v)));
  return { title: 'DropIt!', body: 'Bạn có thông báo mới. Mở DropIt! để xem.', data };
}
export function fcmPayload(msg: PushMessage): string {
  const safe = safePush(msg);
  return JSON.stringify({ default: safe.body, GCM: JSON.stringify({ fcmV1Message: {
    message: { notification: { title: safe.title, body: safe.body }, data: safe.data,
      android: { priority: 'normal', notification: { channel_id: 'dropit_events' } },
      apns: { headers: { 'apns-priority': '5' }, payload: { aps: { sound: 'default' } } },
    },
  } }) });
}
export function invalidEndpoint(error: unknown): boolean {
  return ['EndpointDisabledException', 'NotFoundException'].includes((error as { name?: string })?.name ?? '');
}

export class SnsNotificationSender implements NotificationSender {
  constructor(private readonly db: DB, private readonly transport: SnsTransport) {}
  async register(userId: string, deviceId: string, platform: 'ANDROID' | 'IOS', token: string) {
    // Serialize ownership/rotation; a late logout is scoped to its authenticated user.
    await this.db.transaction().execute(async trx => {
      await sql`select pg_advisory_xact_lock(551338)`.execute(trx);
      const existing = await trx.selectFrom('device_tokens').selectAll().where('token', '=', token).executeTakeFirst();
      let arn = existing?.sns_endpoint_arn;
      if (!arn) arn = await this.transport.endpoint(token);
      try { await this.transport.enable(arn, token); }
      catch (e) {
        if (!invalidEndpoint(e)) throw e;
        arn = await this.transport.endpoint(token);
        await this.transport.enable(arn, token);
      }
      await trx.deleteFrom('device_tokens').where(eb => eb.or([eb('device_id', '=', deviceId), eb('token', '=', token)])).execute();
      await trx.insertInto('device_tokens').values({ user_id: userId, device_id: deviceId, platform, token,
        sns_endpoint_arn: arn, last_seen_at: new Date() }).execute();
    });
  }
  async unregister(userId: string, deviceId: string) {
    await this.db.transaction().execute(async trx => {
      await sql`select pg_advisory_xact_lock(551338)`.execute(trx);
      await trx.deleteFrom('device_tokens').where('user_id', '=', userId).where('device_id', '=', deviceId).execute();
    });
    // Do not delete SNS endpoint: it may already have been rebound by another login.
  }
  async push(userId: string, msg: PushMessage) {
    const devices = await this.db.selectFrom('device_tokens').selectAll().where('user_id', '=', userId).execute();
    let transient = false;
    let accepted = false;
    await Promise.all(devices.map(async device => {
      if (!device.sns_endpoint_arn) return;
      try { await this.transport.publish(device.sns_endpoint_arn, fcmPayload(msg)); accepted = true; }
      catch (e) {
        if (invalidEndpoint(e)) {
          await this.db.deleteFrom('device_tokens').where('id', '=', device.id)
            .where('sns_endpoint_arn', '=', device.sns_endpoint_arn).where('token', '=', device.token).execute();
        } else transient = true;
      }
    }));
    if (transient) throw new Error('Push delivery temporarily unavailable');
    if (!accepted) return 'SKIPPED' as const;
  }
}
