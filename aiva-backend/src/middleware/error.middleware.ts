import { Request, Response, NextFunction } from 'express';

export interface AppError extends Error {
  status?: number;
}

export function errorMiddleware(
  err: AppError,
  _req: Request,
  res: Response,
  _next: NextFunction
): void {
  const status = err.status || 500;
  const message = err.message || 'Internal server error';

  console.error(`[API] Error ${status}:`, message);

  res.status(status).json({
    success: false,
    error: message,
  });
}
