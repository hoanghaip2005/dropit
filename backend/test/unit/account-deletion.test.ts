import { describe, expect, it, vi } from 'vitest';
import { deleteCognitoUser } from '../../src/modules/privacy/account-deletion.js';
import { deletedSubject } from '../../src/shared/auth.js';

describe('account deletion identity boundary', () => {
  it('keeps a deterministic non-reversible tombstone rather than the original subject', () => {
    expect(deletedSubject('private-sub')).toMatch(/^deleted:[a-f0-9]{64}$/);
    expect(deletedSubject('private-sub')).not.toContain('private-sub');
    expect(deletedSubject('other')).not.toBe(deletedSubject('private-sub'));
  });
  it('sends caller access token only to the configured Cognito endpoint', async () => {
    const request = vi.fn().mockResolvedValue(new Response(null, { status: 200 }));
    await deleteCognitoUser('ap-southeast-1', 'caller-token', request);
    expect(request.mock.calls[0][0]).toBe('https://cognito-idp.ap-southeast-1.amazonaws.com/');
    expect(JSON.parse(request.mock.calls[0][1].body)).toEqual({ AccessToken: 'caller-token' });
    expect(request.mock.calls[0][1].headers['X-Amz-Target']).toContain('DeleteUser');
  });
  it('does not report success on a Cognito scope, permission or availability error', async () => {
    for (const status of [400, 403, 500]) {
      await expect(deleteCognitoUser('ap-southeast-1', 'caller-token', vi.fn().mockResolvedValue(new Response(null, { status }))))
        .rejects.toMatchObject({ status: 503, code: 'IDENTITY_DELETION_UNAVAILABLE' });
    }
  });
});
