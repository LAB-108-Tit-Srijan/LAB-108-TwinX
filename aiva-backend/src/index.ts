import express from 'express';
import cors from 'cors';
import morgan from 'morgan';
import path from 'path';
import fs from 'fs';
import { env } from './config/env';
import { initDB } from './config/db';
import videoRoutes from './routes/video.routes';
import askRoutes from './routes/ask.routes';
import lectureRoutes from './routes/lecture.routes';
import authRoutes from './routes/auth.routes';
import courseRoutes from './routes/course.routes';
import enrollmentRoutes from './routes/enrollment.routes';
import roadmapRoutes from './routes/roadmap.routes';
import progressRoutes from './routes/progress.routes';
import quizRoutes from './routes/quiz.routes';
import notesRoutes from './routes/notes.routes';
import todoRoutes from './routes/todo.routes';
import profileRoutes from './routes/profile.routes';
import { errorMiddleware } from './middleware/error.middleware';
import { queueService } from './services/queue.service';

const app = express();

const uploadsDir = path.join(process.cwd(), 'uploads');
if (!fs.existsSync(uploadsDir)) {
  fs.mkdirSync(uploadsDir, { recursive: true });
}

app.use(cors());
app.use(express.json());
app.use(morgan('dev'));

app.use('/api/video', videoRoutes);
app.use('/api', askRoutes);
app.use('/api', lectureRoutes);
app.use('/api', authRoutes);
app.use('/api', courseRoutes);
app.use('/api', enrollmentRoutes);
app.use('/api', roadmapRoutes);
app.use('/api', progressRoutes);
app.use('/api', quizRoutes);
app.use('/api', notesRoutes);
app.use('/api', todoRoutes);
app.use('/api', profileRoutes);

app.get('/health', (_req, res) => {
  res.json({ status: 'ok', service: 'aiva-backend' });
});

// Serve the feature tester at http://localhost:5000/test
app.get('/test', (_req, res) => {
  const testFile = path.join(process.cwd(), 'test-features.html');
  if (fs.existsSync(testFile)) {
    res.sendFile(testFile);
  } else {
    res.status(404).send('test-features.html not found in project root');
  }
});

app.use(errorMiddleware);

app.listen(env.PORT, async () => {
  await initDB();
  console.log('[AIVA] Database tables initialized');
  await queueService.resumePendingJobs();
  console.log(`[AIVA] Server running on http://localhost:${env.PORT}`);
  console.log(`[AIVA] Pinecone index: ${env.PINECONE_INDEX_NAME}`);
});

export default app;
