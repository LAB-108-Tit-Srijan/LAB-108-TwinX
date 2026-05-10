import { query } from '../config/db';
import { QueueJob } from '../types';
import { ragService } from './rag.service';
import { lectureModel } from '../models/lecture.model';
import { summaryService } from './summary.service';

interface QueueRow {
  id: string;
  lecture_id: string;
  status: string;
  current_step: string | null;
  error_message: string | null;
  started_at: Date | null;
  completed_at: Date | null;
  created_at: Date;
}

function rowToJob(row: QueueRow): QueueJob {
  return {
    id: row.id,
    lecture_id: row.lecture_id,
    status: row.status as QueueJob['status'],
    current_step: row.current_step,
    error_message: row.error_message,
    started_at: row.started_at,
    completed_at: row.completed_at,
    created_at: row.created_at,
  };
}

export class QueueService {
  private isProcessing = false;

  async addToQueue(lecture_id: string): Promise<QueueJob> {
    const result = await query(
      `INSERT INTO processing_queue (lecture_id, status)
       VALUES ($1, 'pending')
       RETURNING *`,
      [lecture_id]
    );
    const job = rowToJob(result.rows[0] as QueueRow);
    console.log(`[Queue] Job ${job.id} queued for lecture ${lecture_id}`);
    this.processNext().catch((err: unknown) => {
      console.error('[Queue] processNext error:', err instanceof Error ? err.message : String(err));
    });
    return job;
  }

  async getQueueStatus(lecture_id: string): Promise<QueueJob | null> {
    const result = await query(
      `SELECT * FROM processing_queue
       WHERE lecture_id = $1
       ORDER BY created_at DESC
       LIMIT 1`,
      [lecture_id]
    );
    if (result.rows.length === 0) return null;
    return rowToJob(result.rows[0] as QueueRow);
  }

  async resumePendingJobs(): Promise<void> {
    const result = await query(
      `SELECT COUNT(*) FROM processing_queue WHERE status IN ('pending', 'processing')`
    );
    const count = Number(result.rows[0].count);

    if (count === 0) {
      console.log('[Queue] No pending jobs to resume');
      return;
    }

    console.log(`[Queue] Resuming ${count} interrupted job(s)`);

    // Any job stuck in 'processing' state crashed mid-run — reset to pending
    await query(
      `UPDATE processing_queue
       SET status = 'pending', current_step = NULL
       WHERE status = 'processing'`
    );

    this.processNext().catch((err: unknown) => {
      console.error('[Queue] Resume error:', err instanceof Error ? err.message : String(err));
    });
  }

  private async processNext(): Promise<void> {
    if (this.isProcessing) return;
    this.isProcessing = true;

    try {
      const result = await query(
        `SELECT * FROM processing_queue
         WHERE status = 'pending'
         ORDER BY created_at ASC
         LIMIT 1`
      );

      if (result.rows.length === 0) return;

      await this.processJob(rowToJob(result.rows[0] as QueueRow));
    } finally {
      this.isProcessing = false;
      const remaining = await query(
        `SELECT COUNT(*) FROM processing_queue WHERE status = 'pending'`
      );
      if (Number(remaining.rows[0].count) > 0) {
        this.processNext().catch(() => { /* intentional: loop continues */ });
      }
    }
  }

  private async processJob(job: QueueJob): Promise<void> {
    console.log(`[Queue] Starting job ${job.id} for lecture ${job.lecture_id}`);

    await query(
      `UPDATE processing_queue
       SET status = 'processing', started_at = NOW(), current_step = 'starting'
       WHERE id = $1`,
      [job.id]
    );

    const lecture = await lectureModel.findById(job.lecture_id);
    if (!lecture) {
      await this.markFailed(job.id, 'Lecture record not found in database');
      return;
    }

    try {
      await ragService.processVideoWithSteps(
        job.lecture_id,
        lecture.video_path,
        { title: lecture.title, instructor: lecture.instructor, course: lecture.course },
        (step) => this.updateStep(job.id, step)
      );

      // Feature 1: generate summaries now that chunks exist
      await this.updateStep(job.id, 'generating_summary');
      const chunks = await lectureModel.getChunksByLecture(job.lecture_id);
      if (chunks.length > 0) {
        await summaryService.generateAll(job.lecture_id, chunks);
      }

      await this.markComplete(job.id);
    } catch (err) {
      const message = err instanceof Error ? err.message : String(err);
      await this.markFailed(job.id, message);
    }
  }

  private async updateStep(job_id: string, step: string): Promise<void> {
    await query(
      `UPDATE processing_queue SET current_step = $1 WHERE id = $2`,
      [step, job_id]
    );
  }

  private async markComplete(job_id: string): Promise<void> {
    await query(
      `UPDATE processing_queue
       SET status = 'completed', completed_at = NOW(), current_step = NULL
       WHERE id = $1`,
      [job_id]
    );
    console.log(`[Queue] Job ${job_id} completed`);
  }

  private async markFailed(job_id: string, error: string): Promise<void> {
    await query(
      `UPDATE processing_queue
       SET status = 'failed', error_message = $1, completed_at = NOW()
       WHERE id = $2`,
      [error, job_id]
    );
    console.error(`[Queue] Job ${job_id} failed:`, error);
  }
}

export const queueService = new QueueService();
