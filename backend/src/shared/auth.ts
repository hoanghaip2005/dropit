// Xác thực: interface TokenVerifier để thay HS256 dev bằng Cognito JWKS sau (P2, NFR-10).
import { SignJWT, jwtVerify, errors } from 'jose';
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

// Sau này: CognitoJwksVerifier implements TokenVerifier — jose.createRemoteJWKSet(
//   https://cognito-idp.<region>.amazonaws.com/<pool>/.well-known/jwks.json), kiểm iss, client_id, token_use.
