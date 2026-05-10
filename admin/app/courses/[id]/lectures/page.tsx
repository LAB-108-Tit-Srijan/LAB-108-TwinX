"use client";

import { useState, useEffect, useCallback, useRef } from "react";
import { useRouter, useParams } from "next/navigation";
import { Header } from "@/components/layout/header";
import { api, Course, Lecture } from "@/lib/api";
import { auth } from "@/lib/auth";
import { ArrowLeft, Plus, Trash2, CheckCircle2, Upload, Loader2, Search, ChevronDown, ChevronUp, FileVideo, X, AlertCircle } from "lucide-react";
import { formatDuration } from "@/lib/api";

function formatBytes(bytes: number): string {
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
  return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
}

interface InlineUploadFormProps {
  onSuccess: () => void;
}

function InlineUploadForm({ onSuccess }: InlineUploadFormProps) {
  const fileInputRef = useRef<HTMLInputElement>(null);
  const [expanded, setExpanded] = useState(false);
  const [title, setTitle] = useState("");
  const [instructor, setInstructor] = useState("");
  const [file, setFile] = useState<File | null>(null);
  const [progress, setProgress] = useState(0);
  const [uploading, setUploading] = useState(false);
  const [error, setError] = useState("");
  const [successMsg, setSuccessMsg] = useState("");

  function onFileChange(f: File) {
    const allowed = ["video/mp4", "video/quicktime", "video/x-msvideo", "video/x-matroska", "video/webm"];
    if (!allowed.includes(f.type)) {
      setError("Invalid file type. Please upload MP4, MOV, AVI, MKV, or WebM.");
      return;
    }
    if (f.size > 500 * 1024 * 1024) {
      setError("File too large. Maximum size is 500 MB.");
      return;
    }
    setFile(f);
    setError("");
  }

  async function handleUpload(e: React.FormEvent) {
    e.preventDefault();
    if (!file) { setError("Please select a video file."); return; }
    if (!title.trim()) { setError("Please enter a title."); return; }
    if (!instructor.trim()) { setError("Please enter an instructor name."); return; }

    setUploading(true);
    setProgress(0);
    setError("");
    setSuccessMsg("");

    const formData = new FormData();
    formData.append("video", file);
    formData.append("title", title.trim());
    formData.append("instructor", instructor.trim());

    try {
      await new Promise<string>((resolve, reject) => {
        const xhr = new XMLHttpRequest();
        xhr.upload.onprogress = (event) => {
          if (event.lengthComputable) {
            setProgress(Math.round((event.loaded / event.total) * 100));
          }
        };
        xhr.onload = () => {
          if (xhr.status >= 200 && xhr.status < 300) {
            const data = JSON.parse(xhr.responseText) as { success: boolean; lecture_id: string; error?: string };
            if (data.success) resolve(data.lecture_id);
            else reject(new Error(data.error ?? "Upload failed"));
          } else {
            reject(new Error(`Server error: ${xhr.status}`));
          }
        };
        xhr.onerror = () => reject(new Error("Network error. Check that the backend is running."));
        xhr.open("POST", "https://backend-aiva.mrsumi.com/api/video/upload");
        xhr.send(formData);
      });

      setSuccessMsg("Lecture uploaded successfully! It will appear in the list once processing completes.");
      setTitle("");
      setInstructor("");
      setFile(null);
      if (fileInputRef.current) fileInputRef.current.value = "";
      setProgress(0);
      setExpanded(false);
      onSuccess();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Upload failed. Please try again.");
    } finally {
      setUploading(false);
    }
  }

  const canSubmit = title.trim() && instructor.trim() && !!file && !uploading;

  return (
    <div className="bg-white rounded-2xl border border-[#E5E7EB] overflow-hidden mb-6">
      {/* Header / toggle */}
      <button
        type="button"
        onClick={() => { setExpanded((v) => !v); setError(""); setSuccessMsg(""); }}
        className="w-full flex items-center justify-between px-5 py-4 hover:bg-[#F5F6FA] transition-colors"
      >
        <div className="flex items-center gap-2 text-sm font-semibold text-[#1A1A2E]">
          <Upload size={16} className="text-[#6C63FF]" />
          Upload New Lecture
        </div>
        {expanded ? <ChevronUp size={16} className="text-[#9CA3AF]" /> : <ChevronDown size={16} className="text-[#9CA3AF]" />}
      </button>

      {successMsg && !expanded && (
        <div className="px-5 pb-4 flex items-center gap-2 text-sm text-[#10B981]">
          <CheckCircle2 size={15} className="flex-shrink-0" />
          {successMsg}
        </div>
      )}

      {expanded && (
        <div className="border-t border-[#F3F4F6] p-5">
          <form onSubmit={handleUpload} className="space-y-4">
            <div className="grid grid-cols-2 gap-4">
              {/* Title */}
              <div>
                <label className="text-xs font-medium text-[#1A1A2E] block mb-1">
                  Title <span className="text-[#EF4444]">*</span>
                </label>
                <input
                  value={title}
                  onChange={(e) => setTitle(e.target.value)}
                  placeholder="React Hooks Deep Dive"
                  required
                  disabled={uploading}
                  className="w-full px-3 py-2.5 border border-[#E5E7EB] rounded-xl text-sm focus:outline-none focus:border-[#6C63FF] focus:ring-2 focus:ring-[#6C63FF]/20 disabled:bg-[#F5F6FA] disabled:text-[#9CA3AF] transition-all"
                />
              </div>
              {/* Instructor */}
              <div>
                <label className="text-xs font-medium text-[#1A1A2E] block mb-1">
                  Instructor <span className="text-[#EF4444]">*</span>
                </label>
                <input
                  value={instructor}
                  onChange={(e) => setInstructor(e.target.value)}
                  placeholder="Amit Kumar"
                  required
                  disabled={uploading}
                  className="w-full px-3 py-2.5 border border-[#E5E7EB] rounded-xl text-sm focus:outline-none focus:border-[#6C63FF] focus:ring-2 focus:ring-[#6C63FF]/20 disabled:bg-[#F5F6FA] disabled:text-[#9CA3AF] transition-all"
                />
              </div>
            </div>

            {/* File picker */}
            <div>
              <label className="text-xs font-medium text-[#1A1A2E] block mb-1">
                Video File <span className="text-[#EF4444]">*</span>
              </label>
              <input
                ref={fileInputRef}
                type="file"
                accept="video/mp4,video/quicktime,video/x-msvideo,video/x-matroska,video/webm"
                className="hidden"
                onChange={(e) => { if (e.target.files?.[0]) onFileChange(e.target.files[0]); }}
              />
              {!file ? (
                <button
                  type="button"
                  onClick={() => fileInputRef.current?.click()}
                  disabled={uploading}
                  className="w-full flex items-center gap-2 px-4 py-3 border-2 border-dashed border-[#E5E7EB] rounded-xl text-sm text-[#9CA3AF] hover:border-[#6C63FF]/50 hover:text-[#6C63FF] hover:bg-[#F5F6FA] transition-all disabled:opacity-50"
                >
                  <FileVideo size={16} />
                  Click to select a video file (MP4, MOV, AVI, MKV · Max 500 MB)
                </button>
              ) : (
                <div className="flex items-center gap-3 px-4 py-3 border border-[#6C63FF]/30 bg-[#6C63FF]/5 rounded-xl">
                  <FileVideo size={16} className="text-[#6C63FF] flex-shrink-0" />
                  <div className="flex-1 min-w-0">
                    <p className="text-sm font-medium text-[#1A1A2E] truncate">{file.name}</p>
                    <p className="text-xs text-[#9CA3AF]">{formatBytes(file.size)}</p>
                  </div>
                  {!uploading && (
                    <button
                      type="button"
                      onClick={() => { setFile(null); if (fileInputRef.current) fileInputRef.current.value = ""; }}
                      className="p-1 rounded-lg hover:bg-[#EF4444]/10 text-[#9CA3AF] hover:text-[#EF4444] transition-colors"
                    >
                      <X size={14} />
                    </button>
                  )}
                </div>
              )}
            </div>

            {/* Progress bar */}
            {uploading && (
              <div>
                <div className="flex justify-between text-xs text-[#6B7280] mb-1">
                  <span>Uploading...</span>
                  <span className="font-semibold text-[#6C63FF]">{progress}%</span>
                </div>
                <div className="h-2 bg-[#E5E7EB] rounded-full overflow-hidden">
                  <div
                    className="h-full bg-gradient-to-r from-[#6C63FF] to-[#8B5CF6] rounded-full transition-all duration-300"
                    style={{ width: `${progress}%` }}
                  />
                </div>
              </div>
            )}

            {/* Error */}
            {error && (
              <div className="flex items-center gap-2 p-3 bg-red-50 border border-red-200 rounded-xl text-sm text-red-700">
                <AlertCircle size={15} className="flex-shrink-0" />
                {error}
              </div>
            )}

            {/* Actions */}
            <div className="flex items-center gap-3 pt-1">
              <button
                type="submit"
                disabled={!canSubmit}
                className="flex items-center gap-2 px-5 py-2.5 bg-gradient-to-r from-[#6C63FF] to-[#8B5CF6] text-white text-sm font-semibold rounded-xl hover:opacity-90 transition-opacity disabled:opacity-50 disabled:cursor-not-allowed"
              >
                {uploading ? (
                  <>
                    <span className="w-3.5 h-3.5 rounded-full border-2 border-white border-t-transparent animate-spin" />
                    Uploading...
                  </>
                ) : (
                  <>
                    <Upload size={14} />
                    Upload Lecture
                  </>
                )}
              </button>
              <button
                type="button"
                onClick={() => { setExpanded(false); setError(""); }}
                disabled={uploading}
                className="px-4 py-2.5 text-sm text-[#6B7280] border border-[#E5E7EB] rounded-xl hover:bg-[#F5F6FA] transition-colors disabled:opacity-50"
              >
                Cancel
              </button>
            </div>
          </form>
        </div>
      )}
    </div>
  );
}

export default function CourseLecturesPage() {
  const router = useRouter();
  const { id } = useParams<{ id: string }>();

  const [course, setCourse] = useState<Course | null>(null);
  const [courseLectures, setCourseLectures] = useState<Lecture[]>([]);
  const [allLectures, setAllLectures] = useState<Lecture[]>([]);
  const [search, setSearch] = useState("");
  const [loading, setLoading] = useState(true);
  const [publishing, setPublishing] = useState(false);
  const [error, setError] = useState("");

  const unassigned = allLectures.filter(
    (l) => !l.course_id && l.status === "ready" &&
      l.title.toLowerCase().includes(search.toLowerCase())
  );

  const load = useCallback(async () => {
    if (!auth.isLoggedIn()) { router.push("/login"); return; }
    try {
      setLoading(true);
      const [courseRes, lecturesRes] = await Promise.all([
        api.getCourse(id),
        api.getLectures(),
      ]);
      if (courseRes.success) {
        setCourse(courseRes.course);
        setCourseLectures(courseRes.lectures);
      }
      if (lecturesRes.success) {
        setAllLectures(lecturesRes.lectures);
      }
    } catch {
      setError("Failed to load data");
    } finally {
      setLoading(false);
    }
  }, [id, router]);

  useEffect(() => { load(); }, [load]);

  async function addLecture(lectureId: string) {
    await api.addLectureToCourse(id, lectureId, courseLectures.length);
    load();
  }

  async function removeLecture(lectureId: string) {
    if (!confirm("Remove this lecture from the course?")) return;
    await api.removeLectureFromCourse(id, lectureId);
    load();
  }

  async function handlePublish() {
    if (!confirm("Publish this course? Students will be able to enroll and see it.")) return;
    setPublishing(true);
    await api.publishCourse(id);
    setPublishing(false);
    load();
  }

  if (loading) {
    return (
      <div className="flex flex-col min-h-screen">
        <Header title="Manage Lectures" />
        <div className="flex-1 flex items-center justify-center">
          <Loader2 size={24} className="animate-spin text-[#6C63FF]" />
        </div>
      </div>
    );
  }

  return (
    <div className="flex flex-col min-h-screen">
      <Header title={`${course?.title ?? "Course"} — Lectures`} />
      <main className="flex-1 p-6">
        <button
          onClick={() => router.push("/courses")}
          className="flex items-center gap-2 text-sm text-[#6B7280] hover:text-[#1A1A2E] mb-6 transition-colors"
        >
          <ArrowLeft size={16} /> Back to Courses
        </button>

        {error && (
          <div className="mb-4 px-4 py-3 bg-[#FEF2F2] border border-[#FECACA] rounded-xl text-sm text-[#EF4444]">
            {error}
          </div>
        )}

        <InlineUploadForm onSuccess={load} />

        <div className="grid grid-cols-2 gap-6">
          {/* Left: Course lecture list */}
          <div className="bg-white rounded-2xl border border-[#E5E7EB] overflow-hidden">
            <div className="p-5 border-b border-[#F3F4F6]">
              <div className="flex items-center justify-between">
                <div>
                  <h3 className="font-bold text-[#1A1A2E]">{course?.title}</h3>
                  <p className="text-sm text-[#6B7280] mt-0.5">
                    {courseLectures.length} lectures • {course?.estimated_hours}h estimated
                  </p>
                </div>
                {course?.is_published ? (
                  <span className="flex items-center gap-1.5 text-xs font-semibold text-[#10B981] bg-[#10B981]/10 px-3 py-1.5 rounded-full">
                    <CheckCircle2 size={13} /> Published
                  </span>
                ) : (
                  <span className="text-xs font-semibold text-[#F59E0B] bg-[#F59E0B]/10 px-3 py-1.5 rounded-full">
                    Draft
                  </span>
                )}
              </div>
            </div>

            {courseLectures.length === 0 ? (
              <div className="p-8 text-center text-[#9CA3AF] text-sm">
                <Upload size={32} className="mx-auto mb-2 opacity-30" />
                No lectures added yet. Add from the right panel.
              </div>
            ) : (
              <ul className="divide-y divide-[#F3F4F6]">
                {courseLectures.map((lec, i) => (
                  <li key={lec.id} className="flex items-center gap-3 px-5 py-3.5">
                    <span className="w-7 h-7 flex items-center justify-center text-xs font-bold text-[#9CA3AF] bg-[#F5F6FA] rounded-full flex-shrink-0">
                      {i + 1}
                    </span>
                    <div className="flex-1 min-w-0">
                      <p className="text-sm font-medium text-[#1A1A2E] truncate">{lec.title}</p>
                      <p className="text-xs text-[#9CA3AF]">{formatDuration(lec.duration)}</p>
                    </div>
                    <span className={`text-xs px-2 py-0.5 rounded-full font-medium flex-shrink-0 ${
                      lec.status === "ready" ? "text-[#10B981] bg-[#10B981]/10" :
                      lec.status === "failed" ? "text-[#EF4444] bg-[#EF4444]/10" :
                      "text-[#F59E0B] bg-[#F59E0B]/10"
                    }`}>
                      {lec.status}
                    </span>
                    <button
                      onClick={() => removeLecture(lec.id)}
                      className="p-1.5 rounded-lg text-[#9CA3AF] hover:text-[#EF4444] hover:bg-[#FEF2F2] transition-colors flex-shrink-0"
                    >
                      <Trash2 size={14} />
                    </button>
                  </li>
                ))}
              </ul>
            )}

            {!course?.is_published && (
              <div className="p-4 border-t border-[#F3F4F6]">
                <button
                  onClick={handlePublish}
                  disabled={publishing || courseLectures.length === 0}
                  className="w-full flex items-center justify-center gap-2 py-3 bg-gradient-to-r from-[#10B981] to-[#059669] text-white text-sm font-semibold rounded-xl hover:opacity-90 transition-opacity disabled:opacity-50"
                >
                  {publishing ? <Loader2 size={16} className="animate-spin" /> : <CheckCircle2 size={16} />}
                  Publish Course
                </button>
              </div>
            )}
          </div>

          {/* Right: Unassigned lectures */}
          <div className="bg-white rounded-2xl border border-[#E5E7EB] overflow-hidden">
            <div className="p-5 border-b border-[#F3F4F6]">
              <h3 className="font-bold text-[#1A1A2E]">Add Lectures</h3>
              <p className="text-sm text-[#6B7280] mt-0.5">Ready lectures not yet in any course</p>
              <div className="mt-3 relative">
                <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-[#9CA3AF]" />
                <input
                  value={search}
                  onChange={(e) => setSearch(e.target.value)}
                  placeholder="Search lectures..."
                  className="w-full pl-9 pr-4 py-2 border border-[#E5E7EB] rounded-lg text-sm focus:outline-none focus:border-[#6C63FF]"
                />
              </div>
            </div>

            {unassigned.length === 0 ? (
              <div className="p-8 text-center text-[#9CA3AF] text-sm">
                <CheckCircle2 size={32} className="mx-auto mb-2 opacity-30" />
                {search ? "No matching lectures found" : "All ready lectures are assigned to courses"}
              </div>
            ) : (
              <ul className="divide-y divide-[#F3F4F6] max-h-[500px] overflow-y-auto">
                {unassigned.map((lec) => (
                  <li key={lec.id} className="flex items-center gap-3 px-5 py-3.5">
                    <div className="flex-1 min-w-0">
                      <p className="text-sm font-medium text-[#1A1A2E] truncate">{lec.title}</p>
                      <p className="text-xs text-[#9CA3AF]">
                        {lec.instructor} • {formatDuration(lec.duration)} • {lec.chunks_count} chunks
                      </p>
                    </div>
                    <button
                      onClick={() => addLecture(lec.id)}
                      className="flex items-center gap-1 px-3 py-1.5 text-xs font-semibold text-[#6C63FF] bg-[#6C63FF]/10 rounded-lg hover:bg-[#6C63FF]/20 transition-colors flex-shrink-0"
                    >
                      <Plus size={13} /> Add
                    </button>
                  </li>
                ))}
              </ul>
            )}
          </div>
        </div>
      </main>
    </div>
  );
}
