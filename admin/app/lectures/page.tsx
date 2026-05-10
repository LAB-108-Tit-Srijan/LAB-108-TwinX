"use client";

import { useState, useEffect, useRef, useCallback } from "react";
import { useRouter } from "next/navigation";
import { Header } from "@/components/layout/header";
import { api, Lecture, formatDuration, formatDate } from "@/lib/api";
import { Upload, Eye, Trash2, Filter, AlertCircle, RefreshCw, RotateCcw } from "lucide-react";

const COURSES = ["All", "React Mastery", "Node.js Backend", "DSA Fundamentals", "Python Basics", "System Design", "Database Design"];

function StatusBadge({ status }: { status: Lecture["status"] }) {
  const map: Record<Lecture["status"], { label: string; cls: string; spin?: boolean }> = {
    uploading:    { label: "Uploading",     cls: "bg-gray-100 text-gray-600" },
    transcribing: { label: "Transcribing",  cls: "bg-yellow-100 text-yellow-700", spin: true },
    processing:   { label: "Processing",    cls: "bg-blue-100 text-blue-700",  spin: true },
    ready:        { label: "Ready",         cls: "bg-green-100 text-green-700" },
    failed:       { label: "Failed",        cls: "bg-red-100 text-red-700" },
  };
  const { label, cls, spin } = map[status] ?? map.failed;
  return (
    <span className={`inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-lg text-xs font-semibold ${cls}`}>
      {spin && (
        <span className="w-3 h-3 rounded-full border-2 border-current border-t-transparent animate-spin" />
      )}
      {label}
    </span>
  );
}

function SkeletonRow() {
  return (
    <tr>
      {[1, 2, 3, 4, 5, 6, 7].map((i) => (
        <td key={i} className="px-6 py-4">
          <div className="h-4 bg-[#F3F4F6] rounded-lg animate-pulse" style={{ width: `${60 + Math.random() * 40}%` }} />
        </td>
      ))}
    </tr>
  );
}

export default function LecturesPage() {
  const router = useRouter();
  const [lectures, setLectures] = useState<Lecture[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [selectedCourse, setSelectedCourse] = useState("All");
  const [deletingId, setDeletingId] = useState<string | null>(null);
  const [retryingId, setRetryingId] = useState<string | null>(null);
  const intervalRef = useRef<ReturnType<typeof setInterval> | null>(null);

  const fetchLectures = useCallback(async () => {
    try {
      const data = await api.getLectures();
      if (data.success) setLectures(data.lectures);
    } catch {
      setError("Failed to connect to backend. Is the server running?");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchLectures();
    intervalRef.current = setInterval(fetchLectures, 5000);
    return () => {
      if (intervalRef.current) clearInterval(intervalRef.current);
    };
  }, [fetchLectures]);

  const handleRetry = async (id: string, title: string) => {
    setRetryingId(id);
    try {
      const data = await api.retryLecture(id);
      if (data.success) {
        setLectures((prev) =>
          prev.map((l) => l.id === id ? { ...l, status: 'transcribing', chunks_count: 0, duration: 0 } : l)
        );
        router.push(`/lectures/${id}/status`);
      } else {
        alert(`Retry failed: ${data.message}`);
      }
    } catch {
      alert("Failed to retry. Is the backend running?");
    } finally {
      setRetryingId(null);
    }
  };

  const handleDelete = async (id: string, title: string) => {
    if (!confirm(`Delete "${title}"?\n\nThis will permanently delete the lecture and all its AI data. Are you sure?`)) return;
    setDeletingId(id);
    try {
      await api.deleteLecture(id);
      setLectures((prev) => prev.filter((l) => l.id !== id));
    } catch {
      alert("Failed to delete lecture. Please try again.");
    } finally {
      setDeletingId(null);
    }
  };

  const filtered = selectedCourse === "All"
    ? lectures
    : lectures.filter((l) => l.course === selectedCourse);

  return (
    <div className="flex flex-col min-h-screen">
      <Header title="Lectures" />
      <main className="flex-1 p-6">
        <div className="flex items-center justify-between mb-6">
          <div className="flex items-center gap-3">
            <div className="flex items-center gap-2 text-sm text-[#6B7280]">
              <Filter size={15} />
              <span>Filter by course:</span>
            </div>
            <select
              value={selectedCourse}
              onChange={(e) => setSelectedCourse(e.target.value)}
              className="px-3 py-2 border border-[#E5E7EB] rounded-xl text-sm bg-white focus:outline-none focus:border-[#6C63FF]"
            >
              {COURSES.map((c) => <option key={c}>{c}</option>)}
            </select>
          </div>
          <div className="flex items-center gap-3">
            <button
              onClick={fetchLectures}
              className="p-2.5 border border-[#E5E7EB] rounded-xl text-[#6B7280] hover:bg-[#F5F6FA] hover:text-[#1A1A2E] transition-colors"
              title="Refresh"
            >
              <RefreshCw size={15} />
            </button>
            <button
              onClick={() => router.push("/lectures/upload")}
              className="flex items-center gap-2 px-4 py-2.5 bg-gradient-to-r from-[#6C63FF] to-[#8B5CF6] text-white text-sm font-semibold rounded-xl hover:opacity-90 transition-opacity shadow-sm shadow-[#6C63FF]/30"
            >
              <Upload size={15} />
              Upload Lecture
            </button>
          </div>
        </div>

        {error && (
          <div className="flex items-center gap-3 p-4 mb-6 bg-red-50 border border-red-200 rounded-xl text-sm text-red-700">
            <AlertCircle size={16} className="flex-shrink-0" />
            {error}
          </div>
        )}

        <div className="bg-white rounded-2xl border border-[#E5E7EB] overflow-hidden">
          <table className="w-full">
            <thead className="bg-[#F8F9FC]">
              <tr className="text-left">
                {["#", "Title", "Course", "Status", "Chunks", "Duration", "Created", "Actions"].map((h) => (
                  <th key={h} className="px-6 py-4 text-xs font-semibold text-[#9CA3AF] uppercase">{h}</th>
                ))}
              </tr>
            </thead>
            <tbody className="divide-y divide-[#F3F4F6]">
              {loading ? (
                Array.from({ length: 4 }).map((_, i) => <SkeletonRow key={i} />)
              ) : filtered.length === 0 ? (
                <tr>
                  <td colSpan={8} className="px-6 py-16 text-center">
                    <div className="flex flex-col items-center gap-3">
                      <div className="w-14 h-14 rounded-2xl bg-[#F5F6FA] flex items-center justify-center">
                        <Upload size={24} className="text-[#9CA3AF]" />
                      </div>
                      <p className="text-sm font-semibold text-[#1A1A2E]">No lectures yet</p>
                      <p className="text-xs text-[#9CA3AF]">Upload your first lecture to get started</p>
                      <button
                        onClick={() => router.push("/lectures/upload")}
                        className="mt-1 px-4 py-2 bg-gradient-to-r from-[#6C63FF] to-[#8B5CF6] text-white text-xs font-semibold rounded-xl hover:opacity-90 transition-opacity"
                      >
                        Upload Lecture
                      </button>
                    </div>
                  </td>
                </tr>
              ) : (
                filtered.map((lecture, i) => (
                  <tr key={lecture.id} className="hover:bg-[#F5F6FA] transition-colors">
                    <td className="px-6 py-4 text-sm text-[#9CA3AF]">{i + 1}</td>
                    <td className="px-6 py-4">
                      <div className="flex items-center gap-3">
                        <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-[#6C63FF] to-[#8B5CF6] flex items-center justify-center flex-shrink-0">
                          <span className="text-white text-lg">▶</span>
                        </div>
                        <div>
                          <p className="text-sm font-semibold text-[#1A1A2E]">{lecture.title}</p>
                          <p className="text-xs text-[#9CA3AF]">{lecture.instructor}</p>
                        </div>
                      </div>
                    </td>
                    <td className="px-6 py-4 text-sm text-[#6B7280]">{lecture.course}</td>
                    <td className="px-6 py-4"><StatusBadge status={lecture.status} /></td>
                    <td className="px-6 py-4 text-sm text-[#6B7280]">
                      {lecture.status === "ready" ? (
                        <span className="font-semibold text-[#1A1A2E]">{lecture.chunks_count}</span>
                      ) : "—"}
                    </td>
                    <td className="px-6 py-4 text-sm text-[#6B7280]">
                      {lecture.duration > 0 ? formatDuration(lecture.duration) : "—"}
                    </td>
                    <td className="px-6 py-4 text-sm text-[#6B7280]">{formatDate(lecture.created_at)}</td>
                    <td className="px-6 py-4">
                      <div className="flex items-center gap-2">
                        <button
                          onClick={() => router.push(`/lectures/${lecture.id}`)}
                          className="p-1.5 rounded-lg hover:bg-[#6C63FF]/10 text-[#6B7280] hover:text-[#6C63FF] transition-colors"
                          title="View"
                        >
                          <Eye size={15} />
                        </button>
                        {lecture.status === "failed" && (
                          <button
                            onClick={() => handleRetry(lecture.id, lecture.title)}
                            disabled={retryingId === lecture.id}
                            className="p-1.5 rounded-lg hover:bg-amber-100 text-[#6B7280] hover:text-amber-600 transition-colors disabled:opacity-50"
                            title="Retry processing"
                          >
                            {retryingId === lecture.id
                              ? <span className="w-[15px] h-[15px] block rounded-full border-2 border-amber-500 border-t-transparent animate-spin" />
                              : <RotateCcw size={15} />}
                          </button>
                        )}
                        <button
                          onClick={() => handleDelete(lecture.id, lecture.title)}
                          disabled={deletingId === lecture.id}
                          className="p-1.5 rounded-lg hover:bg-[#EF4444]/10 text-[#6B7280] hover:text-[#EF4444] transition-colors disabled:opacity-50"
                          title="Delete"
                        >
                          {deletingId === lecture.id
                            ? <span className="w-[15px] h-[15px] block rounded-full border-2 border-[#EF4444] border-t-transparent animate-spin" />
                            : <Trash2 size={15} />}
                        </button>
                      </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>

        {!loading && lectures.length > 0 && (
          <p className="mt-3 text-xs text-[#9CA3AF] text-right">
            Auto-refreshes every 5s · {lectures.filter(l => l.status !== "ready" && l.status !== "failed").length > 0
              ? "Processing in progress..."
              : `${lectures.length} lecture${lectures.length !== 1 ? "s" : ""} total`}
          </p>
        )}
      </main>
    </div>
  );
}
