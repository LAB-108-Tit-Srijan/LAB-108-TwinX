import { Pool, QueryResult } from 'pg';
import bcrypt from 'bcryptjs';

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
});

export const query = (text: string, params?: unknown[]): Promise<QueryResult> =>
  pool.query(text, params);

export async function initDB(): Promise<void> {
  // Core tables
  await pool.query(`
    CREATE TABLE IF NOT EXISTS lectures (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      title VARCHAR(255) NOT NULL,
      instructor VARCHAR(255) NOT NULL,
      course VARCHAR(255) NOT NULL,
      video_path TEXT,
      duration FLOAT DEFAULT 0,
      status VARCHAR(50) DEFAULT 'uploading',
      chunks_count INTEGER DEFAULT 0,
      created_at TIMESTAMP DEFAULT NOW(),
      updated_at TIMESTAMP DEFAULT NOW()
    );

    CREATE TABLE IF NOT EXISTS transcript_chunks (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      lecture_id UUID REFERENCES lectures(id) ON DELETE CASCADE,
      text TEXT NOT NULL,
      start_time FLOAT NOT NULL,
      end_time FLOAT NOT NULL,
      timestamp_label VARCHAR(20),
      topic VARCHAR(100),
      chunk_index INTEGER,
      word_count INTEGER,
      created_at TIMESTAMP DEFAULT NOW()
    );
  `);

  // Feature 1: summary columns (idempotent)
  await pool.query(`
    ALTER TABLE lectures ADD COLUMN IF NOT EXISTS summary_full TEXT;
    ALTER TABLE lectures ADD COLUMN IF NOT EXISTS summary_topics JSONB;
    ALTER TABLE lectures ADD COLUMN IF NOT EXISTS chapters JSONB;
  `);

  // Feature 5: processing queue
  await pool.query(`
    CREATE TABLE IF NOT EXISTS processing_queue (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      lecture_id UUID REFERENCES lectures(id),
      status VARCHAR(50) DEFAULT 'pending',
      current_step VARCHAR(100),
      error_message TEXT,
      started_at TIMESTAMP,
      completed_at TIMESTAMP,
      created_at TIMESTAMP DEFAULT NOW()
    );
  `);

  // Feature 3: index for fast timestamp lookups
  await pool.query(`
    CREATE INDEX IF NOT EXISTS idx_chunks_lecture_time
    ON transcript_chunks(lecture_id, start_time, end_time);
  `);

  // ── New tables for courses, students, auth, roadmaps ──

  await pool.query(`
    CREATE TABLE IF NOT EXISTS admins (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      name VARCHAR(255) NOT NULL,
      email VARCHAR(255) UNIQUE NOT NULL,
      password_hash TEXT NOT NULL,
      created_at TIMESTAMP DEFAULT NOW()
    );

    CREATE TABLE IF NOT EXISTS courses (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      title VARCHAR(255) NOT NULL,
      description TEXT,
      instructor VARCHAR(255),
      category VARCHAR(100),
      thumbnail_color VARCHAR(20) DEFAULT '#6C63FF',
      total_lectures INTEGER DEFAULT 0,
      estimated_hours INTEGER DEFAULT 0,
      level VARCHAR(50) DEFAULT 'Beginner',
      is_published BOOLEAN DEFAULT false,
      created_by UUID REFERENCES admins(id),
      created_at TIMESTAMP DEFAULT NOW()
    );

    CREATE TABLE IF NOT EXISTS students (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      name VARCHAR(255),
      phone VARCHAR(20) UNIQUE NOT NULL,
      device_id TEXT,
      created_at TIMESTAMP DEFAULT NOW()
    );

    CREATE TABLE IF NOT EXISTS enrollments (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      student_id UUID REFERENCES students(id),
      course_id UUID REFERENCES courses(id),
      enrolled_at TIMESTAMP DEFAULT NOW(),
      UNIQUE(student_id, course_id)
    );

    CREATE TABLE IF NOT EXISTS roadmaps (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      enrollment_id UUID REFERENCES enrollments(id),
      student_id UUID REFERENCES students(id),
      course_id UUID REFERENCES courses(id),
      goal TEXT,
      daily_hours INTEGER DEFAULT 1,
      target_days INTEGER DEFAULT 30,
      plan JSONB,
      created_at TIMESTAMP DEFAULT NOW()
    );

    CREATE TABLE IF NOT EXISTS watch_progress (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      student_id UUID REFERENCES students(id),
      lecture_id UUID REFERENCES lectures(id),
      watched_seconds INTEGER DEFAULT 0,
      total_seconds INTEGER DEFAULT 0,
      completed BOOLEAN DEFAULT false,
      last_watched TIMESTAMP DEFAULT NOW(),
      UNIQUE(student_id, lecture_id)
    );
  `);

  // Add course_id and order_index to lectures
  await pool.query(`
    ALTER TABLE lectures ADD COLUMN IF NOT EXISTS course_id UUID REFERENCES courses(id);
    ALTER TABLE lectures ADD COLUMN IF NOT EXISTS order_index INTEGER DEFAULT 0;
  `);

  // LMS feature tables
  await pool.query(`
    CREATE TABLE IF NOT EXISTS otps (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      phone VARCHAR(20) NOT NULL,
      otp VARCHAR(10) NOT NULL,
      expires_at TIMESTAMP NOT NULL,
      used BOOLEAN DEFAULT false,
      created_at TIMESTAMP DEFAULT NOW()
    );

    CREATE TABLE IF NOT EXISTS quizzes (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      lecture_id UUID UNIQUE REFERENCES lectures(id) ON DELETE CASCADE,
      questions JSONB NOT NULL,
      generated_at TIMESTAMP DEFAULT NOW()
    );

    CREATE TABLE IF NOT EXISTS quiz_attempts (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      student_id UUID REFERENCES students(id),
      lecture_id UUID REFERENCES lectures(id),
      answers JSONB,
      score INTEGER DEFAULT 0,
      total INTEGER DEFAULT 0,
      completed_at TIMESTAMP DEFAULT NOW(),
      UNIQUE(student_id, lecture_id)
    );

    CREATE TABLE IF NOT EXISTS lecture_notes (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      lecture_id UUID UNIQUE REFERENCES lectures(id) ON DELETE CASCADE,
      content TEXT NOT NULL,
      generated_at TIMESTAMP DEFAULT NOW()
    );

    CREATE TABLE IF NOT EXISTS todos (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      student_id UUID REFERENCES students(id),
      title TEXT NOT NULL,
      completed BOOLEAN DEFAULT false,
      created_at TIMESTAMP DEFAULT NOW()
    );

    CREATE TABLE IF NOT EXISTS credits (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      student_id UUID REFERENCES students(id),
      amount INTEGER NOT NULL,
      reason TEXT,
      created_at TIMESTAMP DEFAULT NOW()
    );
  `);

  // LMS column additions (idempotent)
  await pool.query(`
    ALTER TABLE enrollments ADD COLUMN IF NOT EXISTS target_weeks INTEGER DEFAULT 4;
    ALTER TABLE enrollments ADD COLUMN IF NOT EXISTS start_date DATE DEFAULT CURRENT_DATE;
    ALTER TABLE courses ADD COLUMN IF NOT EXISTS expected_videos INTEGER DEFAULT 0;
    ALTER TABLE students ADD COLUMN IF NOT EXISTS credits_total INTEGER DEFAULT 0;
  `);

  // Chat logs table
  await pool.query(`
    CREATE TABLE IF NOT EXISTS chat_logs (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      lecture_id UUID REFERENCES lectures(id) ON DELETE SET NULL,
      question TEXT NOT NULL,
      language VARCHAR(10) DEFAULT 'en',
      created_at TIMESTAMP DEFAULT NOW()
    );
  `);

  // Seed default admin (password: admin123)
  const existing = await pool.query(`SELECT id FROM admins WHERE email = 'admin@aiva.com'`);
  if (existing.rows.length === 0) {
    const hash = await bcrypt.hash('admin123', 10);
    await pool.query(
      `INSERT INTO admins (name, email, password_hash) VALUES ($1, $2, $3)`,
      ['Super Admin', 'admin@aiva.com', hash]
    );
    console.log('[DB] Default admin seeded: admin@aiva.com / admin123');
  }

  console.log('[DB] Tables and indexes initialized');
}
