import { Router, Request, Response, NextFunction } from 'express';
import fs from 'fs';
import { uploadMiddleware } from '../middleware/upload.middleware';
import { queueService } from '../services/queue.service';
import { lectureModel } from '../models/lecture.model';
import { pineconeService } from '../services/pinecone.service';

const router = Router();

router.post(
  '/upload',
  uploadMiddleware.single('video'),
  async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      if (!req.file) {
        res.status(400).json({ success: false, error: 'No video file provided' });
        return;
      }

      const { title, instructor, course } = req.body as {
        title?: string;
        instructor?: string;
        course?: string;
      };

      if (!title || !instructor || !course) {
        fs.unlinkSync(req.file.path);
        res.status(400).json({
          success: false,
          error: 'Missing required fields: title, instructor, course',
        });
        return;
      }

      const videoPath = req.file.path;
      const lecture = await lectureModel.create({ title, instructor, course, video_path: videoPath });

      console.log(`[API] Video uploaded for lecture ${lecture.id}: ${title}`);

      res.status(202).json({
        success: true,
        lecture_id: lecture.id,
        message: 'Video uploaded. Processing queued.',
        status: 'transcribing',
      });

      await queueService.addToQueue(lecture.id);
    } catch (err) {
      next(err);
    }
  }
);

router.get('/:lecture_id/stream', async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const { lecture_id } = req.params;
    const lecture = await lectureModel.findById(lecture_id);

    if (!lecture || !lecture.video_path) {
      res.status(404).json({ success: false, error: 'Video not found' });
      return;
    }

    if (!fs.existsSync(lecture.video_path)) {
      res.status(404).json({ success: false, error: 'Video file not found on server' });
      return;
    }

    const stat = fs.statSync(lecture.video_path);
    const fileSize = stat.size;
    const range = req.headers.range;

    if (range) {
      const parts = range.replace(/bytes=/, '').split('-');
      const start = parseInt(parts[0], 10);
      const end = parts[1] ? parseInt(parts[1], 10) : fileSize - 1;
      const chunkSize = end - start + 1;
      res.writeHead(206, {
        'Content-Range': `bytes ${start}-${end}/${fileSize}`,
        'Accept-Ranges': 'bytes',
        'Content-Length': chunkSize,
        'Content-Type': 'video/mp4',
      });
      fs.createReadStream(lecture.video_path, { start, end }).pipe(res);
    } else {
      res.writeHead(200, {
        'Content-Length': fileSize,
        'Accept-Ranges': 'bytes',
        'Content-Type': 'video/mp4',
      });
      fs.createReadStream(lecture.video_path).pipe(res);
    }
  } catch (err) {
    next(err);
  }
});

router.get('/:lecture_id/status', async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const { lecture_id } = req.params;
    const lecture = await lectureModel.findById(lecture_id);

    if (!lecture) {
      res.status(404).json({ success: false, error: 'Lecture not found' });
      return;
    }

    const queueJob = await queueService.getQueueStatus(lecture_id);

    res.json({
      lecture_id: lecture.id,
      status: lecture.status,
      title: lecture.title,
      chunks_count: lecture.chunks_count ?? 0,
      duration: lecture.duration,
      current_step: queueJob?.current_step ?? null,
      queue_status: queueJob?.status ?? null,
    });
  } catch (err) {
    next(err);
  }
});

router.post('/:lecture_id/retry', async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const { lecture_id } = req.params;
    const lecture = await lectureModel.findById(lecture_id);

    if (!lecture) {
      res.status(404).json({ success: false, error: 'Lecture not found' });
      return;
    }

    if (lecture.status === 'ready') {
      res.status(400).json({ success: false, error: 'Lecture is already ready' });
      return;
    }

    if (!lecture.video_path || !fs.existsSync(lecture.video_path)) {
      res.status(400).json({
        success: false,
        error: 'Original video file is no longer available. Please re-upload.',
      });
      return;
    }

    await lectureModel.deleteChunks(lecture_id);
    try { await pineconeService.deleteByLecture(lecture_id); } catch { /* nothing was stored */ }

    await lectureModel.updateStatus(lecture_id, 'transcribing', { chunks_count: 0, duration: 0 });

    console.log(`[API] Retrying processing for lecture ${lecture_id}: ${lecture.title}`);

    res.json({
      success: true,
      lecture_id,
      message: 'Reprocessing queued.',
      status: 'transcribing',
    });

    await queueService.addToQueue(lecture_id);
  } catch (err) {
    next(err);
  }
});

export default router;
