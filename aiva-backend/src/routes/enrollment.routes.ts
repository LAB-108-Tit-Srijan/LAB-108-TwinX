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

    // Create enrollment with target_weeks (ignore duplicate)
    const enrollment = await query(
      `INSERT INTO enrollments (student_id, course_id, target_weeks)
       VALUES ($1, $2, $3)
       ON CONFLICT (student_id, course_id) DO UPDATE SET enrolled_at = enrollments.enrolled_at
       RETURNING id`,
      [studentId, course_id, target_weeks ?? 4]
    );
    const enrollmentId = enrollment.rows[0].id;

    // Auto-generate roadmap using OpenAI
    let roadmapId: string | null = null;
    try {
      const lecturesResult = await query(
        `SELECT id, title, duration, order_index FROM lectures
         WHERE course_id = $1 AND status = 'ready' ORDER BY order_index ASC`,
        [course_id]
      );
      const lectures = lecturesResult.rows;
      const weeks = target_weeks ?? 4;
      const targetDays = weeks * 7;

      if (lectures.length > 0) {
        const prompt = `You are an AI learning coach.
A student has enrolled in: ${course.title}
Available time: 1 hour/day
Target: Complete in ${targetDays} days
Total lectures: ${lectures.length}
Total estimated hours: ${course.estimated_hours}h
Lectures: ${lectures.map((l: { title: string; duration: number; id: string }, i: number) => `${i + 1}. ${l.title} (${Math.round(l.duration / 60)}min, id: ${l.id})`).join('\n')}

Create a day-by-day study plan.
Return ONLY valid JSON (no markdown, no explanation):
{
  "overview": "string (2 sentences)",
  "daily_goal_hours": number,
  "estimated_completion_days": number,
  "weekly_plan": [
    {
      "week": number,
      "focus": "string",
      "lectures": [
        {
          "lecture_id": "string",
          "title": "string",
          "day": number,
          "estimated_minutes": number,
          "priority": "high" | "medium" | "low"
        }
      ]
    }
  ],
  "today_lectures": ["lecture_id"],
  "tips": ["string"]
}`;

        const completion = await openai.chat.completions.create({
          model: 'gpt-4o-mini',
          max_tokens: 2048,
          messages: [{ role: 'user', content: prompt }],
        });

        const raw = completion.choices[0].message.content?.trim() ?? '{}';
        const jsonText = raw.replace(/^```(?:json)?\n?/, '').replace(/\n?```$/, '');
        const plan = JSON.parse(jsonText);

        const saved = await query(
          `INSERT INTO roadmaps (enrollment_id, student_id, course_id, goal, daily_hours, target_days, plan)
           VALUES ($1,$2,$3,$4,$5,$6,$7)
           ON CONFLICT DO NOTHING
           RETURNING id`,
          [enrollmentId, studentId, course_id, `Complete ${course.title}`, 1, targetDays, JSON.stringify(plan)]
        );
        roadmapId = saved.rows[0]?.id ?? null;
      }
    } catch (roadmapErr) {
      // Roadmap generation failure should not block enrollment
      console.error('[Enrollment] Roadmap auto-generation failed:', roadmapErr);
    }

    res.json({
      success: true,
      enrollment_id: enrollmentId,
      course,
      roadmap_id: roadmapId,
      message: 'Enrolled successfully',
    });
  } catch (err) {
    next(err);
  }
});

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
