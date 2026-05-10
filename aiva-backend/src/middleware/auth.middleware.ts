import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import { env } from '../config/env';
import { query } from '../config/db';

export interface AdminRequest extends Request {
  admin?: { id: string; email: string; name: string };
}

export interface StudentRequest extends Request {
  student?: { id: string; phone: string; name: string | null };
}

export function adminAuth(req: AdminRequest, res: Response, next: NextFunction): void {
  const auth = req.headers.authorization;
  if (!auth?.startsWith('Bearer ')) {
    res.status(401).json({ success: false, error: 'Missing admin token' });
    return;
  }
  try {
    const payload = jwt.verify(auth.slice(7), env.ADMIN_JWT_SECRET) as {
      id: string; email: string; name: string;
    };
    req.admin = payload;
    next();
  } catch {
    res.status(401).json({ success: false, error: 'Invalid or expired admin token' });
  }
}

export function studentAuth(req: StudentRequest, res: Response, next: NextFunction): void {
  const auth = req.headers.authorization;
  if (!auth?.startsWith('Bearer ')) {
    res.status(401).json({ success: false, error: 'Missing student token' });
    return;
  }

  let payload: { id: string; phone: string; name: string | null };
  try {
    payload = jwt.verify(auth.slice(7), env.STUDENT_JWT_SECRET) as typeof payload;
  } catch {
    res.status(401).json({ success: false, error: 'Invalid or expired student token' });
    return;
  }

  // Verify the student still exists in the database.
  // If the DB was reset or the student was deleted the JWT is still
  // cryptographically valid but the row is gone — every FK-constrained
  // INSERT would fail. Catch it here with a clear "please log in again" error.
  query(`SELECT id FROM students WHERE id = $1 LIMIT 1`, [payload.id])
    .then((result) => {
      if (!result.rows[0]) {
        res.status(401).json({
          success: false,
          error: 'Session expired — please log in again',
          session_expired: true,
        });
        return;
      }
      req.student = payload;
      next();
    })
    .catch(() => {
      // DB error — still let the request through so the route handler can deal with it
      req.student = payload;
      next();
    });
}
