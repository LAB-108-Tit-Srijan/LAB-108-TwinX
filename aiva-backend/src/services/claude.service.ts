import Anthropic from '@anthropic-ai/sdk';
import { Response } from 'express';
import { env } from '../config/env';
import { RAGContext, ChatMessage, PauseContext } from '../types';

const CLAUDE_MODEL = 'claude-sonnet-4-20250514';
const MAX_TOKENS = 1024;
const MAX_HISTORY_MESSAGES = 6;

const TIMESTAMP_REGEX = /\[(\d{1,2}:\d{2})\]/g;

export class ClaudeService {
  private client: Anthropic;

  constructor() {
    this.client = new Anthropic({ apiKey: env.ANTHROPIC_API_KEY });
  }

  buildSystemPrompt(language: 'en' | 'hi'): string {
    if (language === 'hi') {
      return `Aap AIVA hain, ek expert AI doubt solver ek coding institute ke liye. Aap students ko unke lecture videos se coding concepts samajhne mein madad karte hain.

RULES:
1. Sirf provided lecture transcript context se answer den
2. Hamesha specific timestamps [MM:SS] format mein reference karein
3. Code concepts ke liye pehle simple analogies den
4. Answers simple aur clear rakhein — Hinglish mein
5. Hamesha end karein: 'Kya ab clear hua?'
6. Timestamps as [42:31] format mein rakhein`;
    }

    return `You are AIVA, an expert AI doubt solver for a coding institute. You help students understand coding concepts from their lecture videos.

RULES:
1. Answer ONLY from the provided lecture transcript context
2. Always reference specific timestamps using format [MM:SS]
3. If the answer is in the transcript, cite it precisely
4. If not in transcript, say 'This wasn't covered in this lecture, but I can explain generally'
5. For code concepts, give simple analogies first
6. Keep answers concise — 3-5 sentences for simple doubts, more for complex ones
7. Always end with: 'Does this clear your doubt?'
8. Format timestamps as clickable references: [42:31]`;
  }

  async streamAnswer(
    context: RAGContext[],
    question: string,
    chat_history: ChatMessage[],
    language: 'en' | 'hi',
    res: Response,
    pauseContext?: PauseContext
  ): Promise<void> {
    console.log('[Claude] Building context string from', context.length, 'chunks');

    const pauseChunks = context.filter((c) => c.is_pause_context);
    const semanticChunks = context.filter((c) => !c.is_pause_context);

    let contextString = '';
    if (pauseChunks.length > 0) {
      contextString += `STUDENT PAUSED AT ${pauseContext?.timestamp_label ?? ''}. Context from that moment:\n`;
      contextString += pauseChunks
        .map((ctx) => `[${ctx.chunk.timestamp_label}] ${ctx.chunk.text}`)
        .join('\n\n');
      contextString += '\n\nADDITIONAL RELEVANT SECTIONS:\n';
    }
    contextString += semanticChunks
      .map((ctx) => `[${ctx.chunk.timestamp_label}] ${ctx.chunk.text}`)
      .join('\n\n');

    const recentHistory = chat_history.slice(-MAX_HISTORY_MESSAGES);
    const messages: Anthropic.MessageParam[] = [
      ...recentHistory.map((msg): Anthropic.MessageParam => ({
        role: msg.role === 'student' ? 'user' : 'assistant',
        content: msg.content,
      })),
      {
        role: 'user',
        content: `Lecture Context:\n${contextString}\n\nStudent Question: ${question}`,
      },
    ];

    res.setHeader('Content-Type', 'text/event-stream');
    res.setHeader('Cache-Control', 'no-cache');
    res.setHeader('Connection', 'keep-alive');
    res.flushHeaders();

    console.log('[Claude] Starting streaming response...');

    let fullAnswer = '';

    try {
      const stream = this.client.messages.stream({
        model: CLAUDE_MODEL,
        max_tokens: MAX_TOKENS,
        system: this.buildSystemPrompt(language),
        messages,
      });

      for await (const event of stream) {
        if (
          event.type === 'content_block_delta' &&
          event.delta.type === 'text_delta'
        ) {
          const delta = event.delta.text;
          fullAnswer += delta;
          res.write(`data: ${JSON.stringify({ type: 'delta', text: delta })}\n\n`);
        }
      }

      // Extract timestamps mentioned in the response
      const timestampMatches: string[] = [];
      let match: RegExpExecArray | null;
      const regexCopy = new RegExp(TIMESTAMP_REGEX.source, TIMESTAMP_REGEX.flags);
      while ((match = regexCopy.exec(fullAnswer)) !== null) {
        if (!timestampMatches.includes(match[1])) {
          timestampMatches.push(match[1]);
        }
      }

      const sourceChunks = context.map((c) => ({
        timestamp: c.chunk.timestamp_label,
        seconds: c.chunk.start_time,
        score: c.similarity_score,
      }));

      res.write(
        `data: ${JSON.stringify({
          type: 'done',
          timestamps: timestampMatches,
          source_chunks: sourceChunks,
        })}\n\n`
      );

      console.log('[Claude] Stream complete. Timestamps found:', timestampMatches);
    } catch (err) {
      const message = err instanceof Error ? err.message : String(err);
      console.error('[Claude] Streaming error:', message);

      res.write(
        `data: ${JSON.stringify({ type: 'error', message: 'Failed to generate answer. Please try again.' })}\n\n`
      );
    } finally {
      res.end();
    }
  }
}

export const claudeService = new ClaudeService();
