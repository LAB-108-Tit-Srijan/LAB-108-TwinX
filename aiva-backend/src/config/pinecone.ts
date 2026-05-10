import { Pinecone, Index } from '@pinecone-database/pinecone';

const pinecone = new Pinecone({
  apiKey: process.env.PINECONE_API_KEY!,
});

export const getIndex = (): Index => pinecone.index(process.env.PINECONE_INDEX_NAME!);
