import OpenAI from 'openai';
import { env } from '../config/env';

const EMBEDDING_MODEL = 'text-embedding-3-small';

export class EmbeddingService {
  private client: OpenAI;

  constructor() {
    this.client = new OpenAI({ apiKey: env.OPENAI_API_KEY });
  }

  async embedText(text: string): Promise<number[]> {
    console.log('[Embedding] Embedding single text snippet');
    try {
      const response = await this.client.embeddings.create({
        model: EMBEDDING_MODEL,
        input: text,
      });
      return response.data[0].embedding;
    } catch (err) {
      const message = err instanceof Error ? err.message : String(err);
      throw new Error(`[Embedding] Failed to embed text: ${message}`);
    }
  }

  async embedBatch(texts: string[]): Promise<number[][]> {
    console.log(`[Embedding] Batch embedding ${texts.length} texts`);

    const BATCH_SIZE = 100;
    const allEmbeddings: number[][] = [];

    for (let i = 0; i < texts.length; i += BATCH_SIZE) {
      const batch = texts.slice(i, i + BATCH_SIZE);
      console.log(`[Embedding] Processing batch ${Math.floor(i / BATCH_SIZE) + 1} (${batch.length} items)`);

      try {
        const response = await this.client.embeddings.create({
          model: EMBEDDING_MODEL,
          input: batch,
        });

        const sorted = response.data.sort((a, b) => a.index - b.index);
        allEmbeddings.push(...sorted.map((d) => d.embedding));
      } catch (err) {
        const message = err instanceof Error ? err.message : String(err);
        throw new Error(`[Embedding] Batch embedding failed at index ${i}: ${message}`);
      }
    }

    console.log(`[Embedding] Done. Generated ${allEmbeddings.length} embeddings`);
    return allEmbeddings;
  }

  async embedQuestion(question: string): Promise<number[]> {
    console.log('[Embedding Question] Embedding student question');
    try {
      const response = await this.client.embeddings.create({
        model: EMBEDDING_MODEL,
        input: question,
      });
      return response.data[0].embedding;
    } catch (err) {
      const message = err instanceof Error ? err.message : String(err);
      throw new Error(`[Embedding] Failed to embed question: ${message}`);
    }
  }
}

export const embeddingService = new EmbeddingService();
