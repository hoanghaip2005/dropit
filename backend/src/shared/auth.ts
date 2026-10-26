// Xác thực: interface TokenVerifier để thay HS256 dev bằng Cognito JWKS sau (P2, NFR-10).
import { SignJWT, jwtVerify, errors, createRemoteJWKSet, type JWTVerifyGetKey } from 'jose';
import type { AppConfig } from '../config.js';
import { AppError, E } from './errors.js';

export type Identity = { sub: string; email?: string; name?: string; groups: string[] };

export interface TokenVerifier {
  verify(token: string): Promise<Identity>;
}

/** Bản dev/test: JWT HS256 ký bằng JWT_SECRET. */
export class Hs256Verifier implements TokenVerifier {
  private key: Uint8Array;
  constructor(secret: string) {
    this.key = new TextEncoder().encode(secret);
  }
  async verify(token: string): Promise<Identity> {
    try {
      const { payload } = await jwtVerify(token, this.key, { algorithms: ['HS256'] });
      if (payload.token_use !== 'access') throw E.unauth('Sai loại token');
      return {
        sub: String(payload.sub),
        email: payload.email as string | undefined,
        name: payload.name as string | undefined,
        groups: (payload['cognito:groups'] as string[]) ?? [],
      };
    } catch (e) {
      if (e instanceof AppError) throw e;
      if (e instanceof errors.JWTExpired) throw E.expired();
      throw E.unauth();
    }
  }
  async sign(claims: { sub: string; email?: string; name?: string }, ttlSec = 3600): Promise<string> {
    return new SignJWT({ ...claims, token_use: 'access' })
      .setProtectedHeader({ alg: 'HS256' })
      .setIssuedAt()
      .setExpirationTime(Math.floor(Date.now() / 1000) + ttlSec)
      .sign(this.key);
  }
}

/** Cognito access tokens only. Resolver injection supports isolated signed-JWKS tests. */
export class CognitoJwksVerifier implements TokenVerifier {
  private readonly issuer: string;
  private readonly resolveKey: JWTVerifyGetKey;
  constructor(region: string, poolId: string, private readonly clientId: string, resolveKey?: JWTVerifyGetKey) {
    if (!/^[a-z]{2}(?:-[a-z]+)+-\d$/.test(region) ||
        !new RegExp(`^${region}_[A-Za-z0-9]+$`).test(poolId) || !/^[A-Za-z0-9]+$/.test(clientId)) {
      throw new Error('Invalid Cognito public configuration');
    }
    this.issuer = `https://cognito-idp.${region}.amazonaws.com/${poolId}`;
    this.resolveKey = resolveKey ?? createRemoteJWKSet(new URL(`${this.issuer}/.well-known/jwks.json`));
  }
  async verify(token: string): Promise<Identity> {
    try {
      const { payload } = await jwtVerify(token, this.resolveKey, {
        algorithms: ['RS256'], issuer: this.issuer, requiredClaims: ['sub', 'exp', 'client_id', 'token_use'],
      });
      if (payload.token_use !== 'access' || payload.client_id !== this.clientId ||
          typeof payload.sub !== 'string' || !payload.sub.trim()) throw E.unauth();
      const groups = payload['cognito:groups'];
      if (groups !== undefined && (!Array.isArray(groups) || !groups.every(g => typeof g === 'string'))) throw E.unauth();
      return {
        sub: payload.sub,
        email: typeof payload.email === 'string' ? payload.email : undefined,
        name: typeof payload.name === 'string' ? payload.name : undefined,
        groups: groups as string[] | undefined ?? [],
      };
    } catch (e) {
      if (e instanceof AppError) throw e;
      if (e instanceof errors.JWTExpired) throw E.expired();
      throw E.unauth();
    }
  }
}

export function createTokenVerifier(cfg: AppConfig): TokenVerifier {
  const local = cfg.nodeEnv === 'development' || cfg.nodeEnv === 'test';
  if (cfg.devAuth) {
    if (!local) throw new Error('Development authentication is forbidden outside development/test');
    return new Hs256Verifier(cfg.jwtSecret);
  }
  if (!cfg.cognitoRegion || !cfg.cognitoPoolId || !cfg.cognitoClientId) {
    throw new Error('Cognito authentication configuration is required');
  }
  return new CognitoJwksVerifier(cfg.cognitoRegion, cfg.cognitoPoolId, cfg.cognitoClientId);
}
