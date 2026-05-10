import Anthropic from '@anthropic-ai/sdk';
import { env } from '../config/env';
import { TranscriptChunk, TopicSummary, Chapter } from '../types';
import { lectureModel } from '../models/lecture.model';

const CLAUDE_MODEL = 'claude-sonnet-4-20250514';

const THUMBNAIL_COLORS = [
  '#6C63FF', '#8B5CF6', '#EC4899', '#F59E0B', '#10B981',
  '#3B82F6', '#EF4444', '#14B8A6', '#F97316', '#A855F7',
];

export class SummaryService {
  private client: Anthropic;

  constructor() {
    this.client = new Anthropic({ apiKey: env.ANTHROPIC_API_KEY });
  }

  async generateFullSummary(chunks: TranscriptChunk[]): Promise<string> {
    const transcript = chunks
      .map((c) => `[${c.timestamp_label}] ${c.text}`)
      .join('\n\n');

    const response = await this.client.messages.create({
      model: CLAUDE_MODEL,
      max_tokens: 1024,
      messages: [
        {
          role: 'user',
          content: `Write a comprehensive 3-5 paragraph summary of this lecture for students. Focus on key concepts, sequence of topics, and practical takeaways. Do not mention timestamps.\n\nTranscript:\n${transcript}`,
        },
      ],
    });

    const block = response.content[0];
    return block.type === 'text' ? block.text : '';
  }

  async generateTopicSummaries(chunks: TranscriptChunk[]): Promise<TopicSummary[]> {
    const topicMap = new Map<string, TranscriptChunk[]>();
    for (const chunk of chunks) {
      const topic = chunk.topic ?? 'General';
      if (!topicMap.has(topic)) topicMap.set(topic, []);
      topicMap.get(topic)!.push(chunk);
    }

    const summaries: TopicSummary[] = [];

    for (const [topic, topicChunks] of topicMap) {
      const topicText = topicChunks.map((c) => c.text).join('\n');
      const firstChunk = topicChunks[0];

      const response = await this.client.messages.create({
        model: CLAUDE_MODEL,
        max_tokens: 200,
        messages: [
          {
            role: 'user',
            content: `Write a 2-3 sentence summary of this lecture section about "${topic}":\n\n${topicText}`,
          },
        ],
      });

      const block = response.content[0];
      summaries.push({
        topic,
        summary: block.type === 'text' ? block.text : '',
        start_timestamp: firstChunk.timestamp_label,
        start_seconds: firstChunk.start_time,
        chunk_count: topicChunks.length,
      });
    }

    return summaries;
  }

  async generateChapters(chunks: TranscriptChunk[]): Promise<Chapter[]> {
    const transcript = chunks
      .map((c) => `[${c.timestamp_label}] [${Math.floor(c.start_time)}s] ${c.text.substring(0, 120)}`)
      .join('\n');

    const response = await this.client.messages.create({
      model: CLAUDE_MODEL,
      max_tokens: 1024,
      messages: [
        {
          role: 'user',
          content: `Analyze this lecture transcript and identify 4-8 key chapters. Return ONLY a valid JSON array with no markdown or extra text:\n[\n  { "title": "Short Chapter Title", "timestamp_label": "MM:SS", "seconds": 42, "description": "One sentence." }\n]\n\nTranscript:\n${transcript}`,
        },
      ],
    });

    const block = response.content[0];
    if (block.type !== 'text') return [];

    try {
      const jsonMatch = block.text.match(/\[[\s\S]*\]/);
      if (!jsonMatch) return [];

      const parsed = JSON.parse(jsonMatch[0]) as Array<{
        title: string;
        timestamp_label: string;
        seconds: number;
        description: string;
      }>;

      return parsed.map((ch, i) => ({
        title: ch.title,
        timestamp_label: ch.timestamp_label,
        seconds: Number(ch.seconds),
        description: ch.description,
        thumbnail_color: THUMBNAIL_COLORS[i % THUMBNAIL_COLORS.length],
      }));
    } catch {
      console.error('[Summary] Failed to parse chapters JSON from Claude response');
      return [];
    }
  }

  async generateAll(lecture_id: string, chunks: TranscriptChunk[]): Promise<void> {
    console.log('[Summary] Generating full summary...');
    const summaryFull = await this.generateFullSummary(chunks);

    console.log('[Summary] Generating topic summaries...');
    const summaryTopics = await this.generateTopicSummaries(chunks);

    console.log('[Summary] Generating chapters...');
    const chapters = await this.generateChapters(chunks);

    await lectureModel.updateSummary(lecture_id, { summaryFull, summaryTopics, chapters });
    console.log('[Summary] Done:', {
      fullLength: summaryFull.length,
      topicsCount: summaryTopics.length,
      chaptersCount: chapters.length,
    });
  }
}

export const summaryService = new SummaryService();
