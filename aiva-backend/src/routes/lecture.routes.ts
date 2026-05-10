import { Router, Request, Response, NextFunction } from 'express';
import fs from 'fs';
import { lectureModel } from '../models/lecture.model';
import { pineconeService } from '../services/pinecone.service';
import { query } from '../config/db';

const router = Router();

router.get('/lectures', async (_req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const lectures = await lectureModel.findAll();
    res.json({
      success: true,
      count: lectures.length,
      lectures: lectures.map((l) => ({
        id: l.id,
        title: l.title,
        instructor: l.instructor,
        course: l.course,
        status: l.status,
        chunks_count: l.chunks_count ?? 0,
        duration: l.duration,
        created_at: l.created_at,
      })),
    });
  } catch (err) {
    next(err);
  }
});

// GET /api/lectures/published — public, all ready lectures from published courses
router.get('/lectures/published', async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const result = await query(`
      SELECT l.id, l.title, l.instructor, l.duration, l.status, l.course_id,
             l.order_index, l.chunks_count,
             c.title AS course_title, c.thumbnail_color, c.level, c.category
      FROM lectures l
      JOIN courses c ON c.id = l.course_id
      WHERE c.is_published = true AND l.status = 'ready'
      ORDER BY c.created_at DESC, l.order_index ASC
    `);
    res.json({ success: true, lectures: result.rows, count: result.rows.length });
  } catch (err) {
    next(err);
  }
});

router.get('/lectures/:id', async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const { id } = req.params;
    const lecture = await lectureModel.findById(id);

    if (!lecture) {
      res.status(404).json({ success: false, error: 'Lecture not found' });
      return;
    }

    res.json({
      success: true,
      lecture: {
        id: lecture.id,
        title: lecture.title,
        instructor: lecture.instructor,
        course: lecture.course,
        status: lecture.status,
        chunks_count: lecture.chunks_count ?? 0,
        duration: lecture.duration,
        created_at: lecture.created_at,
        updated_at: lecture.updated_at,
      },
    });
  } catch (err) {
    next(err);
  }
});

router.get('/lectures/:id/chunks', async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const { id } = req.params;
    const lecture = await lectureModel.findById(id);

    if (!lecture) {
      res.status(404).json({ success: false, error: 'Lecture not found' });
      return;
    }

    const chunks = await lectureModel.getChunksByLecture(id);
    res.json({ success: true, chunks });
  } catch (err) {
    next(err);
  }
});

// Feature 1: Summary endpoint
router.get('/lectures/:id/summary', async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const { id } = req.params;
    const lecture = await lectureModel.findById(id);

    if (!lecture) {
      res.status(404).json({ success: false, error: 'Lecture not found' });
      return;
    }

    if (lecture.status !== 'ready') {
      res.status(400).json({ success: false, error: `Lecture not ready. Status: ${lecture.status}` });
      return;
    }

    res.json({
      success: true,
      lecture_id: id,
      summary_full: lecture.summary_full ?? null,
      summary_topics: lecture.summary_topics ?? [],
      chapters: lecture.chapters ?? [],
    });
  } catch (err) {
    next(err);
  }
});

// Feature 3: Full transcript as ordered array
router.get('/lectures/:id/transcript', async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const { id } = req.params;
    const lecture = await lectureModel.findById(id);

    if (!lecture) {
      res.status(404).json({ success: false, error: 'Lecture not found' });
      return;
    }

    const chunks = await lectureModel.getChunksByLecture(id);
    res.json({
      success: true,
      lecture_id: id,
      total: chunks.length,
      transcript: chunks.map((c) => ({
        timestamp_label: c.timestamp_label,
        start_time: c.start_time,
        end_time: c.end_time,
        text: c.text,
        topic: c.topic,
      })),
    });
  } catch (err) {
    next(err);
  }
});

// Feature 3: Sync — find the chunk at a given timestamp (seconds)
router.get('/lectures/:id/transcript/sync', async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const { id } = req.params;
    const t = parseFloat(req.query['t'] as string);

    if (isNaN(t) || t < 0) {
      res.status(400).json({ success: false, error: 'Query param "t" must be a non-negative number (seconds)' });
      return;
    }

    const lecture = await lectureModel.findById(id);
    if (!lecture) {
      res.status(404).json({ success: false, error: 'Lecture not found' });
      return;
    }

    const chunk = await lectureModel.getChunkAtTime(id, t);
    if (!chunk) {
      res.json({ success: true, chunk: null });
      return;
    }

    res.json({
      success: true,
      seconds: t,
      chunk: {
        timestamp_label: chunk.timestamp_label,
        start_time: chunk.start_time,
        end_time: chunk.end_time,
        text: chunk.text,
        topic: chunk.topic,
        chunk_index: chunk.chunk_index,
      },
    });
  } catch (err) {
    next(err);
  }
});

// Feature 4: All chapters
router.get('/lectures/:id/chapters', async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const { id } = req.params;
    const lecture = await lectureModel.findById(id);

    if (!lecture) {
      res.status(404).json({ success: false, error: 'Lecture not found' });
      return;
    }

    res.json({
      success: true,
      lecture_id: id,
      chapters: lecture.chapters ?? [],
    });
  } catch (err) {
    next(err);
  }
});

// Feature 4: Current chapter at a given timestamp
router.get('/lectures/:id/chapters/current', async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const { id } = req.params;
    const t = parseFloat(req.query['t'] as string);

    if (isNaN(t) || t < 0) {
      res.status(400).json({ success: false, error: 'Query param "t" must be a non-negative number (seconds)' });
      return;
    }

    const lecture = await lectureModel.findById(id);
    if (!lecture) {
      res.status(404).json({ success: false, error: 'Lecture not found' });
      return;
    }

    const chapters = lecture.chapters ?? [];
    // Find the last chapter whose start is <= t
    let current = chapters[0] ?? null;
    for (const ch of chapters) {
      if (ch.seconds <= t) current = ch;
      else break;
    }

    res.json({
      success: true,
      seconds: t,
      chapter: current,
      chapter_index: current ? chapters.indexOf(current) : -1,
    });
  } catch (err) {
    next(err);
  }
});

router.delete('/lectures/:id', async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const { id } = req.params;
    const lecture = await lectureModel.findById(id);

    if (!lecture) {
      res.status(404).json({ success: false, error: 'Lecture not found' });
      return;
    }

    await pineconeService.deleteByLecture(id);

    if (lecture.video_path && fs.existsSync(lecture.video_path)) {
      fs.unlinkSync(lecture.video_path);
      console.log(`[API] Deleted video file: ${lecture.video_path}`);
    }

    await lectureModel.delete(id);

    console.log(`[API] Lecture ${id} deleted`);
    res.json({ success: true, message: `Lecture ${id} deleted successfully` });
  } catch (err) {
    next(err);
  }
});

export default router;
