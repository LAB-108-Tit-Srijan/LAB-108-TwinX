import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import { env } from '../config/env';

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
  try {
    const payload = jwt.verify(auth.slice(7), env.STUDENT_JWT_SECRET) as {
      id: string; phone: string; name: string | null;
    };
    req.student = payload;
    next();
  } catch {
    res.status(401).json({ success: false, error: 'Invalid or expired student token' });
  }
}
