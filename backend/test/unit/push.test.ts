import { describe, expect, it } from 'vitest';
import { AwsSnsTransport, fcmPayload, invalidEndpoint, safePush } from '../../src/modules/notifications/sns.js';

describe('mobile push payload boundary', () => {
  it('uses generic lockscreen copy and only navigation identifiers', () => {
    const msg = safePush({ title: 'Secret group', body: 'Private reason +10 Coins', data: {
      type: 'SESSION_RESULT', event_id: 'RESULT:abc', session_id: 'abc', group_id: 'group',
      coins: '10', journal: 'secret', display_name: 'An', token: 'secret',
    } });
    expect(msg).toEqual({ title: 'DropIt!', body: 'Bạn có thông báo mới. Mở DropIt! để xem.',
      data: { type: 'SESSION_RESULT', event_id: 'RESULT:abc', session_id: 'abc', group_id: 'group' } });
  });
  it('drops malformed or excessively long route values', () => {
    expect(safePush({ title: '', body: '', data: { event_id: 'x'.repeat(129), group_id: 'https://bad/path' } }).data).toEqual({});
  });
  it('wraps FCM v1 inside SNS GCM and sets the mobile channel', () => {
    const payload = JSON.parse(fcmPayload({ title: 'private', body: 'private', data: { type: 'NEW' } }));
    const message = JSON.parse(payload.GCM).fcmV1Message.message;
    expect(message.notification.title).toBe('DropIt!');
    expect(message.android.notification.channel_id).toBe('dropit_events');
    expect(message.data).toEqual({ type: 'NEW' });
    expect(JSON.stringify(payload)).not.toContain('private');
  });
  it('cleans only known invalid endpoint failures', () => {
    expect(invalidEndpoint({ name: 'EndpointDisabledException' })).toBe(true);
    expect(invalidEndpoint({ name: 'NotFoundException' })).toBe(true);
    expect(invalidEndpoint({ name: 'ThrottlingException' })).toBe(false);
  });
  it('rejects non-FCM platform configuration', () => {
    expect(() => new AwsSnsTransport('ap-southeast-1', 'arn:aws:sns:ap-southeast-1:123456789012:app/APNS/wrong'))
      .toThrow('GCM');
  });
});
