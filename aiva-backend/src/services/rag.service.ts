import { Response } from 'express';
import { transcriptionService } from './transcription.service';
import { chunkingService } from './chunking.service';
import { embeddingService } from './embedding.service';
import { pineconeService } from './pinecone.service';
import { claudeService } from './claude.service';
import { lectureModel } from '../models/lecture.model';
import { AskRequest, RAGContext } from '../types';

export class RAGService {
  async processVideo(
    lecture_id: string,
    videoPath: string,
    metadata: { title: string; instructor: string; course: string }
  ): Promise<void> {
    await this.processVideoWithSteps(lecture_id, videoPath, metadata, () => Promise.resolve());
  }

  async processVideoWithSteps(
    lecture_id: string,
    videoPath: string,
    _metadata: { title: string; instructor: string; course: string },
    onStep: (step: string) => Promise<void>
  ): Promise<void> {
    try {
      console.log('[RAG] Starting transcription...');
      await lectureModel.updateStatus(lecture_id, 'transcribing');
      await onStep('transcribing');
      const segments = await transcriptionService.transcribeVideo(videoPath);

      console.log('[RAG] Chunking transcript...');
      await lectureModel.updateStatus(lecture_id, 'processing');
      await onStep('chunking');
      const chunks = chunkingService.chunkTranscript(segments, lecture_id);

      for (const chunk of chunks) {
        chunk.topic = chunkingService.extractTopics(chunk);
      }

      console.log('[RAG] Generating embeddings...');
      await onStep('embedding');
      const embeddings = await embeddingService.embedBatch(chunks.map((c) => c.text));

      console.log('[RAG] Storing chunks in PostgreSQL...');
      await onStep('saving_chunks');
      await lectureModel.saveChunks(chunks);

      console.log('[RAG] Storing embeddings in Pinecone...');
      await onStep('indexing');
      await pineconeService.upsertChunks(lecture_id, chunks, embeddings);

      const duration = segments.length > 0 ? segments[segments.length - 1].end : 0;
      await lectureModel.updateStatus(lecture_id, 'ready', {
        chunks_count: chunks.length,
        duration,
      });

      console.log('[RAG] Pipeline complete!', {
        lecture_id,
        segments: segments.length,
        chunks: chunks.length,
        duration: `${Math.floor(duration / 60)}m ${Math.floor(duration % 60)}s`,
      });
    } catch (err) {
      const message = err instanceof Error ? err.message : String(err);
      console.error('[RAG] Pipeline failed:', message);
      await lectureModel.updateStatus(lecture_id, 'failed');
      throw err;
    }
  }

  async answerQuestion(request: AskRequest, res: Response): Promise<void> {
    console.log('[RAG] Received question:', request.question);

    const questionEmbedding = await embeddingService.embedQuestion(request.question);

    let ragContexts = await pineconeService.searchSimilar(
      request.lecture_id,
      questionEmbedding,
      4
    );

    // Feature 2: Inject pause-point context chunks before semantic results
    if (request.pause_context) {
      const { seconds, window_before = 120, window_after = 30 } = request.pause_context;
      const start = Math.max(0, seconds - window_before);
      const end = seconds + window_after;

      const pauseChunks = await lectureModel.getPauseContextChunks(
        request.lecture_id,
        start,
        end
      );

      const existingIds = new Set(ragContexts.map((c) => c.chunk.id));
      const pauseContexts: RAGContext[] = pauseChunks
        .filter((c) => !existingIds.has(c.id))
        .map((c, i) => ({
          chunk: c,
          similarity_score: 1.0,
          rank: i,
          is_pause_context: true,
        }));

      ragContexts = [...pauseContexts, ...ragContexts];
      console.log(`[RAG] Added ${pauseContexts.length} pause-context chunks at ${seconds}s`);
    }

    if (ragContexts.length === 0) {
      console.log('[RAG] No relevant chunks found, sending fallback response');
      res.setHeader('Content-Type', 'text/event-stream');
      res.setHeader('Cache-Control', 'no-cache');
      res.setHeader('Connection', 'keep-alive');
      res.flushHeaders();

      const fallback =
        request.language === 'hi'
          ? 'Is lecture mein aapke sawaal ka relevant content nahi mila. Please koi aur sawaal poochein.'
          : "I couldn't find relevant content in this lecture for your question. Please try rephrasing or ask about a different topic.";

      res.write(`data: ${JSON.stringify({ type: 'delta', text: fallback })}\n\n`);
      res.write(`data: ${JSON.stringify({ type: 'done', timestamps: [], source_chunks: [] })}\n\n`);
      res.end();
      return;
    }

    await claudeService.streamAnswer(
      ragContexts,
      request.question,
      request.chat_history,
      request.language,
      res,
      request.pause_context
    );
  }
}

export const ragService = new RAGService();
