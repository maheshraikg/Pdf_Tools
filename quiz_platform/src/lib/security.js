import crypto from 'node:crypto';
import { promisify } from 'node:util';

const scrypt = promisify(crypto.scrypt);

export const hmac = (key, value) => crypto.createHmac('sha256', key).update(String(value)).digest();
export const sha256 = (value) => crypto.createHash('sha256').update(value).digest();
export const randomToken = (bytes = 32) => crypto.randomBytes(bytes).toString('base64url');

/** Uniform random numeric code using rejection-free crypto.randomInt. */
export function randomDigits(length) {
  let out = '';
  for (let i = 0; i < length; i++) out += crypto.randomInt(0, 10);
  return out;
}

export function timingSafeEqualBuf(a, b) {
  if (!Buffer.isBuffer(a) || !Buffer.isBuffer(b) || a.length !== b.length) return false;
  return crypto.timingSafeEqual(a, b);
}

/** AES-256-GCM. Output layout: 12-byte IV | 16-byte tag | ciphertext. */
export function encrypt(key, plaintext) {
  const iv = crypto.randomBytes(12);
  const cipher = crypto.createCipheriv('aes-256-gcm', key, iv);
  const ct = Buffer.concat([cipher.update(String(plaintext), 'utf8'), cipher.final()]);
  return Buffer.concat([iv, cipher.getAuthTag(), ct]);
}

export function decrypt(key, blob) {
  const iv = blob.subarray(0, 12);
  const tag = blob.subarray(12, 28);
  const decipher = crypto.createDecipheriv('aes-256-gcm', key, iv);
  decipher.setAuthTag(tag);
  return Buffer.concat([decipher.update(blob.subarray(28)), decipher.final()]).toString('utf8');
}

const SCRYPT = { N: 16384, r: 8, p: 1, keylen: 64 };

export async function hashPassword(password) {
  const salt = crypto.randomBytes(16);
  const dk = await scrypt(password, salt, SCRYPT.keylen, { N: SCRYPT.N, r: SCRYPT.r, p: SCRYPT.p });
  return `scrypt$${SCRYPT.N}$${SCRYPT.r}$${SCRYPT.p}$${salt.toString('base64')}$${dk.toString('base64')}`;
}

export async function verifyPassword(password, stored) {
  const parts = String(stored).split('$');
  if (parts.length !== 6 || parts[0] !== 'scrypt') return false;
  const [, N, r, p, saltB64, dkB64] = parts;
  const expected = Buffer.from(dkB64, 'base64');
  const dk = await scrypt(password, Buffer.from(saltB64, 'base64'), expected.length, {
    N: Number(N), r: Number(r), p: Number(p),
  });
  return timingSafeEqualBuf(dk, expected);
}

/** Human-friendly ID without ambiguous characters (0/O, 1/I/L). */
export function friendlyId(prefix, length = 7) {
  const alphabet = '23456789ABCDEFGHJKMNPQRSTUVWXYZ';
  let s = '';
  for (let i = 0; i < length; i++) s += alphabet[crypto.randomInt(0, alphabet.length)];
  return `${prefix}-${s}`;
}
