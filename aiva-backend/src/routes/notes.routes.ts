import { Router, Response, NextFunction } from 'express';
import OpenAI from 'openai';
import { query } from '../config/db';
import { env } from '../config/env';
import { studentAuth, StudentRequest } from '../middleware/auth.middleware';
import { regenerateStudentNotes } from './chat-history.routes';

const router = Router();
const openai = new OpenAI({ apiKey: env.OPENAI_API_KEY });

// GET /api/notes/:lecture_id  (studentAuth)
router.get('/notes/:lecture_id', studentAuth, async (req: StudentRequest, res: Response, next: NextFunction): Promise<void> => {
  try {
    const { lecture_id } = req.params;

    // Return existing notes if already generated
    const existing = await query(`SELECT * FROM lecture_notes WHERE lecture_id = $1`, [lecture_id]);
    if (existing.rows[0]) {
      res.json({
        success: true,
        notes: {
          lecture_id,
          content: existing.rows[0].content,
          generated_at: existing.rows[0].generated_at,
        },
      });
      return;
    }

    // Get lecture info
    const lectureResult = await query(`SELECT title, instructor FROM lectures WHERE id = $1`, [lecture_id]);
    if (!lectureResult.rows[0]) {
      res.status(404).json({ success: false, error: 'Lecture not found' });
      return;
    }

    // Get all transcript chunks
    const chunksResult = await query(
      `SELECT text FROM transcript_chunks WHERE lecture_id = $1 ORDER BY chunk_index ASC`,
      [lecture_id]
    );

    if (chunksResult.rows.length === 0) {
      res.status(404).json({
        success: false,
        error: 'No transcript available for this lecture yet. Please wait for processing to complete.',
      });
      return;
    }

    const fullTranscript = chunksResult.rows
      .map((c: { text: string }) => c.text)
      .join(' ');

    const prompt = `Generate structured study notes from this lecture transcript.
Format as markdown with:
- ## Key Concepts (bullet points)
- ## Detailed Notes (organized by topic)
- ## Summary (2-3 sentences)
- ## Key Takeaways (bullet points)

Transcript: ${fullTranscript}`;

    const completion = await openai.chat.completions.create({
      model: 'gpt-4o-mini',
      max_tokens: 2000,
      messages: [{ role: 'user', content: prompt }],
    });

    const content = completion.choices[0].message.content?.trim() ?? '';

    // Save to lecture_notes table
    const saved = await query(
      `INSERT INTO lecture_notes (lecture_id, content)
       VALUES ($1, $2)
       ON CONFLICT (lecture_id) DO UPDATE SET content = $2, generated_at = NOW()
       RETURNING generated_at`,
      [lecture_id, content]
    );

    res.json({
      success: true,
      notes: {
        lecture_id,
        content,
        generated_at: saved.rows[0].generated_at,
      },
    });
  } catch (err) {
    next(err);
  }
});

// GET /api/student-notes/:lecture_id  —  per-student notes built from Q&A history
router.get('/student-notes/:lecture_id', studentAuth, async (req: StudentRequest, res: Response, next: NextFunction): Promise<void> => {
  try {
    const { lecture_id } = req.params;
    const studentId = req.student!.id;

    // Return cached notes if available
    const existing = await query(
      `SELECT content, updated_at FROM student_notes WHERE student_id = $1 AND lecture_id = $2`,
      [studentId, lecture_id]
    );
    if (existing.rows[0]) {
      res.json({ success: true, notes: existing.rows[0] });
      return;
    }

    // Try generating from Q&A history first
    const chatResult = await query(
      `SELECT question, answer FROM chat_logs
       WHERE student_id = $1 AND lecture_id = $2 AND answer IS NOT NULL
       ORDER BY created_at ASC`,
      [studentId, lecture_id]
    );

    if (chatResult.rows.length > 0) {
      // Generate from Q&A and return
      await regenerateStudentNotes(studentId, lecture_id);
      const fresh = await query(
        `SELECT content, updated_at FROM student_notes WHERE student_id = $1 AND lecture_id = $2`,
        [studentId, lecture_id]
      );
      if (fresh.rows[0]) {
        res.json({ success: true, notes: fresh.rows[0] });
        return;
      }
    }

    // Fallback: generate from transcript (same as lecture-wide notes but saved per student)
    const chunksResult = await query(
      `SELECT text FROM transcript_chunks WHERE lecture_id = $1 ORDER BY chunk_index ASC LIMIT 60`,
      [lecture_id]
    );
    if (chunksResult.rows.length === 0) {
      res.json({ success: false, error: 'No content available to generate notes yet. Start watching and asking questions!' });
      return;
    }

    const lectureResult = await query(`SELECT title FROM lectures WHERE id = $1`, [lecture_id]);
    const title = lectureResult.rows[0]?.title ?? 'this lecture';
    const transcript = chunksResult.rows.map((c: { text: string }) => c.text).join(' ').slice(0, 4000);

    const prompt = `Generate personalized study notes from this lecture transcript for a student.
Lecture: "${title}"
Format as markdown with: ## Key Concepts, ## Detailed Notes, ## Summary, ## Key Takeaways
Transcript: ${transcript}`;

    const completion = await openai.chat.completions.create({
      model: 'gpt-4o-mini',
      max_tokens: 1500,
      messages: [{ role: 'user', content: prompt }],
    });

    const content = completion.choices[0].message.content?.trim() ?? '';
    await query(
      `INSERT INTO student_notes (student_id, lecture_id, content)
       VALUES ($1, $2, $3)
       ON CONFLICT (student_id, lecture_id) DO UPDATE SET content = $3, updated_at = NOW()`,
      [studentId, lecture_id, content]
    );

    res.json({ success: true, notes: { content, updated_at: new Date() } });
  } catch (err) {
    next(err);
  }
});

export default router;
