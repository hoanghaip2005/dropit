import { afterEach, beforeAll, describe, expect, it, vi } from 'vitest';
import { createLocalJWKSet, exportJWK, generateKeyPair, SignJWT } from 'jose';
import { CognitoJwksVerifier, createTokenVerifier, Hs256Verifier } from '../../src/shared/auth.js';
import { loadConfig } from '../../src/config.js';
import { buildApp } from '../../src/app.js';

const region = 'ap-southeast-1';
const pool = 'ap-southeast-1_TestPool';
const client = 'publicclient123';
const issuer = `https://cognito-idp.${region}.amazonaws.com/${pool}`;
let keys: Awaited<ReturnType<typeof generateKeyPair>>;
let verifier: CognitoJwksVerifier;
beforeAll(async () => {
  keys = await generateKeyPair('RS256');
  verifier = new CognitoJwksVerifier(region, pool, client, createLocalJWKSet({
    keys: [{ ...await exportJWK(keys.publicKey), kid: 'test-key', alg: 'RS256', use: 'sig' }],
  }));
});
async function token(overrides: Record<string, unknown> = {}, key = keys.privateKey) {
  return new SignJWT({ sub: 'user-sub', iss: issuer, client_id: client, token_use: 'access',
    exp: Math.floor(Date.now() / 1000) + 300, 'cognito:groups': ['admin'], ...overrides })
    .setProtectedHeader({ alg: 'RS256', kid: 'test-key' }).sign(key);
}
describe('Cognito access token verification', () => {
  it('accepts a signed access token and identity', async () => {
    await expect(verifier.verify(await token())).resolves.toMatchObject({ sub: 'user-sub', groups: ['admin'] });
  });
  it.each([
    ['issuer', { iss: 'https://wrong.example' }],
    ['client', { client_id: 'anotherclient' }],
    ['ID token', { token_use: 'id' }],
    ['missing subject', { sub: undefined }],
    ['empty subject', { sub: '' }],
    ['missing expiry', { exp: undefined }],
    ['invalid groups', { 'cognito:groups': 'admin' }],
  ])('rejects %s', async (_, claims) => {
    await expect(verifier.verify(await token(claims))).rejects.toMatchObject({ code: 'UNAUTHENTICATED' });
  });
  it('rejects expired tokens distinctly', async () => {
    await expect(verifier.verify(await token({ exp: 1 }))).rejects.toMatchObject({ code: 'TOKEN_EXPIRED' });
  });
  it('rejects a signature from another key', async () => {
    const other = await generateKeyPair('RS256');
    await expect(verifier.verify(await token({}, other.privateKey))).rejects.toMatchObject({ code: 'UNAUTHENTICATED' });
  });
  it('rejects HS256 even with access claims', async () => {
    const signed = await new SignJWT({ sub: 'user-sub', token_use: 'access' })
      .setProtectedHeader({ alg: 'HS256' }).sign(new TextEncoder().encode('test-key'));
    await expect(verifier.verify(signed)).rejects.toMatchObject({ code: 'UNAUTHENTICATED' });
  });
});
describe('authentication configuration', () => {
  afterEach(() => vi.unstubAllEnvs());
  it('defaults configured development to Cognito instead of dev tokens', () => {
    vi.stubEnv('DEV_AUTH', undefined);
    const cfg = loadConfig({ nodeEnv: 'development', cognitoRegion: region,
      cognitoPoolId: pool, cognitoClientId: client });
    expect(cfg.devAuth).toBe(false);
    expect(createTokenVerifier(cfg)).toBeInstanceOf(CognitoJwksVerifier);
  });
  it('fails closed with partial Cognito configuration in development', () => {
    vi.stubEnv('DEV_AUTH', undefined);
    const cfg = loadConfig({ nodeEnv: 'development', cognitoRegion: region,
      cognitoPoolId: '', cognitoClientId: '' });
    expect(cfg.devAuth).toBe(false);
    expect(() => createTokenVerifier(cfg)).toThrow('Cognito authentication configuration is required');
  });
  it('supports explicit local DEV_AUTH while production still rejects it', () => {
    vi.stubEnv('DEV_AUTH', '1');
    expect(createTokenVerifier(loadConfig({ nodeEnv: 'development' }))).toBeInstanceOf(Hs256Verifier);
    expect(() => createTokenVerifier(loadConfig({ nodeEnv: 'production' }))).toThrow('Development authentication is forbidden');
  });
  it('preserves explicit test dev auth', () => {
    expect(createTokenVerifier(loadConfig({ nodeEnv: 'test', devAuth: true }))).toBeInstanceOf(Hs256Verifier);
  });
  it('selects Cognito for production', () => {
    expect(createTokenVerifier(loadConfig({ nodeEnv: 'production', devAuth: false,
      cognitoRegion: region, cognitoPoolId: pool, cognitoClientId: client }))).toBeInstanceOf(CognitoJwksVerifier);
  });
  it('rejects production dev auth override before database access', async () => {
    await expect(buildApp({ cfg: loadConfig({ nodeEnv: 'production', devAuth: true }) }))
      .rejects.toThrow('Development authentication is forbidden');
  });
  it('rejects missing production Cognito configuration before database access', async () => {
    await expect(buildApp({ cfg: loadConfig({ nodeEnv: 'production', devAuth: false,
      cognitoRegion: undefined, cognitoPoolId: undefined, cognitoClientId: undefined }) }))
      .rejects.toThrow('Cognito authentication configuration is required');
  });
  it('rejects an injected dev verifier in production', async () => {
    await expect(buildApp({ cfg: loadConfig({ nodeEnv: 'production', devAuth: false }),
      verifier: new Hs256Verifier('test') })).rejects.toThrow('Development authentication is forbidden');
  });
});
