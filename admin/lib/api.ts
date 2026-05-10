import { auth } from './auth';

const BASE_URL = 'https://demo11.mrsumi.com';

function authHeaders(): Record<string, string> {
  const token = auth.getToken();
  return {
    'Content-Type': 'application/json',
    ...(token ? { Authorization: `Bearer ${token}` } : {}),
  };
}

export interface Lecture {
  id: string;
  title: string;
  instructor: string;
  course: string;
  status: 'uploading' | 'transcribing' | 'processing' | 'ready' | 'failed';
  chunks_count: number;
  duration: number;
  created_at: string;
  updated_at?: string;
  course_id?: string | null;
  order_index?: number;
}

export interface Course {
  id: string;
  title: string;
  description?: string;
  instructor?: string;
  category?: string;
  thumbnail_color?: string;
  total_lectures: number;
  actual_lectures?: number;
  estimated_hours: number;
  expected_videos?: number;
  level?: string;
  is_published: boolean;
  created_at: string;
}

export interface Student {
  id: string;
  name: string | null;
  phone: string;
  credits_total: number;
  created_at: string;
}

export interface QuizQuestion {
  question: string;
  options: string[];
  correct_index: number;
  explanation: string;
}

export interface Chunk {
  id: string;
  lecture_id: string;
  text: string;
  start_time: number;
  end_time: number;
  timestamp_label: string;
  topic: string;
  chunk_index: number;
  word_count: number;
}

export interface LectureStatus {
  lecture_id: string;
  status: string;
  title: string;
  chunks_count: number;
  duration: number;
}

export interface AdminStats {
  total_students: number;
  total_courses: number;
  published_courses: number;
  total_lectures: number;
  ready_lectures: number;
  total_enrollments: number;
  completed_lectures: number;
  recent_enrollments: Array<{
    enrolled_at: string;
    student_name: string | null;
    phone: string;
    course_title: string;
  }>;
}

export interface DoubtsAnalytics {
  total_doubts: number;
  recent_doubts: Array<{ question: string; language: string; created_at: string; lecture_title: string | null }>;
  top_lectures_by_doubts: Array<{ title: string; doubts_count: number }>;
}

export const api = {
  // ── Lectures ──────────────────────────────────────────────────────────
  getLectures: (): Promise<{ success: boolean; lectures: Lecture[]; count: number }> =>
    fetch(`${BASE_URL}/api/lectures`, { headers: authHeaders() }).then((r) => r.json()),

  getLecture: (id: string): Promise<{ success: boolean; lecture: Lecture }> =>
    fetch(`${BASE_URL}/api/lectures/${id}`, { headers: authHeaders() }).then((r) => r.json()),

  getLectureChunks: (id: string): Promise<{ success: boolean; chunks: Chunk[] }> =>
    fetch(`${BASE_URL}/api/lectures/${id}/chunks`, { headers: authHeaders() }).then((r) => r.json()),

  getLectureStatus: (id: string): Promise<LectureStatus> =>
    fetch(`${BASE_URL}/api/video/${id}/status`, { headers: authHeaders() }).then((r) => r.json()),

  deleteLecture: (id: string): Promise<{ success: boolean; message: string }> =>
    fetch(`${BASE_URL}/api/lectures/${id}`, { method: 'DELETE', headers: authHeaders() }).then((r) => r.json()),

  retryLecture: (id: string): Promise<{ success: boolean; message: string; status: string }> =>
    fetch(`${BASE_URL}/api/video/${id}/retry`, { method: 'POST', headers: authHeaders() }).then((r) => r.json()),

  // ── Courses ──────────────────────────────────────────────────────────
  getCourses: (): Promise<{ success: boolean; courses: Course[] }> =>
    fetch(`${BASE_URL}/api/courses/all`, { headers: authHeaders() }).then((r) => r.json()),

  getCourse: (id: string): Promise<{ success: boolean; course: Course; lectures: Lecture[] }> =>
    fetch(`${BASE_URL}/api/courses/${id}`, { headers: authHeaders() }).then((r) => r.json()),

  createCourse: (data: Partial<Course> & { expected_videos?: number }): Promise<{ success: boolean; course: Course }> =>
    fetch(`${BASE_URL}/api/courses`, {
      method: 'POST',
      headers: authHeaders(),
      body: JSON.stringify(data),
    }).then((r) => r.json()),

  updateCourse: (id: string, data: Partial<Course>): Promise<{ success: boolean; course: Course }> =>
    fetch(`${BASE_URL}/api/courses/${id}`, {
      method: 'PUT',
      headers: authHeaders(),
      body: JSON.stringify(data),
    }).then((r) => r.json()),

  publishCourse: (id: string): Promise<{ success: boolean; message: string }> =>
    fetch(`${BASE_URL}/api/courses/${id}/publish`, { method: 'POST', headers: authHeaders() }).then((r) => r.json()),

  addLectureToCourse: (courseId: string, lectureId: string, orderIndex: number): Promise<{ success: boolean }> =>
    fetch(`${BASE_URL}/api/courses/${courseId}/lectures`, {
      method: 'POST',
      headers: authHeaders(),
      body: JSON.stringify({ lecture_id: lectureId, order_index: orderIndex }),
    }).then((r) => r.json()),

  removeLectureFromCourse: (courseId: string, lectureId: string): Promise<{ success: boolean }> =>
    fetch(`${BASE_URL}/api/courses/${courseId}/lectures/${lectureId}`, {
      method: 'DELETE',
      headers: authHeaders(),
    }).then((r) => r.json()),

  // ── Students ──────────────────────────────────────────────────────────
  getStudents: (): Promise<{ success: boolean; students: Student[]; count: number }> =>
    fetch(`${BASE_URL}/api/students`, { headers: authHeaders() }).then((r) => r.json()),

  // ── Admin Stats ───────────────────────────────────────────────────────
  getAdminStats: (): Promise<{ success: boolean; stats: AdminStats }> =>
    fetch(`${BASE_URL}/api/admin/stats`, { headers: authHeaders() }).then((r) => r.json()),

  getDoubtsAnalytics: (): Promise<{ success: boolean; analytics: DoubtsAnalytics }> =>
    fetch(`${BASE_URL}/api/admin/doubts-analytics`, { headers: authHeaders() }).then((r) => r.json()),

  // ── Quiz ──────────────────────────────────────────────────────────────
  getQuiz: (lectureId: string): Promise<{ success: boolean; quiz: { lecture_id: string; questions: QuizQuestion[] } }> =>
    fetch(`${BASE_URL}/api/quiz/${lectureId}`, { headers: authHeaders() }).then((r) => r.json()),

  // ── Notes ─────────────────────────────────────────────────────────────
  getLectureNotes: (lectureId: string): Promise<{ success: boolean; notes: { lecture_id: string; content: string; generated_at: string } }> =>
    fetch(`${BASE_URL}/api/notes/${lectureId}`, { headers: authHeaders() }).then((r) => r.json()),

  // ── Auth ─────────────────────────────────────────────────────────────
  adminLogin: (email: string, password: string): Promise<{ success: boolean; token?: string; error?: string; admin?: { id: string; name: string; email: string } }> =>
    fetch(`${BASE_URL}/api/admin/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, password }),
    }).then((r) => r.json()),

  // ── Chat (SSE) ────────────────────────────────────────────────────────
  askQuestion: async (
    lectureId: string,
    question: string,
    language: string,
    onChunk: (text: string) => void,
    onDone: (data: unknown) => void
  ): Promise<void> => {
    const response = await fetch(`${BASE_URL}/api/ask`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ lecture_id: lectureId, question, language, chat_history: [] }),
    });

    const reader = response.body!.getReader();
    const decoder = new TextDecoder();

    while (true) {
      const { done, value } = await reader.read();
      if (done) break;
      const chunk = decoder.decode(value);
      for (const line of chunk.split('\n')) {
        if (line.startsWith('data: ')) {
          try {
            const data = JSON.parse(line.slice(6));
            if (data.type === 'delta') onChunk(data.text as string);
            if (data.type === 'done') onDone(data);
          } catch {
            // ignore malformed SSE lines
          }
        }
      }
    }
  },
};

export function formatDuration(seconds: number): string {
  const h = Math.floor(seconds / 3600);
  const m = Math.floor((seconds % 3600) / 60);
  const s = Math.floor(seconds % 60);
  if (h > 0) return `${h}h ${m}m`;
  if (m > 0) return `${m}m ${s}s`;
  return `${s}s`;
}

export function formatDate(iso: string): string {
  const d = new Date(iso);
  return d.toLocaleDateString('en-IN', { day: '2-digit', month: 'short', year: 'numeric' });
}
