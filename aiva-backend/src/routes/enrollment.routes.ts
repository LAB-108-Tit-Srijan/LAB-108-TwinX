import { Router, Request, Response, NextFunction } from 'express';
import OpenAI from 'openai';
import { query } from '../config/db';
import { env } from '../config/env';
import { studentAuth, StudentRequest } from '../middleware/auth.middleware';

const openai = new OpenAI({ apiKey: env.OPENAI_API_KEY });

const router = Router();

// POST /api/enroll
router.post('/enroll', studentAuth, async (req: StudentRequest, res: Response, next: NextFunction): Promise<void> => {
  try {
    const { course_id, target_weeks } = req.body as { course_id?: string; target_weeks?: number };
    const studentId = req.student!.id;

    if (!course_id) {
      res.status(400).json({ success: false, error: 'course_id is required' });
      return;
    }

    // Check course exists and is published
    const courseResult = await query(`SELECT * FROM courses WHERE id = $1 AND is_published = true`, [course_id]);
    if (!courseResult.rows[0]) {
      res.status(404).json({ success: false, error: 'Course not found or not published' });
      return;
    }
    const course = courseResult.rows[0];

    // Create enrollment (upsert — safe to call multiple times)
    const enrollment = await query(
      `INSERT INTO enrollments (student_id, course_id, target_weeks)
       VALUES ($1, $2, $3)
       ON CONFLICT (student_id, course_id) DO UPDATE SET target_weeks = EXCLUDED.target_weeks
       RETURNING id`,
      [studentId, course_id, target_weeks ?? 4]
    );
    const enrollmentId = enrollment.rows[0].id;

    // Respond immediately — don't make the student wait for AI roadmap generation
    res.json({
      success: true,
      enrollment_id: enrollmentId,
      message: 'Enrolled successfully',
    });

    // Generate roadmap in background (fire-and-forget, never blocks the response)
    generateRoadmapBackground(enrollmentId, studentId, course_id, course, target_weeks ?? 4)
      .catch((err: unknown) => console.error('[Enrollment] Background roadmap failed:', err));

  } catch (err) {
    next(err);
  }
});

async function generateRoadmapBackground(
  enrollmentId: string,
  studentId: string,
  courseId: string,
  course: { title: string; estimated_hours: number },
  targetWeeks: number
): Promise<void> {
  // Skip if roadmap already exists for this enrollment
  const existing = await query(
    `SELECT id FROM roadmaps WHERE enrollment_id = $1 LIMIT 1`,
    [enrollmentId]
  );
  if (existing.rows[0]) return;

  const lecturesResult = await query(
    `SELECT id, title, duration, order_index FROM lectures
     WHERE course_id = $1 AND status = 'ready' ORDER BY order_index ASC`,
    [courseId]
  );
  const lectures = lecturesResult.rows;
  if (lectures.length === 0) return;

  const targetDays = targetWeeks * 7;

  const prompt = `You are an AI learning coach.
A student enrolled in: ${course.title}
Available time: 1 hour/day. Target: complete in ${targetDays} days.
Total lectures: ${lectures.length} (${course.estimated_hours}h estimated)
Lectures:
${lectures.map((l: { title: string; duration: number; id: string }, i: number) =>
  `${i + 1}. ${l.title} (${Math.round(l.duration / 60)}min, id: ${l.id})`
).join('\n')}

Return ONLY a valid JSON object (no markdown, no explanation):
{"overview":"string","daily_goal_hours":1,"estimated_completion_days":${targetDays},"weekly_plan":[{"week":1,"focus":"string","lectures":[{"lecture_id":"string","title":"string","day":1,"estimated_minutes":30,"priority":"high"}]}],"today_lectures":["lecture_id"],"tips":["string"]}`;

  const completion = await openai.chat.completions.create({
    model: 'gpt-4o-mini',
    max_tokens: 2048,
    messages: [{ role: 'user', content: prompt }],
  });

  const raw = completion.choices[0].message.content?.trim() ?? '{}';
  // Robustly extract the JSON object regardless of surrounding text
  const objMatch = raw.match(/\{[\s\S]*\}/);
  if (!objMatch) {
    console.error('[Enrollment] Could not extract JSON from roadmap response:', raw.slice(0, 200));
    return;
  }
  const plan = JSON.parse(objMatch[0]);

  await query(
    `INSERT INTO roadmaps (enrollment_id, student_id, course_id, goal, daily_hours, target_days, plan)
     VALUES ($1,$2,$3,$4,$5,$6,$7)
     ON CONFLICT (enrollment_id) DO UPDATE SET plan = EXCLUDED.plan, target_days = EXCLUDED.target_days`,
    [enrollmentId, studentId, courseId, `Complete ${course.title}`, 1, targetDays, JSON.stringify(plan)]
  );
  console.log(`[Enrollment] Roadmap generated for enrollment ${enrollmentId}`);
}

// GET /api/my-courses
router.get('/my-courses', studentAuth, async (req: StudentRequest, res: Response, next: NextFunction): Promise<void> => {
  try {
    const studentId = req.student!.id;

    const result = await query(`
      SELECT
        e.id AS enrollment_id,
        e.enrolled_at,
        c.*,
        COALESCE(progress.completed_count, 0) AS completed_lectures,
        COALESCE(progress.completed_count, 0)::float / NULLIF(c.total_lectures, 0) * 100 AS progress_percent
      FROM enrollments e
      JOIN courses c ON c.id = e.course_id
      LEFT JOIN (
        SELECT wp.student_id, l.course_id, COUNT(*) AS completed_count
        FROM watch_progress wp
        JOIN lectures l ON l.id = wp.lecture_id
        WHERE wp.student_id = $1 AND wp.completed = true
        GROUP BY wp.student_id, l.course_id
      ) progress ON progress.student_id = $1 AND progress.course_id = c.id
      WHERE e.student_id = $1
      ORDER BY e.enrolled_at DESC
    `, [studentId]);

    res.json({ success: true, courses: result.rows });
  } catch (err) {
    next(err);
  }
});

export default router;
