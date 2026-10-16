import { badRequest } from './errors.js';

/**
 * Normalises a mobile number to E.164 (digits only, with country code, no '+').
 * Accepts "+91 98765 43210", "09876543210", "9876543210" (default country code).
 */
export function normalizePhone(input, defaultCountryCode = '91') {
  if (typeof input !== 'string') throw badRequest('invalid_phone', 'Enter a valid mobile number');
  const trimmed = input.trim();
  let digits = trimmed.replace(/[\s\-().]/g, '');
  if (!/^\+?\d+$/.test(digits)) throw badRequest('invalid_phone', 'Enter a valid mobile number');
  if (digits.startsWith('+')) digits = digits.slice(1);
  else if (digits.startsWith('00')) digits = digits.slice(2);
  else {
    digits = digits.replace(/^0+/, '');
    if (defaultCountryCode === '91' && digits.length === 10) digits = `91${digits}`;
    else if (digits.length <= 10) digits = `${defaultCountryCode}${digits}`;
  }
  if (digits.length < 8 || digits.length > 15) throw badRequest('invalid_phone', 'Enter a valid mobile number');
  // Indian mobile numbers: 10 digits starting 6-9.
  if (digits.startsWith('91') && !/^91[6-9]\d{9}$/.test(digits)) {
    throw badRequest('invalid_phone', 'Enter a valid 10-digit Indian mobile number');
  }
  return digits;
}

export const maskPhone = (last4) => `••••••${last4}`;
