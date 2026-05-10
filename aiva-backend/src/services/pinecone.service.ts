import { RecordMetadata } from '@pinecone-database/pinecone';
import { getIndex } from '../config/pinecone';
import { TranscriptChunk, RAGContext } from '../types';

interface ChunkMetadata extends RecordMetadata {
  lecture_id: string;
  text: string;
  start_time: number;
  end_time: number;
  timestamp_label: string;
  topic: string;
  chunk_index: number;
}

const UPSERT_BATCH_SIZE = 100;

export class PineconeService {
  async upsertChunks(
    lecture_id: string,
    chunks: TranscriptChunk[],
    embeddings: number[][]
  ): Promise<void> {
    console.log(`[Pinecone] Upserting ${chunks.length} chunks for lecture ${lecture_id}`);

    const records = chunks.map((chunk, i) => ({
      id: chunk.id,
      values: embeddings[i],
      metadata: {
        lecture_id: chunk.lecture_id,
        text: chunk.text,
        start_time: chunk.start_time,
        end_time: chunk.end_time,
        timestamp_label: chunk.timestamp_label,
        topic: chunk.topic ?? 'General',
        chunk_index: chunk.chunk_index,
      } satisfies ChunkMetadata,
    }));

    const index = getIndex();
    for (let i = 0; i < records.length; i += UPSERT_BATCH_SIZE) {
      const batch = records.slice(i, i + UPSERT_BATCH_SIZE);
      // SDK v7: upsert takes { records: [...] }
      await index.upsert({ records: batch });
      console.log(`[Pinecone] Upserted batch ${Math.floor(i / UPSERT_BATCH_SIZE) + 1} (${batch.length} vectors)`);
    }

    console.log(`[Pinecone] Done upserting for lecture ${lecture_id}`);
  }

  async searchSimilar(
    lecture_id: string,
    question_embedding: number[],
    top_k: number = 4
  ): Promise<RAGContext[]> {
    console.log(`[Pinecone] Searching top ${top_k} similar chunks for lecture ${lecture_id}`);

    const results = await getIndex().query({
      vector: question_embedding,
      topK: top_k,
      filter: { lecture_id: { $eq: lecture_id } },
      includeMetadata: true,
    });

    const ragContexts: RAGContext[] = (results.matches ?? []).map((match, i) => {
      const meta = (match.metadata ?? {}) as ChunkMetadata;

      const chunk: TranscriptChunk = {
        id: match.id,
        lecture_id: meta.lecture_id ?? lecture_id,
        text: String(meta.text ?? ''),
        start_time: Number(meta.start_time ?? 0),
        end_time: Number(meta.end_time ?? 0),
        timestamp_label: String(meta.timestamp_label ?? '00:00'),
        topic: String(meta.topic ?? 'General'),
        chunk_index: Number(meta.chunk_index ?? i),
        word_count: String(meta.text ?? '').trim().split(/\s+/).length,
      };

      return {
        chunk,
        similarity_score: match.score ?? 0,
        rank: i + 1,
      };
    });

    console.log(`[Pinecone] Found ${ragContexts.length} relevant chunks`);
    return ragContexts;
  }

  async deleteByLecture(lecture_id: string): Promise<void> {
    console.log(`[Pinecone] Deleting all vectors for lecture ${lecture_id}`);

    // SDK v7: deleteMany takes { filter } or { ids }
    await getIndex().deleteMany({ filter: { lecture_id: { $eq: lecture_id } } });

    console.log(`[Pinecone] Deleted vectors for lecture ${lecture_id}`);
  }
}

export const pineconeService = new PineconeService();
