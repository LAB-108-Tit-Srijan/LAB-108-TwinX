import dotenv from 'dotenv';

dotenv.config();

export const env = {
  PORT: parseInt(process.env.PORT || '8000', 10),
  ANTHROPIC_API_KEY: process.env.ANTHROPIC_API_KEY || '',
  OPENAI_API_KEY: process.env.OPENAI_API_KEY || '',
  DATABASE_URL: process.env.DATABASE_URL || '',
  PINECONE_API_KEY: process.env.PINECONE_API_KEY || '',
  PINECONE_INDEX_NAME: process.env.PINECONE_INDEX_NAME || 'aiva-lectures',
  MAX_FILE_SIZE_MB: parseInt(process.env.MAX_FILE_SIZE_MB || '500', 10),
  CHUNK_SIZE: parseInt(process.env.CHUNK_SIZE || '300', 10),
  CHUNK_OVERLAP: parseInt(process.env.CHUNK_OVERLAP || '50', 10),
  ADMIN_JWT_SECRET: process.env.ADMIN_JWT_SECRET || 'aiva_admin_secret_2025',
  STUDENT_JWT_SECRET: process.env.STUDENT_JWT_SECRET || 'aiva_student_secret_2025',
} as const;

function validateEnv(): void {
  const required = ['ANTHROPIC_API_KEY', 'OPENAI_API_KEY', 'DATABASE_URL', 'PINECONE_API_KEY'] as const;
  const missing = required.filter((key) => !process.env[key]);
  if (missing.length > 0) {
    throw new Error(`Missing required environment variables: ${missing.join(', ')}`);
  }
}

validateEnv();
