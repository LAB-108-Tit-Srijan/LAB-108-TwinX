import { Router, Request, Response, NextFunction } from 'express';
import OpenAI from 'openai';
import { query } from '../config/db';
import { env } from '../config/env';
import { studentAuth, StudentRequest } from '../middleware/auth.middleware';

const router = Router();
const openai = new OpenAI({ apiKey: env.OPENAI_API_KEY });

// GET /api/quiz/:lecture_id
router.get('/quiz/:lecture_id', async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const { lecture_id } = req.params;

    // Return existing quiz if already generated
    const existing = await query(`SELECT * FROM quizzes WHERE lecture_id = $1`, [lecture_id]);
    if (existing.rows[0]) {
      const raw = existing.rows[0].questions;
      const questions = typeof raw === 'string' ? JSON.parse(raw) : raw;
      res.json({ success: true, quiz: { lecture_id, questions } });
      return;
    }

    // Get transcript chunks for this lecture
    const chunksResult = await query(
      `SELECT text FROM transcript_chunks WHERE lecture_id = $1 ORDER BY chunk_index ASC`,
      [lecture_id]
    );

    if (chunksResult.rows.length === 0) {
      // Check if lecture exists at all
      const lectureCheck = await query(`SELECT status, title FROM lectures WHERE id = $1`, [lecture_id]);
      if (!lectureCheck.rows[0]) {
        res.status(404).json({ success: false, error: 'Lecture not found' });
        return;
      }
      if (lectureCheck.rows[0].status !== 'ready') {
        res.status(202).json({
          success: false,
          error: `Lecture is still being processed (status: ${lectureCheck.rows[0].status}). Quiz will be available once processing completes.`,
          status: lectureCheck.rows[0].status,
        });
        return;
      }
      // Lecture is ready but has no chunks - unusual state
      res.status(404).json({ success: false, error: 'No transcript available for quiz generation.' });
      return;
    }

    // Concatenate up to 4000 chars
    const transcript = chunksResult.rows
      .map((c: { text: string }) => c.text)
      .join(' ')
      .slice(0, 4000);

    const prompt = `Based on this lecture transcript, generate 5 multiple-choice quiz questions.
Return ONLY valid JSON array (no markdown):
[
  {
    "question": "string",
    "options": ["A", "B", "C", "D"],
    "correct_index": 0,
    "explanation": "string"
  }
]
Transcript: ${transcript}`;

    const completion = await openai.chat.completions.create({
      model: 'gpt-4o-mini',
      max_tokens: 1000,
      messages: [{ role: 'user', content: prompt }],
    });

    const raw = completion.choices[0].message.content?.trim() ?? '[]';
    const jsonText = raw.replace(/^```(?:json)?\n?/, '').replace(/\n?```$/, '');
    const questions = JSON.parse(jsonText);

    // Save to quizzes table
    await query(
      `INSERT INTO quizzes (lecture_id, questions) VALUES ($1, $2)
       ON CONFLICT (lecture_id) DO UPDATE SET questions = $2, generated_at = NOW()`,
      [lecture_id, JSON.stringify(questions)]
    );

    res.json({ success: true, quiz: { lecture_id, questions } });
  } catch (err) {
    next(err);
  }
});

// POST /api/quiz/:lecture_id/attempt  (studentAuth)
router.post('/quiz/:lecture_id/attempt', studentAuth, async (req: StudentRequest, res: Response, next: NextFunction): Promise<void> => {
  try {
    const { lecture_id } = req.params;
    const { answers } = req.body as { answers?: number[] };
    const studentId = req.student!.id;

    if (!answers || !Array.isArray(answers)) {
      res.status(400).json({ success: false, error: 'answers array is required' });
      return;
    }

    // Load quiz questions
    const quizResult = await query(`SELECT questions FROM quizzes WHERE lecture_id = $1`, [lecture_id]);
    if (!quizResult.rows[0]) {
      res.status(404).json({ success: false, error: 'Quiz not found for this lecture' });
      return;
    }

    const questionsRaw = quizResult.rows[0].questions;
    const questions = (typeof questionsRaw === 'string' ? JSON.parse(questionsRaw) : questionsRaw) as Array<{ correct_index: number }>;
    const total = questions.length;
    let score = 0;

    for (let i = 0; i < total; i++) {
      if (answers[i] === questions[i].correct_index) {
        score++;
      }
    }

    const percentage = total > 0 ? Math.round((score / total) * 100) : 0;
    const passed = percentage >= 60;

    // Upsert quiz attempt
    await query(
      `INSERT INTO quiz_attempts (student_id, lecture_id, answers, score, total)
       VALUES ($1, $2, $3, $4, $5)
       ON CONFLICT (student_id, lecture_id)
       DO UPDATE SET answers = $3, score = $4, total = $5, completed_at = NOW()`,
      [studentId, lecture_id, JSON.stringify(answers), score, total]
    );

    // Award 10 credits if passed
    if (passed) {
      await query(
        `INSERT INTO credits (student_id, amount, reason) VALUES ($1, $2, $3)`,
        [studentId, 10, `Passed quiz for lecture ${lecture_id}`]
      );
      await query(
        `UPDATE students SET credits_total = credits_total + 10 WHERE id = $1`,
        [studentId]
      );
    }

    res.json({ success: true, score, total, percentage, passed });
  } catch (err) {
    next(err);
  }
});

export default router;
