import { Router, Response, NextFunction } from 'express';
import OpenAI from 'openai';
import { query } from '../config/db';
import { env } from '../config/env';
import { studentAuth, StudentRequest } from '../middleware/auth.middleware';

const router = Router();
const openai = new OpenAI({ apiKey: env.OPENAI_API_KEY });

// POST /api/chat-history  —  save a completed Q&A exchange
router.post('/chat-history', studentAuth, async (req: StudentRequest, res: Response, next: NextFunction): Promise<void> => {
  try {
    const { lecture_id, question, answer, language } = req.body as {
      lecture_id?: string;
      question?: string;
      answer?: string;
      language?: string;
    };
    const studentId = req.student!.id;

    if (!lecture_id || !question || !answer) {
      res.status(400).json({ success: false, error: 'lecture_id, question, and answer are required' });
      return;
    }

    const lang = language ?? (/[ऀ-ॿ]/.test(question) ? 'hi' : 'en');

    await query(
      `INSERT INTO chat_logs (lecture_id, student_id, question, answer, language)
       VALUES ($1, $2, $3, $4, $5)`,
      [lecture_id, studentId, question.trim(), answer.trim(), lang]
    );

    // Regenerate student notes in background (don't await)
    regenerateStudentNotes(studentId, lecture_id).catch((err) =>
      console.error('[Notes] Background regeneration failed:', err)
    );

    res.json({ success: true });
  } catch (err) {
    next(err);
  }
});

// GET /api/chat-history/:lecture_id  —  retrieve Q&A history for this student + lecture
router.get('/chat-history/:lecture_id', studentAuth, async (req: StudentRequest, res: Response, next: NextFunction): Promise<void> => {
  try {
    const { lecture_id } = req.params;
    const studentId = req.student!.id;

    const result = await query(
      `SELECT question, answer, created_at
       FROM chat_logs
       WHERE student_id = $1 AND lecture_id = $2 AND answer IS NOT NULL
       ORDER BY created_at ASC`,
      [studentId, lecture_id]
    );

    res.json({ success: true, history: result.rows });
  } catch (err) {
    next(err);
  }
});

// ── Internal helper: regenerate student notes from Q&A history ─────────────

async function regenerateStudentNotes(studentId: string, lectureId: string): Promise<void> {
  // Get all Q&A pairs for this student + lecture
  const chatResult = await query(
    `SELECT question, answer FROM chat_logs
     WHERE student_id = $1 AND lecture_id = $2 AND answer IS NOT NULL
     ORDER BY created_at ASC`,
    [studentId, lectureId]
  );

  if (chatResult.rows.length === 0) return;

  // Get lecture title for context
  const lectureResult = await query(`SELECT title FROM lectures WHERE id = $1`, [lectureId]);
  const lectureTitle = lectureResult.rows[0]?.title ?? 'this lecture';

  const qaText = chatResult.rows
    .map((row: { question: string; answer: string }, i: number) =>
      `Q${i + 1}: ${row.question}\nA${i + 1}: ${row.answer}`
    )
    .join('\n\n');

  const prompt = `You are generating personalized study notes for a student learning "${lectureTitle}".
The student asked these questions and got these answers during the lecture:

${qaText}

Based on these Q&A exchanges, generate concise, well-structured study notes in markdown.
Focus only on what the student actually asked about — these are their personalized notes.
Format as:
## My Notes — ${lectureTitle}
### Key Concepts I Asked About
(bullet points of main ideas from Q&A)
### Detailed Notes
(organized sections based on the topics the student explored)
### Quick Summary
(2-3 sentences capturing what the student focused on)`;

  const completion = await openai.chat.completions.create({
    model: 'gpt-4o-mini',
    max_tokens: 1500,
    messages: [{ role: 'user', content: prompt }],
  });

  const content = completion.choices[0].message.content?.trim() ?? '';
  if (!content) return;

  await query(
    `INSERT INTO student_notes (student_id, lecture_id, content)
     VALUES ($1, $2, $3)
     ON CONFLICT (student_id, lecture_id) DO UPDATE SET content = $3, updated_at = NOW()`,
    [studentId, lectureId, content]
  );
}

export { regenerateStudentNotes };
export default router;
