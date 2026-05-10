import { Router, Request, Response, NextFunction } from 'express';
import OpenAI from 'openai';
import { query } from '../config/db';
import { env } from '../config/env';
import { studentAuth, StudentRequest } from '../middleware/auth.middleware';

const router = Router();
const openai = new OpenAI({ apiKey: env.OPENAI_API_KEY });

// POST /api/roadmap/generate
router.post('/roadmap/generate', studentAuth, async (req: StudentRequest, res: Response, next: NextFunction): Promise<void> => {
  try {
    const { enrollment_id, goal, daily_hours, target_days } = req.body as {
      enrollment_id?: string; goal?: string; daily_hours?: number; target_days?: number;
    };
    const studentId = req.student!.id;

    if (!enrollment_id || !goal) {
      res.status(400).json({ success: false, error: 'enrollment_id and goal are required' });
      return;
    }

    // Verify enrollment belongs to this student
    const enrollResult = await query(
      `SELECT e.*, c.title, c.estimated_hours, c.total_lectures
       FROM enrollments e JOIN courses c ON c.id = e.course_id
       WHERE e.id = $1 AND e.student_id = $2`,
      [enrollment_id, studentId]
    );
    if (!enrollResult.rows[0]) {
      res.status(404).json({ success: false, error: 'Enrollment not found' });
      return;
    }

    const enrollment = enrollResult.rows[0];
    const lecturesResult = await query(
      `SELECT id, title, duration, order_index FROM lectures
       WHERE course_id = $1 AND status = 'ready' ORDER BY order_index ASC`,
      [enrollment.course_id]
    );
    const lectures = lecturesResult.rows;

    const hoursPerDay = daily_hours ?? 1;
    const days = target_days ?? 30;

    const prompt = `You are an AI learning coach.
A student has enrolled in: ${enrollment.title}
Their goal: ${goal}
Available time: ${hoursPerDay} hours/day
Target: Complete in ${days} days
Total lectures: ${lectures.length}
Total estimated hours: ${enrollment.estimated_hours}h
Lectures: ${lectures.map((l, i) => `${i + 1}. ${l.title} (${Math.round(l.duration / 60)}min, id: ${l.id})`).join('\n')}

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
    // Strip possible markdown code fences
    const jsonText = raw.replace(/^```(?:json)?\n?/, '').replace(/\n?```$/, '');
    const plan = JSON.parse(jsonText);

    // Store roadmap
    const saved = await query(
      `INSERT INTO roadmaps (enrollment_id, student_id, course_id, goal, daily_hours, target_days, plan)
       VALUES ($1,$2,$3,$4,$5,$6,$7)
       ON CONFLICT DO NOTHING
       RETURNING id`,
      [enrollment_id, studentId, enrollment.course_id, goal, hoursPerDay, days, JSON.stringify(plan)]
    );

    // If conflict (already exists), update it
    let roadmapId = saved.rows[0]?.id;
    if (!roadmapId) {
      const updated = await query(
        `UPDATE roadmaps SET plan = $1, goal = $2, daily_hours = $3, target_days = $4
         WHERE enrollment_id = $5 RETURNING id`,
        [JSON.stringify(plan), goal, hoursPerDay, days, enrollment_id]
      );
      roadmapId = updated.rows[0]?.id;
    }

    res.json({ success: true, roadmap_id: roadmapId, plan });
  } catch (err) {
    next(err);
  }
});

// GET /api/roadmap/:enrollment_id
router.get('/roadmap/:enrollment_id', studentAuth, async (req: StudentRequest, res: Response, next: NextFunction): Promise<void> => {
  try {
    const { enrollment_id } = req.params;
    const studentId = req.student!.id;

    const result = await query(
      `SELECT r.*, c.title AS course_title FROM roadmaps r
       JOIN courses c ON c.id = r.course_id
       WHERE r.enrollment_id = $1 AND r.student_id = $2`,
      [enrollment_id, studentId]
    );

    if (!result.rows[0]) {
      res.status(404).json({ success: false, error: 'Roadmap not found' });
      return;
    }

    res.json({ success: true, roadmap: result.rows[0] });
  } catch (err) {
    next(err);
  }
});

// GET /api/roadmap/today — prioritized today's lectures across all enrollments
router.get('/roadmap/today', studentAuth, async (req: StudentRequest, res: Response, next: NextFunction): Promise<void> => {
  try {
    const studentId = req.student!.id;

    // Get all roadmaps for this student
    const roadmaps = await query(
      `SELECT r.plan, r.course_id, c.title AS course_title, c.thumbnail_color
       FROM roadmaps r JOIN courses c ON c.id = r.course_id
       WHERE r.student_id = $1`,
      [studentId]
    );

    const todayLectures: Array<{
      lecture_id: string; title: string; course_title: string;
      course_id: string; estimated_minutes: number; priority: string;
      is_completed: boolean; thumbnail_color: string;
    }> = [];

    for (const rm of roadmaps.rows) {
      const plan = rm.plan as {
        today_lectures?: string[];
        weekly_plan?: Array<{ lectures: Array<{ lecture_id: string; title: string; estimated_minutes: number; priority: string }> }>;
      };
      const todayIds: string[] = plan.today_lectures ?? [];

      if (todayIds.length === 0) continue;

      // Get lecture details + watch progress
      for (const lectureId of todayIds) {
        const lRes = await query(
          `SELECT l.id, l.title,
                  wp.completed
           FROM lectures l
           LEFT JOIN watch_progress wp ON wp.lecture_id = l.id AND wp.student_id = $1
           WHERE l.id = $2`,
          [studentId, lectureId]
        );
        if (!lRes.rows[0]) continue;

        // Find priority from plan
        let estimatedMins = 30;
        let priority = 'medium';
        for (const week of plan.weekly_plan ?? []) {
          const found = week.lectures.find((lc) => lc.lecture_id === lectureId);
          if (found) { estimatedMins = found.estimated_minutes; priority = found.priority; break; }
        }

        todayLectures.push({
          lecture_id: lRes.rows[0].id,
          title: lRes.rows[0].title,
          course_title: rm.course_title,
          course_id: rm.course_id,
          estimated_minutes: estimatedMins,
          priority,
          is_completed: lRes.rows[0].completed ?? false,
          thumbnail_color: rm.thumbnail_color ?? '#6C63FF',
        });
      }
    }

    // Sort: high first, then medium, then low
    const order: Record<string, number> = { high: 0, medium: 1, low: 2 };
    todayLectures.sort((a, b) => (order[a.priority] ?? 1) - (order[b.priority] ?? 1));

    res.json({ success: true, today_lectures: todayLectures });
  } catch (err) {
    next(err);
  }
});

export default router;
