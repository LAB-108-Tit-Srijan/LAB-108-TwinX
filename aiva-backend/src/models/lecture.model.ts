import { query } from '../config/db';
import { Lecture, TranscriptChunk, TopicSummary, Chapter } from '../types';

interface LectureRow {
  id: string;
  title: string;
  instructor: string;
  course: string;
  video_path: string;
  duration: number;
  status: string;
  chunks_count: number;
  summary_full: string | null;
  summary_topics: TopicSummary[] | null;
  chapters: Chapter[] | null;
  created_at: Date;
  updated_at: Date;
}

function rowToLecture(row: LectureRow): Lecture {
  return {
    id: row.id,
    title: row.title,
    instructor: row.instructor,
    course: row.course,
    video_path: row.video_path,
    duration: Number(row.duration),
    status: row.status as Lecture['status'],
    chunks_count: row.chunks_count,
    summary_full: row.summary_full ?? undefined,
    summary_topics: row.summary_topics ?? undefined,
    chapters: row.chapters ?? undefined,
    created_at: row.created_at,
    updated_at: row.updated_at,
  };
}

export class LectureModel {
  async findAll(): Promise<Lecture[]> {
    const result = await query(
      'SELECT * FROM lectures ORDER BY created_at DESC'
    );
    return (result.rows as LectureRow[]).map(rowToLecture);
  }

  async findById(id: string): Promise<Lecture | null> {
    const result = await query('SELECT * FROM lectures WHERE id = $1', [id]);
    if (result.rows.length === 0) return null;
    return rowToLecture(result.rows[0] as LectureRow);
  }

  async create(data: {
    title: string;
    instructor: string;
    course: string;
    video_path: string;
  }): Promise<Lecture> {
    const result = await query(
      `INSERT INTO lectures (title, instructor, course, video_path)
       VALUES ($1, $2, $3, $4)
       RETURNING *`,
      [data.title, data.instructor, data.course, data.video_path]
    );
    return rowToLecture(result.rows[0] as LectureRow);
  }

  async updateStatus(
    id: string,
    status: Lecture['status'],
    extra?: { chunks_count?: number; duration?: number }
  ): Promise<void> {
    await query(
      `UPDATE lectures
       SET status = $1,
           chunks_count = COALESCE($2, chunks_count),
           duration = COALESCE($3, duration),
           updated_at = NOW()
       WHERE id = $4`,
      [
        status,
        extra?.chunks_count ?? null,
        extra?.duration ?? null,
        id,
      ]
    );
  }

  async delete(id: string): Promise<void> {
    await query('DELETE FROM lectures WHERE id = $1', [id]);
  }

  async saveChunks(chunks: TranscriptChunk[]): Promise<void> {
    if (chunks.length === 0) return;

    const values: unknown[] = [];
    const placeholders = chunks.map((chunk, i) => {
      const base = i * 9;
      values.push(
        chunk.id,
        chunk.lecture_id,
        chunk.text,
        chunk.start_time,
        chunk.end_time,
        chunk.timestamp_label,
        chunk.topic ?? 'General',
        chunk.chunk_index,
        chunk.word_count
      );
      return `($${base + 1}, $${base + 2}, $${base + 3}, $${base + 4}, $${base + 5}, $${base + 6}, $${base + 7}, $${base + 8}, $${base + 9})`;
    });

    await query(
      `INSERT INTO transcript_chunks
         (id, lecture_id, text, start_time, end_time, timestamp_label, topic, chunk_index, word_count)
       VALUES ${placeholders.join(', ')}`,
      values
    );
  }

  async deleteChunks(lecture_id: string): Promise<void> {
    await query('DELETE FROM transcript_chunks WHERE lecture_id = $1', [lecture_id]);
  }

  async updateSummary(
    lecture_id: string,
    data: { summaryFull: string; summaryTopics: TopicSummary[]; chapters: Chapter[] }
  ): Promise<void> {
    await query(
      `UPDATE lectures
       SET summary_full = $1, summary_topics = $2, chapters = $3, updated_at = NOW()
       WHERE id = $4`,
      [data.summaryFull, JSON.stringify(data.summaryTopics), JSON.stringify(data.chapters), lecture_id]
    );
  }

  async getPauseContextChunks(
    lecture_id: string,
    start_seconds: number,
    end_seconds: number
  ): Promise<TranscriptChunk[]> {
    const result = await query(
      `SELECT * FROM transcript_chunks
       WHERE lecture_id = $1
         AND start_time >= $2
         AND end_time <= $3
       ORDER BY chunk_index ASC`,
      [lecture_id, start_seconds, end_seconds]
    );
    return result.rows.map((row) => ({
      id: row.id as string,
      lecture_id: row.lecture_id as string,
      text: row.text as string,
      start_time: Number(row.start_time),
      end_time: Number(row.end_time),
      timestamp_label: row.timestamp_label as string,
      topic: row.topic as string,
      chunk_index: Number(row.chunk_index),
      word_count: Number(row.word_count),
    }));
  }

  async getChunkAtTime(lecture_id: string, seconds: number): Promise<TranscriptChunk | null> {
    const result = await query(
      `SELECT * FROM transcript_chunks
       WHERE lecture_id = $1
         AND start_time <= $2
         AND end_time >= $2
       ORDER BY start_time ASC
       LIMIT 1`,
      [lecture_id, seconds]
    );
    if (result.rows.length === 0) {
      // Fallback: nearest chunk before the timestamp
      const fallback = await query(
        `SELECT * FROM transcript_chunks
         WHERE lecture_id = $1 AND start_time <= $2
         ORDER BY start_time DESC LIMIT 1`,
        [lecture_id, seconds]
      );
      if (fallback.rows.length === 0) return null;
      const row = fallback.rows[0];
      return {
        id: row.id as string,
        lecture_id: row.lecture_id as string,
        text: row.text as string,
        start_time: Number(row.start_time),
        end_time: Number(row.end_time),
        timestamp_label: row.timestamp_label as string,
        topic: row.topic as string,
        chunk_index: Number(row.chunk_index),
        word_count: Number(row.word_count),
      };
    }
    const row = result.rows[0];
    return {
      id: row.id as string,
      lecture_id: row.lecture_id as string,
      text: row.text as string,
      start_time: Number(row.start_time),
      end_time: Number(row.end_time),
      timestamp_label: row.timestamp_label as string,
      topic: row.topic as string,
      chunk_index: Number(row.chunk_index),
      word_count: Number(row.word_count),
    };
  }

  async getChunksByLecture(lecture_id: string): Promise<TranscriptChunk[]> {
    const result = await query(
      'SELECT * FROM transcript_chunks WHERE lecture_id = $1 ORDER BY chunk_index ASC',
      [lecture_id]
    );

    return result.rows.map((row) => ({
      id: row.id as string,
      lecture_id: row.lecture_id as string,
      text: row.text as string,
      start_time: Number(row.start_time),
      end_time: Number(row.end_time),
      timestamp_label: row.timestamp_label as string,
      topic: row.topic as string,
      chunk_index: Number(row.chunk_index),
      word_count: Number(row.word_count),
    }));
  }
}

export const lectureModel = new LectureModel();
