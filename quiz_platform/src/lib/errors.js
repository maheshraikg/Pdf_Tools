export class AppError extends Error {
  constructor(status, code, message, details) {
    super(message ?? code);
    this.status = status;
    this.code = code;
    this.details = details;
  }
}

export const badRequest = (code, message, details) => new AppError(400, code, message, details);
export const unauthorized = (code = 'unauthorized', message = 'Authentication required') => new AppError(401, code, message);
export const forbidden = (code = 'forbidden', message = 'Not allowed') => new AppError(403, code, message);
export const notFound = (code = 'not_found', message = 'Not found') => new AppError(404, code, message);
export const conflict = (code, message, details) => new AppError(409, code, message, details);
export const tooMany = (code = 'rate_limited', message = 'Too many requests', retryAfterMs) =>
  new AppError(429, code, message, retryAfterMs ? { retryAfterMs } : undefined);
