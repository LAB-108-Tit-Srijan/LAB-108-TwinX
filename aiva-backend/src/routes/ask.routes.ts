import { Router, Request, Response, NextFunction } from 'express';
import { ragService } from '../services/rag.service';
import { lectureModel } from '../models/lecture.model';
import { query } from '../config/db';
import { AskRequest } from '../types';

const router = Router();

router.post('/ask', async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const body = req.body as Partial<AskRequest>;

    const { lecture_id, question, language, chat_history, current_timestamp, pause_context } = body;

    if (!lecture_id || !question) {
      res.status(400).json({
        success: false,
        error: 'Missing required fields: lecture_id, question',
      });
      return;
    }

    const detectedLang = /[ऀ-ॿ]/.test(question ?? '') ? 'hi' : 'en';
    const finalLanguage = (language === 'en' || language === 'hi') ? language : detectedLang;

    // Log the question (fire-and-forget, don't block the response)
    if (lecture_id && question) {
      query(`INSERT INTO chat_logs (lecture_id, question, language) VALUES ($1, $2, $3)`,
        [lecture_id, question, finalLanguage]
      ).catch(() => {}); // ignore errors
    }

    const lecture = await lectureModel.findById(lecture_id);

    if (!lecture) {
      res.status(404).json({ success: false, error: 'Lecture not found' });
      return;
    }

    if (lecture.status !== 'ready') {
      res.status(400).json({
        success: false,
        error: `Lecture is not ready yet. Current status: ${lecture.status}`,
      });
      return;
    }

    // Auto-build pause context from current_timestamp when not explicitly provided
    let finalPauseContext = pause_context;
    if (!finalPauseContext && current_timestamp !== undefined && current_timestamp > 0) {
      const minutes = Math.floor(current_timestamp / 60);
      const secs = Math.floor(current_timestamp % 60);
      finalPauseContext = {
        seconds: current_timestamp,
        timestamp_label: `${String(minutes).padStart(2, '0')}:${String(secs).padStart(2, '0')}`,
        window_before: 120,
        window_after: 30,
      };
    }

    const askRequest: AskRequest = {
      lecture_id,
      question: question.trim(),
      language: finalLanguage,
      chat_history: chat_history ?? [],
      current_timestamp,
      pause_context: finalPauseContext,
    };

    console.log(`[API] Ask request for lecture ${lecture_id}: "${question}"`);

    await ragService.answerQuestion(askRequest, res);
  } catch (err) {
    if (!res.headersSent) {
      next(err);
    } else {
      const message = err instanceof Error ? err.message : String(err);
      console.error('[API] Error after SSE headers sent:', message);
      res.write(`data: ${JSON.stringify({ type: 'error', message })}\n\n`);
      res.end();
    }
  }
});

export default router;
