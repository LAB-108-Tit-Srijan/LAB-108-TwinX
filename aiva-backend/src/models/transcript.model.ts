import { TranscriptSegment } from '../types';

// Transcript segments are ephemeral — stored only during processing.
// They are not persisted to disk; chunks are stored in ChromaDB.
export interface TranscriptRecord {
  lecture_id: string;
  segments: TranscriptSegment[];
  raw_text: string;
  created_at: Date;
}

export function buildRawText(segments: TranscriptSegment[]): string {
  return segments.map((s) => s.text).join(' ');
}
