import { v4 as uuidv4 } from 'uuid';
import { env } from '../config/env';
import { TranscriptSegment, TranscriptChunk } from '../types';

const SENTENCE_ENDINGS = /[.?!]$/;

const TOPIC_KEYWORDS: Array<{ keywords: string[]; topic: string }> = [
  { keywords: ['async', 'await', 'promise', 'then', 'catch', 'resolve', 'reject'], topic: 'Async Programming' },
  { keywords: ['hook', 'useeffect', 'usestate', 'usecallback', 'usememo', 'useref'], topic: 'React Hooks' },
  { keywords: ['component', 'props', 'state', 'render', 'jsx', 'virtual dom'], topic: 'React Components' },
  { keywords: ['algorithm', 'complexity', 'big o', 'time complexity', 'space complexity'], topic: 'Algorithms' },
  { keywords: ['database', 'query', 'sql', 'nosql', 'mongodb', 'schema', 'table'], topic: 'Databases' },
  { keywords: ['function', 'class', 'method', 'constructor', 'prototype', 'closure'], topic: 'Functions' },
  { keywords: ['array', 'loop', 'iterate', 'forEach', 'map', 'filter', 'reduce'], topic: 'Arrays & Loops' },
];

export class ChunkingService {
  extractTopics(chunk: TranscriptChunk): string {
    const lower = chunk.text.toLowerCase();
    for (const { keywords, topic } of TOPIC_KEYWORDS) {
      if (keywords.some((kw) => lower.includes(kw))) {
        return topic;
      }
    }
    return 'General';
  }

  chunkTranscript(segments: TranscriptSegment[], lecture_id: string): TranscriptChunk[] {
    console.log(`[Chunking] Starting chunking for lecture ${lecture_id} with ${segments.length} segments`);

    const targetWordCount = env.CHUNK_SIZE;
    const overlapWordCount = env.CHUNK_OVERLAP;

    const chunks: TranscriptChunk[] = [];
    let chunkIndex = 0;
    let i = 0;
    let overlapText = '';

    while (i < segments.length) {
      const chunkSegments: TranscriptSegment[] = [];
      let wordCount = 0;
      const startTime = segments[i].start;

      // Seed with overlap from previous chunk
      let baseText = overlapText;
      const overlapWords = overlapText.trim() === '' ? 0 : overlapText.trim().split(/\s+/).length;
      wordCount = overlapWords;

      while (i < segments.length) {
        const seg = segments[i];
        const segWords = seg.text.trim().split(/\s+/).length;

        chunkSegments.push(seg);
        wordCount += segWords;
        i++;

        if (wordCount >= targetWordCount) {
          // Only split at sentence boundary
          if (SENTENCE_ENDINGS.test(seg.text.trim())) {
            break;
          }
          // Look ahead up to 3 more segments for a sentence boundary
          let lookahead = 0;
          while (i < segments.length && lookahead < 3) {
            const next = segments[i];
            const nextWords = next.text.trim().split(/\s+/).length;
            chunkSegments.push(next);
            wordCount += nextWords;
            i++;
            lookahead++;
            if (SENTENCE_ENDINGS.test(next.text.trim())) {
              break;
            }
          }
          break;
        }
      }

      if (chunkSegments.length === 0) break;

      const combinedText = (baseText + ' ' + chunkSegments.map((s) => s.text).join(' ')).trim();
      const endTime = chunkSegments[chunkSegments.length - 1].end;
      const totalWords = combinedText.split(/\s+/).length;

      const chunk: TranscriptChunk = {
        id: uuidv4(),
        lecture_id,
        text: combinedText,
        start_time: startTime,
        end_time: endTime,
        timestamp_label: this.formatTimestamp(startTime),
        chunk_index: chunkIndex,
        word_count: totalWords,
      };

      chunks.push(chunk);

      // Build overlap text from last N words of this chunk's segment texts (without overlap prefix)
      const segText = chunkSegments.map((s) => s.text).join(' ');
      const segWords = segText.trim().split(/\s+/);
      overlapText = segWords.slice(-overlapWordCount).join(' ');

      chunkIndex++;
    }

    console.log(`[Chunking] Created ${chunks.length} chunks`);
    return chunks;
  }

  private formatTimestamp(seconds: number): string {
    const minutes = Math.floor(seconds / 60);
    const secs = Math.floor(seconds % 60);
    return `${String(minutes).padStart(2, '0')}:${String(secs).padStart(2, '0')}`;
  }
}

export const chunkingService = new ChunkingService();
