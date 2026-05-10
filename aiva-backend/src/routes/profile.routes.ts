import { Router, Response, NextFunction } from 'express';
import { query } from '../config/db';
import { studentAuth, StudentRequest } from '../middleware/auth.middleware';

const router = Router();

// GET /api/profile  (studentAuth)
router.get('/profile', studentAuth, async (req: StudentRequest, res: Response, next: NextFunction): Promise<void> => {
  try {
    const studentId = req.student!.id;

    // Get student base info
    const studentResult = await query(
      `SELECT id, name, phone, credits_total FROM students WHERE id = $1`,
      [studentId]
    );
    if (!studentResult.rows[0]) {
      res.status(404).json({ success: false, error: 'Student not found' });
      return;
    }
    const student = studentResult.rows[0];

    // Total enrolled courses
    const enrolledResult = await query(
      `SELECT COUNT(*)::int AS total FROM enrollments WHERE student_id = $1`,
      [studentId]
    );

    // Completed courses: all lectures of the course are completed
    const completedCoursesResult = await query(
      `SELECT COUNT(*)::int AS total
       FROM enrollments e
       JOIN courses c ON c.id = e.course_id
       WHERE e.student_id = $1
         AND c.total_lectures > 0
         AND c.total_lectures = (
           SELECT COUNT(*)
           FROM watch_progress wp
           JOIN lectures l ON l.id = wp.lecture_id
           WHERE wp.student_id = $1 AND l.course_id = e.course_id AND wp.completed = true
         )`,
      [studentId]
    );

    // Total watch hours
    const watchHoursResult = await query(
      `SELECT COALESCE(SUM(watched_seconds), 0)::float / 3600 AS total_hours
       FROM watch_progress WHERE student_id = $1`,
      [studentId]
    );

    // Completed lectures count
    const completedLecturesResult = await query(
      `SELECT COUNT(*)::int AS total FROM watch_progress WHERE student_id = $1 AND completed = true`,
      [studentId]
    );

    // Quiz attempts count and avg score
    const quizStatsResult = await query(
      `SELECT
         COUNT(*)::int AS attempts,
         COALESCE(AVG(CASE WHEN total > 0 THEN score::float / total * 100 ELSE 0 END), 0)::float AS avg_score
       FROM quiz_attempts WHERE student_id = $1`,
      [studentId]
    );

    res.json({
      success: true,
      profile: {
        ...student,
        stats: {
          enrolled_courses: enrolledResult.rows[0].total,
          completed_courses: completedCoursesResult.rows[0].total,
          total_watch_hours: Math.round(watchHoursResult.rows[0].total_hours * 100) / 100,
          completed_lectures: completedLecturesResult.rows[0].total,
          quiz_attempts: quizStatsResult.rows[0].attempts,
          quiz_avg_score: Math.round(quizStatsResult.rows[0].avg_score * 10) / 10,
        },
      },
    });
  } catch (err) {
    next(err);
  }
});

// GET /api/credits  (studentAuth)
router.get('/credits', studentAuth, async (req: StudentRequest, res: Response, next: NextFunction): Promise<void> => {
  try {
    const studentId = req.student!.id;

    const creditsResult = await query(
      `SELECT id, amount, reason, created_at FROM credits
       WHERE student_id = $1 ORDER BY created_at DESC`,
      [studentId]
    );

    const studentResult = await query(
      `SELECT credits_total FROM students WHERE id = $1`,
      [studentId]
    );

    res.json({
      success: true,
      credits: creditsResult.rows,
      total: studentResult.rows[0]?.credits_total ?? 0,
    });
  } catch (err) {
    next(err);
  }
});

// PATCH /api/profile  (studentAuth)
router.patch('/profile', studentAuth, async (req: StudentRequest, res: Response, next: NextFunction): Promise<void> => {
  try {
    const studentId = req.student!.id;
    const { name } = req.body as { name?: string };

    if (!name) {
      res.status(400).json({ success: false, error: 'name is required' });
      return;
    }

    const result = await query(
      `UPDATE students SET name = $1 WHERE id = $2
       RETURNING id, name, phone, credits_total`,
      [name, studentId]
    );

    if (!result.rows[0]) {
      res.status(404).json({ success: false, error: 'Student not found' });
      return;
    }

    res.json({ success: true, student: result.rows[0] });
  } catch (err) {
    next(err);
  }
});

export default router;
