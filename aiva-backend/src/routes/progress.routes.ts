import { Router, Request, Response, NextFunction } from 'express';
import { query } from '../config/db';
import { studentAuth, StudentRequest } from '../middleware/auth.middleware';

const router = Router();

// POST /api/progress/update
router.post('/progress/update', studentAuth, async (req: StudentRequest, res: Response, next: NextFunction): Promise<void> => {
  try {
    const { lecture_id, watched_seconds, total_seconds } = req.body as {
      lecture_id?: string; watched_seconds?: number; total_seconds?: number;
    };
    const studentId = req.student!.id;

    if (!lecture_id) {
      res.status(400).json({ success: false, error: 'lecture_id is required' });
      return;
    }

    const ws = watched_seconds ?? 0;
    const ts = total_seconds ?? 0;
    const completed = ts > 0 && ws >= ts * 0.9;

    const result = await query(
      `INSERT INTO watch_progress (student_id, lecture_id, watched_seconds, total_seconds, completed, last_watched)
       VALUES ($1, $2, $3, $4, $5, NOW())
       ON CONFLICT (student_id, lecture_id) DO UPDATE SET
         watched_seconds = GREATEST(watch_progress.watched_seconds, $3),
         total_seconds = $4,
         completed = CASE WHEN $5 THEN true ELSE watch_progress.completed END,
         last_watched = NOW()
       RETURNING *`,
      [studentId, lecture_id, ws, ts, completed]
    );

    res.json({ success: true, progress: result.rows[0] });
  } catch (err) {
    next(err);
  }
});

// GET /api/progress/course/:course_id
router.get('/progress/course/:course_id', studentAuth, async (req: StudentRequest, res: Response, next: NextFunction): Promise<void> => {
  try {
    const { course_id } = req.params;
    const studentId = req.student!.id;

    const lectures = await query(
      `SELECT l.id AS lecture_id,
              COALESCE(wp.completed, false) AS completed,
              CASE WHEN COALESCE(wp.total_seconds, 0) > 0
                THEN ROUND(wp.watched_seconds::numeric / wp.total_seconds * 100)
                ELSE 0 END AS progress_percent
       FROM lectures l
       LEFT JOIN watch_progress wp ON wp.lecture_id = l.id AND wp.student_id = $1
       WHERE l.course_id = $2 ORDER BY l.order_index`,
      [studentId, course_id]
    );

    const total = lectures.rows.length;
    const completed = lectures.rows.filter((r) => r.completed).length;
    const percentage = total > 0 ? Math.round((completed / total) * 100) : 0;

    res.json({
      success: true,
      course_id,
      total_lectures: total,
      completed_lectures: completed,
      percentage,
      lectures: lectures.rows,
    });
  } catch (err) {
    next(err);
  }
});

export default router;
