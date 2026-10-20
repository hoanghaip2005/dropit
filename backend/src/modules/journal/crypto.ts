// Mã hóa phong bì cho nhật ký (BR-100, NFR-P05). Mỗi mục: khóa dữ liệu (DEK) ngẫu nhiên 256 bit,
// AES-256-GCM. DEK được bọc bằng khóa chủ từ env (thay KMS GenerateDataKey ở bản AWS).
import { createCipheriv, createDecipheriv, createHash, randomBytes } from 'node:crypto';

export const LOCAL_KEY_ID = 'local-env:v1';

export function masterKey(secret: string): Buffer {
  const b = Buffer.from(secret, 'base64');
  return b.length === 32 && b.toString('base64') === secret ? b : createHash('sha256').update(secret, 'utf8').digest();
}

function seal(key: Buffer, plain: Buffer, aad: Buffer) {
  const iv = randomBytes(12);
  const c = createCipheriv('aes-256-gcm', key, iv);
  c.setAAD(aad);
  const ct = Buffer.concat([c.update(plain), c.final()]);
  return { iv, ct: Buffer.concat([ct, c.getAuthTag()]) };
}

function open(key: Buffer, iv: Buffer, ctTag: Buffer, aad: Buffer) {
  const d = createDecipheriv('aes-256-gcm', key, iv);
  d.setAAD(aad);
  d.setAuthTag(ctTag.subarray(ctTag.length - 16));
  return Buffer.concat([d.update(ctTag.subarray(0, ctTag.length - 16)), d.final()]);
}

/** AAD gắn bản mã với (user, ngày): chép ciphertext sang người/ngày khác sẽ không giải được. */
const aadOf = (userId: string, day: string) => Buffer.from(`journal|${userId}|${day}`);

export function encryptJournal(master: Buffer, userId: string, day: string, text: string) {
  const dek = randomBytes(32);
  const aad = aadOf(userId, day);
  const body = seal(dek, Buffer.from(text, 'utf8'), aad);
  const wrapped = seal(master, dek, aad);
  return { ciphertext: body.ct, nonce: body.iv, encrypted_dek: Buffer.concat([wrapped.iv, wrapped.ct]), kms_key_id: LOCAL_KEY_ID };
}

export function decryptJournal(master: Buffer, userId: string, day: string, row: { ciphertext: Buffer; nonce: Buffer; encrypted_dek: Buffer }) {
  const aad = aadOf(userId, day);
  const dek = open(master, row.encrypted_dek.subarray(0, 12), row.encrypted_dek.subarray(12), aad);
  return open(dek, row.nonce, row.ciphertext, aad).toString('utf8');
}
