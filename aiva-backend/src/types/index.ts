export interface TranscriptSegment {
  id: string;
  start: number;
  end: number;
  text: string;
  timestamp_label: string;
}

export interface TranscriptChunk {
  id: string;
  lecture_id: string;
  text: string;
  start_time: number;
  end_time: number;
  timestamp_label: string;
  topic?: string;
  chunk_index: number;
  word_count: number;
}

export interface Lecture {
  id: string;
  title: string;
  instructor: string;
  course: string;
  video_path: string;
  duration: number;
  status: 'uploading' | 'transcribing' | 'processing' | 'ready' | 'failed';
  transcript_raw?: string;
  chunks_count?: number;
  summary_full?: string;
  summary_topics?: TopicSummary[];
  chapters?: Chapter[];
  created_at: Date;
  updated_at: Date;
}

export interface PauseContext {
  seconds: number;
  timestamp_label: string;
  window_before: number;   // seconds before pause to include (default 120)
  window_after: number;    // seconds after pause to include (default 30)
}

export interface AskRequest {
  lecture_id: string;
  question: string;
  language: 'en' | 'hi';
  chat_history: ChatMessage[];
  current_timestamp?: number;
  pause_context?: PauseContext;
}

export interface ChatMessage {
  role: 'student' | 'aiva';
  content: string;
  timestamp?: string;
}

export interface RAGContext {
  chunk: TranscriptChunk;
  similarity_score: number;
  rank: number;
  is_pause_context?: boolean;
}

export interface AIVAResponse {
  answer: string;
  source_timestamps: TimestampReference[];
  related_moments: RelatedMoment[];
  language: string;
}

export interface TimestampReference {
  label: string;
  seconds: number;
  context: string;
}

export interface RelatedMoment {
  lecture_id: string;
  lecture_title: string;
  timestamp_label: string;
  seconds: number;
  relevance: string;
}

export interface TopicSummary {
  topic: string;
  summary: string;
  start_timestamp: string;
  start_seconds: number;
  chunk_count: number;
}

export interface Chapter {
  title: string;
  timestamp_label: string;
  seconds: number;
  description: string;
  thumbnail_color?: string;
}

export interface QueueJob {
  id: string;
  lecture_id: string;
  status: 'pending' | 'processing' | 'completed' | 'failed';
  current_step: string | null;
  error_message: string | null;
  started_at: Date | null;
  completed_at: Date | null;
  created_at: Date;
}
