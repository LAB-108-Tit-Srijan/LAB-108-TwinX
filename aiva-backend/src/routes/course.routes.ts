import { Router, Request, Response, NextFunction } from 'express';
import { query } from '../config/db';
import { adminAuth, AdminRequest } from '../middleware/auth.middleware';

const router = Router();

// GET /api/courses — public, only published
router.get('/courses', async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const { category, level } = req.query as { category?: string; level?: string };

    let sql = `
      SELECT c.*, COUNT(l.id)::int AS actual_lectures
      FROM courses c
      LEFT JOIN lectures l ON l.course_id = c.id
      WHERE c.is_published = true
    `;
    const params: unknown[] = [];

    if (category) {
      params.push(category);
      sql += ` AND c.category = $${params.length}`;
    }
    if (level) {
      params.push(level);
      sql += ` AND c.level = $${params.length}`;
    }
    sql += ` GROUP BY c.id ORDER BY c.created_at DESC`;

    const result = await query(sql, params);
    res.json({ success: true, courses: result.rows });
  } catch (err) {
    next(err);
  }
});

// GET /api/courses/all — admin, all courses including drafts
router.get('/courses/all', adminAuth, async (req: AdminRequest, res: Response, next: NextFunction): Promise<void> => {
  try {
    const result = await query(`
      SELECT c.*, COUNT(l.id)::int AS actual_lectures
      FROM courses c
      LEFT JOIN lectures l ON l.course_id = c.id
      GROUP BY c.id ORDER BY c.created_at DESC
    `);
    res.json({ success: true, courses: result.rows });
  } catch (err) {
    next(err);
  }
});

// POST /api/courses — admin only
router.post('/courses', adminAuth, async (req: AdminRequest, res: Response, next: NextFunction): Promise<void> => {
  try {
    const { title, description, instructor, category, level, estimated_hours, thumbnail_color, expected_videos } = req.body as {
      title?: string; description?: string; instructor?: string;
      category?: string; level?: string; estimated_hours?: number;
      thumbnail_color?: string; expected_videos?: number;
    };

    if (!title) {
      res.status(400).json({ success: false, error: 'title is required' });
      return;
    }

    const result = await query(
      `INSERT INTO courses (title, description, instructor, category, level, estimated_hours, thumbnail_color, expected_videos, created_by)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9) RETURNING *`,
      [title, description ?? null, instructor ?? null, category ?? null,
       level ?? 'Beginner', estimated_hours ?? 0, thumbnail_color ?? '#6C63FF',
       expected_videos ?? 0, req.admin!.id]
    );

    res.status(201).json({ success: true, course: result.rows[0] });
  } catch (err) {
    next(err);
  }
});

// GET /api/courses/:id — single course with lectures
router.get('/courses/:id', async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const { id } = req.params;
    const courseResult = await query(`SELECT * FROM courses WHERE id = $1`, [id]);
    if (!courseResult.rows[0]) {
      res.status(404).json({ success: false, error: 'Course not found' });
      return;
    }

    const lecturesResult = await query(
      `SELECT id, title, instructor, duration, status, chunks_count, order_index
       FROM lectures WHERE course_id = $1 ORDER BY order_index ASC`,
      [id]
    );

    res.json({ success: true, course: courseResult.rows[0], lectures: lecturesResult.rows });
  } catch (err) {
    next(err);
  }
});

// PUT /api/courses/:id — admin only
router.put('/courses/:id', adminAuth, async (req: AdminRequest, res: Response, next: NextFunction): Promise<void> => {
  try {
    const { id } = req.params;
    const { title, description, instructor, category, level, estimated_hours, thumbnail_color, expected_videos } = req.body as Record<string, unknown>;

    const result = await query(
      `UPDATE courses SET
        title = COALESCE($1, title),
        description = COALESCE($2, description),
        instructor = COALESCE($3, instructor),
        category = COALESCE($4, category),
        level = COALESCE($5, level),
        estimated_hours = COALESCE($6, estimated_hours),
        thumbnail_color = COALESCE($7, thumbnail_color),
        expected_videos = COALESCE($8, expected_videos)
       WHERE id = $9 RETURNING *`,
      [title, description, instructor, category, level, estimated_hours, thumbnail_color, expected_videos, id]
    );

    if (!result.rows[0]) {
      res.status(404).json({ success: false, error: 'Course not found' });
      return;
    }
    res.json({ success: true, course: result.rows[0] });
  } catch (err) {
    next(err);
  }
});

// POST /api/courses/:id/publish — admin only
router.post('/courses/:id/publish', adminAuth, async (req: AdminRequest, res: Response, next: NextFunction): Promise<void> => {
  try {
    const { id } = req.params;
    const result = await query(
      `UPDATE courses SET is_published = true WHERE id = $1 RETURNING *`,
      [id]
    );
    if (!result.rows[0]) {
      res.status(404).json({ success: false, error: 'Course not found' });
      return;
    }
    res.json({ success: true, course: result.rows[0], message: 'Course published successfully' });
  } catch (err) {
    next(err);
  }
});

// POST /api/courses/:id/lectures — add a lecture to a course (admin only)
router.post('/courses/:id/lectures', adminAuth, async (req: AdminRequest, res: Response, next: NextFunction): Promise<void> => {
  try {
    const { id } = req.params;
    const { lecture_id, order_index } = req.body as { lecture_id?: string; order_index?: number };

    if (!lecture_id) {
      res.status(400).json({ success: false, error: 'lecture_id is required' });
      return;
    }

    await query(
      `UPDATE lectures SET course_id = $1, order_index = $2 WHERE id = $3`,
      [id, order_index ?? 0, lecture_id]
    );

    // Update total_lectures count on course
    await query(
      `UPDATE courses SET total_lectures = (SELECT COUNT(*) FROM lectures WHERE course_id = $1) WHERE id = $1`,
      [id]
    );

    res.json({ success: true, message: 'Lecture added to course' });
  } catch (err) {
    next(err);
  }
});

// DELETE /api/courses/:id/lectures/:lectureId — remove lecture from course (admin only)
router.delete('/courses/:id/lectures/:lectureId', adminAuth, async (req: AdminRequest, res: Response, next: NextFunction): Promise<void> => {
  try {
    const { id, lectureId } = req.params;
    await query(`UPDATE lectures SET course_id = NULL, order_index = 0 WHERE id = $1 AND course_id = $2`, [lectureId, id]);
    await query(
      `UPDATE courses SET total_lectures = (SELECT COUNT(*) FROM lectures WHERE course_id = $1) WHERE id = $1`,
      [id]
    );
    res.json({ success: true, message: 'Lecture removed from course' });
  } catch (err) {
    next(err);
  }
});

export default router;
