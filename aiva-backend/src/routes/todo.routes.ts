import { Router, Response, NextFunction } from 'express';
import { query } from '../config/db';
import { studentAuth, StudentRequest } from '../middleware/auth.middleware';

const router = Router();

// GET /api/todos  (studentAuth)
router.get('/todos', studentAuth, async (req: StudentRequest, res: Response, next: NextFunction): Promise<void> => {
  try {
    const studentId = req.student!.id;

    const result = await query(
      `SELECT id, title, completed, created_at FROM todos
       WHERE student_id = $1 ORDER BY created_at DESC`,
      [studentId]
    );

    res.json({ success: true, todos: result.rows });
  } catch (err) {
    next(err);
  }
});

// POST /api/todos  (studentAuth)
router.post('/todos', studentAuth, async (req: StudentRequest, res: Response, next: NextFunction): Promise<void> => {
  try {
    const studentId = req.student!.id;
    const { title } = req.body as { title?: string };

    if (!title) {
      res.status(400).json({ success: false, error: 'title is required' });
      return;
    }

    const result = await query(
      `INSERT INTO todos (student_id, title) VALUES ($1, $2)
       RETURNING id, title, completed, created_at`,
      [studentId, title]
    );

    res.status(201).json({ success: true, todo: result.rows[0] });
  } catch (err) {
    next(err);
  }
});

// PUT /api/todos/:id  (studentAuth)
router.put('/todos/:id', studentAuth, async (req: StudentRequest, res: Response, next: NextFunction): Promise<void> => {
  try {
    const studentId = req.student!.id;
    const { id } = req.params;
    const { completed, title } = req.body as { completed?: boolean; title?: string };

    const result = await query(
      `UPDATE todos
       SET
         completed = COALESCE($1, completed),
         title = COALESCE($2, title)
       WHERE id = $3 AND student_id = $4
       RETURNING id, title, completed, created_at`,
      [completed ?? null, title ?? null, id, studentId]
    );

    if (!result.rows[0]) {
      res.status(404).json({ success: false, error: 'Todo not found' });
      return;
    }

    res.json({ success: true, todo: result.rows[0] });
  } catch (err) {
    next(err);
  }
});

// DELETE /api/todos/:id  (studentAuth)
router.delete('/todos/:id', studentAuth, async (req: StudentRequest, res: Response, next: NextFunction): Promise<void> => {
  try {
    const studentId = req.student!.id;
    const { id } = req.params;

    const result = await query(
      `DELETE FROM todos WHERE id = $1 AND student_id = $2 RETURNING id`,
      [id, studentId]
    );

    if (!result.rows[0]) {
      res.status(404).json({ success: false, error: 'Todo not found or not owned by you' });
      return;
    }

    res.json({ success: true, message: 'Todo deleted' });
  } catch (err) {
    next(err);
  }
});

export default router;
