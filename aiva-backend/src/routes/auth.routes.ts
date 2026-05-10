import { Router, Request, Response, NextFunction } from 'express';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { query } from '../config/db';
import { env } from '../config/env';
import { adminAuth, AdminRequest } from '../middleware/auth.middleware';

const router = Router();

// POST /api/admin/login
router.post('/admin/login', async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const { email, password } = req.body as { email?: string; password?: string };
    if (!email || !password) {
      res.status(400).json({ success: false, error: 'email and password required' });
      return;
    }

    const result = await query(`SELECT id, name, email, password_hash FROM admins WHERE email = $1`, [email]);
    const admin = result.rows[0];
    if (!admin) {
      res.status(401).json({ success: false, error: 'Invalid credentials' });
      return;
    }

    const valid = await bcrypt.compare(password, admin.password_hash);
    if (!valid) {
      res.status(401).json({ success: false, error: 'Invalid credentials' });
      return;
    }

    const token = jwt.sign(
      { id: admin.id, email: admin.email, name: admin.name },
      env.ADMIN_JWT_SECRET,
      { expiresIn: '7d' }
    );

    res.json({ success: true, token, admin: { id: admin.id, name: admin.name, email: admin.email } });
  } catch (err) {
    next(err);
  }
});

// POST /api/student/send-otp
router.post('/student/send-otp', async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const { phone } = req.body as { phone?: string };
    if (!phone) {
      res.status(400).json({ success: false, error: 'phone is required' });
      return;
    }

    // Find or create student by phone
    let result = await query(`SELECT id FROM students WHERE phone = $1`, [phone]);
    if (!result.rows[0]) {
      await query(`INSERT INTO students (phone) VALUES ($1)`, [phone]);
    }

    // Store mock OTP (always 123456) with 10-minute expiry
    const otp = '123456';
    const expiresAt = new Date(Date.now() + 10 * 60 * 1000);
    await query(
      `INSERT INTO otps (phone, otp, expires_at) VALUES ($1, $2, $3)`,
      [phone, otp, expiresAt]
    );

    res.json({ success: true, message: 'OTP sent' });
  } catch (err) {
    next(err);
  }
});

// POST /api/student/verify-otp
router.post('/student/verify-otp', async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const { phone, otp, device_id, name } = req.body as {
      phone?: string; otp?: string; device_id?: string; name?: string;
    };

    if (!phone || !otp) {
      res.status(400).json({ success: false, error: 'phone and otp are required' });
      return;
    }

    // Find latest unused, non-expired OTP for this phone
    const otpResult = await query(
      `SELECT id FROM otps
       WHERE phone = $1 AND otp = $2 AND used = false AND expires_at > NOW()
       ORDER BY created_at DESC LIMIT 1`,
      [phone, otp]
    );

    if (!otpResult.rows[0]) {
      res.status(401).json({ success: false, error: 'Invalid or expired OTP' });
      return;
    }

    // Mark OTP as used
    await query(`UPDATE otps SET used = true WHERE id = $1`, [otpResult.rows[0].id]);

    // Find or create student
    let studentResult = await query(
      `SELECT id, name, phone, credits_total FROM students WHERE phone = $1`,
      [phone]
    );
    let student = studentResult.rows[0];

    if (!student) {
      const insert = await query(
        `INSERT INTO students (phone, device_id) VALUES ($1, $2) RETURNING id, name, phone, credits_total`,
        [phone, device_id ?? null]
      );
      student = insert.rows[0];
    } else {
      if (device_id) {
        await query(`UPDATE students SET device_id = $1 WHERE id = $2`, [device_id, student.id]);
      }
      // Update name if provided and student has no name yet
      if (name && !student.name) {
        const updated = await query(
          `UPDATE students SET name = $1 WHERE id = $2 RETURNING id, name, phone, credits_total`,
          [name, student.id]
        );
        student = updated.rows[0];
      }
    }

    const token = jwt.sign(
      { id: student.id, phone: student.phone, name: student.name },
      env.STUDENT_JWT_SECRET,
      { expiresIn: '30d' }
    );

    res.json({
      success: true,
      token,
      student: { id: student.id, name: student.name, phone: student.phone, credits_total: student.credits_total },
    });
  } catch (err) {
    next(err);
  }
});

// GET /api/students — admin only, list all students
router.get('/students', adminAuth, async (req: AdminRequest, res: Response, next: NextFunction): Promise<void> => {
  try {
    const result = await query(
      `SELECT s.id, s.name, s.phone, s.credits_total, s.created_at,
              COUNT(DISTINCT e.id)::int AS enrolled_courses,
              COUNT(DISTINCT CASE WHEN wp.completed = true THEN wp.lecture_id END)::int AS completed_lectures
       FROM students s
       LEFT JOIN enrollments e ON e.student_id = s.id
       LEFT JOIN watch_progress wp ON wp.student_id = s.id
       GROUP BY s.id
       ORDER BY s.created_at DESC`
    );
    res.json({ success: true, students: result.rows, count: result.rows.length });
  } catch (err) {
    next(err);
  }
});

// GET /api/admin/stats — admin dashboard statistics
router.get('/admin/stats', adminAuth, async (req: AdminRequest, res: Response, next: NextFunction): Promise<void> => {
  try {
    const [
      studentsResult,
      coursesResult,
      lecturesResult,
      enrollmentsResult,
      completedResult,
      recentEnrollmentsResult,
    ] = await Promise.all([
      query(`SELECT COUNT(*)::int AS total FROM students`),
      query(`SELECT COUNT(*)::int AS total, COUNT(CASE WHEN is_published THEN 1 END)::int AS published FROM courses`),
      query(`SELECT COUNT(*)::int AS total, COUNT(CASE WHEN status = 'ready' THEN 1 END)::int AS ready FROM lectures`),
      query(`SELECT COUNT(*)::int AS total FROM enrollments`),
      query(`SELECT COUNT(*)::int AS total FROM watch_progress WHERE completed = true`),
      query(`
        SELECT e.enrolled_at, s.name AS student_name, s.phone, c.title AS course_title
        FROM enrollments e
        JOIN students s ON s.id = e.student_id
        JOIN courses c ON c.id = e.course_id
        ORDER BY e.enrolled_at DESC LIMIT 10
      `),
    ]);

    res.json({
      success: true,
      stats: {
        total_students: studentsResult.rows[0].total,
        total_courses: coursesResult.rows[0].total,
        published_courses: coursesResult.rows[0].published,
        total_lectures: lecturesResult.rows[0].total,
        ready_lectures: lecturesResult.rows[0].ready,
        total_enrollments: enrollmentsResult.rows[0].total,
        completed_lectures: completedResult.rows[0].total,
        recent_enrollments: recentEnrollmentsResult.rows,
      },
    });
  } catch (err) {
    next(err);
  }
});

// GET /api/admin/doubts-analytics — admin doubts analytics
router.get('/admin/doubts-analytics', adminAuth, async (req: AdminRequest, res: Response, next: NextFunction): Promise<void> => {
  try {
    const [totalResult, recentResult, topLecturesResult] = await Promise.all([
      query(`SELECT COUNT(*)::int AS total FROM chat_logs`),
      query(`
        SELECT cl.question, cl.language, cl.created_at, l.title AS lecture_title
        FROM chat_logs cl
        LEFT JOIN lectures l ON l.id = cl.lecture_id
        ORDER BY cl.created_at DESC LIMIT 20
      `),
      query(`
        SELECT l.title, COUNT(cl.id)::int AS doubts_count
        FROM chat_logs cl
        LEFT JOIN lectures l ON l.id = cl.lecture_id
        WHERE l.id IS NOT NULL
        GROUP BY l.id, l.title
        ORDER BY doubts_count DESC LIMIT 10
      `),
    ]);

    res.json({
      success: true,
      analytics: {
        total_doubts: totalResult.rows[0].total,
        recent_doubts: recentResult.rows,
        top_lectures_by_doubts: topLecturesResult.rows,
      },
    });
  } catch (err) {
    next(err);
  }
});

export default router;
