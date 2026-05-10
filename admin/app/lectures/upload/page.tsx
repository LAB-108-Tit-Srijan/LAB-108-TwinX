"use client";

import { useState, useRef, useCallback } from "react";
import { useRouter } from "next/navigation";
import Link from "next/link";
import { Header } from "@/components/layout/header";
import {
  ArrowLeft,
  UploadCloud,
  FileVideo,
  CheckCircle2,
  AlertCircle,
  X,
} from "lucide-react";

const COURSES = [
  "React Mastery",
  "Node.js Backend",
  "DSA Fundamentals",
  "Python Basics",
  "System Design",
  "Database Design",
];

function formatBytes(bytes: number): string {
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
  return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
}

export default function UploadLecturePage() {
  const router = useRouter();
  const fileInputRef = useRef<HTMLInputElement>(null);

  const [title, setTitle] = useState("");
  const [instructor, setInstructor] = useState("");
  const [course, setCourse] = useState(COURSES[0]);
  const [customCourse, setCustomCourse] = useState("");
  const [useCustomCourse, setUseCustomCourse] = useState(false);
  const [file, setFile] = useState<File | null>(null);
  const [isDragging, setIsDragging] = useState(false);
  const [progress, setProgress] = useState(0);
  const [uploading, setUploading] = useState(false);
  const [error, setError] = useState("");

  const onFileChange = (f: File) => {
    const allowed = ["video/mp4", "video/quicktime", "video/x-msvideo", "video/x-matroska", "video/webm"];
    if (!allowed.includes(f.type)) {
      setError("Invalid file type. Please upload MP4, MOV, AVI, or MKV.");
      return;
    }
    if (f.size > 500 * 1024 * 1024) {
      setError("File too large. Maximum size is 500 MB.");
      return;
    }
    setFile(f);
    setError("");
  };

  const onDrop = useCallback((e: React.DragEvent) => {
    e.preventDefault();
    setIsDragging(false);
    const dropped = e.dataTransfer.files[0];
    if (dropped) onFileChange(dropped);
  }, []);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!file) { setError("Please select a video file."); return; }
    const finalCourse = useCustomCourse ? customCourse.trim() : course;
    if (!finalCourse) { setError("Please enter a course name."); return; }

    setUploading(true);
    setProgress(0);
    setError("");

    const formData = new FormData();
    formData.append("video", file);
    formData.append("title", title.trim());
    formData.append("instructor", instructor.trim());
    formData.append("course", finalCourse);

    try {
      const lectureId = await new Promise<string>((resolve, reject) => {
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

      router.push(`/lectures/${lectureId}/status`);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Upload failed. Please try again.");
      setUploading(false);
    }
  };

  const canSubmit = title.trim() && instructor.trim() && file && !uploading;

  return (
    <div className="flex flex-col min-h-screen">
      <Header title="Upload Lecture" />
      <main className="flex-1 p-6">
        <div className="flex items-center gap-3 mb-6">
          <Link
            href="/lectures"
            className="p-2 rounded-xl border border-[#E5E7EB] hover:bg-[#F5F6FA] text-[#6B7280] hover:text-[#1A1A2E] transition-colors"
          >
            <ArrowLeft size={16} />
          </Link>
          <h2 className="text-lg font-bold text-[#1A1A2E]">Upload New Lecture</h2>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-[1fr_360px] gap-6">
          {/* LEFT — Form */}
          <div className="bg-white rounded-2xl border border-[#E5E7EB] p-6">
            <form onSubmit={handleSubmit} className="space-y-5">

              {/* Title */}
              <div>
                <label className="text-sm font-medium text-[#1A1A2E] block mb-1.5">
                  Lecture Title <span className="text-[#EF4444]">*</span>
                </label>
                <input
                  value={title}
                  onChange={(e) => setTitle(e.target.value)}
                  placeholder="React Hooks Deep Dive"
                  required
                  disabled={uploading}
                  className="w-full px-4 py-3 border border-[#E5E7EB] rounded-xl text-sm focus:outline-none focus:border-[#6C63FF] focus:ring-2 focus:ring-[#6C63FF]/20 disabled:bg-[#F5F6FA] disabled:text-[#9CA3AF] transition-all"
                />
              </div>

              {/* Instructor */}
              <div>
                <label className="text-sm font-medium text-[#1A1A2E] block mb-1.5">
                  Instructor Name <span className="text-[#EF4444]">*</span>
                </label>
                <input
                  value={instructor}
                  onChange={(e) => setInstructor(e.target.value)}
                  placeholder="Amit Kumar"
                  required
                  disabled={uploading}
                  className="w-full px-4 py-3 border border-[#E5E7EB] rounded-xl text-sm focus:outline-none focus:border-[#6C63FF] focus:ring-2 focus:ring-[#6C63FF]/20 disabled:bg-[#F5F6FA] disabled:text-[#9CA3AF] transition-all"
                />
              </div>

              {/* Course */}
              <div>
                <label className="text-sm font-medium text-[#1A1A2E] block mb-1.5">Course</label>
                {!useCustomCourse ? (
                  <div className="flex gap-2">
                    <select
                      value={course}
                      onChange={(e) => setCourse(e.target.value)}
                      disabled={uploading}
                      className="flex-1 px-4 py-3 border border-[#E5E7EB] rounded-xl text-sm focus:outline-none focus:border-[#6C63FF] bg-white disabled:bg-[#F5F6FA] disabled:text-[#9CA3AF]"
                    >
                      {COURSES.map((c) => <option key={c}>{c}</option>)}
                    </select>
                    <button
                      type="button"
                      onClick={() => setUseCustomCourse(true)}
                      className="px-3 py-2 text-xs text-[#6C63FF] border border-[#6C63FF]/30 rounded-xl hover:bg-[#6C63FF]/5 transition-colors whitespace-nowrap"
                    >
                      + Custom
                    </button>
                  </div>
                ) : (
                  <div className="flex gap-2">
                    <input
                      value={customCourse}
                      onChange={(e) => setCustomCourse(e.target.value)}
                      placeholder="Enter course name"
                      disabled={uploading}
                      className="flex-1 px-4 py-3 border border-[#6C63FF] rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-[#6C63FF]/20 disabled:bg-[#F5F6FA]"
                      autoFocus
                    />
                    <button
                      type="button"
                      onClick={() => { setUseCustomCourse(false); setCustomCourse(""); }}
                      className="px-3 py-2 text-xs text-[#6B7280] border border-[#E5E7EB] rounded-xl hover:bg-[#F5F6FA] transition-colors"
                    >
                      <X size={14} />
                    </button>
                  </div>
                )}
              </div>

              {/* File Upload */}
              <div>
                <label className="text-sm font-medium text-[#1A1A2E] block mb-1.5">
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
                  <div
                    onDragOver={(e) => { e.preventDefault(); setIsDragging(true); }}
                    onDragEnter={(e) => { e.preventDefault(); setIsDragging(true); }}
                    onDragLeave={() => setIsDragging(false)}
                    onDrop={onDrop}
                    onClick={() => fileInputRef.current?.click()}
                    className={`border-2 border-dashed rounded-2xl p-10 text-center cursor-pointer transition-all select-none ${
                      isDragging
                        ? "border-[#6C63FF] bg-[#6C63FF]/5 scale-[1.01]"
                        : "border-[#E5E7EB] hover:border-[#6C63FF]/50 hover:bg-[#F5F6FA]"
                    }`}
                  >
                    <UploadCloud size={36} className={`mx-auto mb-3 ${isDragging ? "text-[#6C63FF]" : "text-[#9CA3AF]"}`} />
                    <p className="text-sm font-semibold text-[#1A1A2E]">Drag & drop your lecture video</p>
                    <p className="text-xs text-[#9CA3AF] mt-1 mb-4">Supports MP4, MOV, AVI, MKV · Max 500MB</p>
                    <span className="px-4 py-2 bg-[#6C63FF]/10 text-[#6C63FF] text-xs font-semibold rounded-lg hover:bg-[#6C63FF]/20 transition-colors">
                      Browse Files
                    </span>
                  </div>
                ) : (
                  <div className="border-2 border-[#6C63FF]/30 bg-[#6C63FF]/5 rounded-2xl p-5">
                    <div className="flex items-center gap-3">
                      <div className="w-10 h-10 rounded-xl bg-[#6C63FF]/10 flex items-center justify-center flex-shrink-0">
                        <FileVideo size={20} className="text-[#6C63FF]" />
                      </div>
                      <div className="flex-1 min-w-0">
                        <p className="text-sm font-semibold text-[#1A1A2E] truncate">{file.name}</p>
                        <p className="text-xs text-[#9CA3AF]">{formatBytes(file.size)}</p>
                      </div>
                      {!uploading && (
                        <button
                          type="button"
                          onClick={() => { setFile(null); if (fileInputRef.current) fileInputRef.current.value = ""; }}
                          className="p-1.5 rounded-lg hover:bg-[#EF4444]/10 text-[#9CA3AF] hover:text-[#EF4444] transition-colors"
                        >
                          <X size={14} />
                        </button>
                      )}
                    </div>
                    {uploading && (
                      <div className="mt-4">
                        <div className="flex justify-between text-xs text-[#6B7280] mb-1.5">
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
                  </div>
                )}
              </div>

              {/* Error */}
              {error && (
                <div className="flex items-center gap-2 p-3 bg-red-50 border border-red-200 rounded-xl text-sm text-red-700">
                  <AlertCircle size={15} className="flex-shrink-0" />
                  {error}
                </div>
              )}

              {/* Submit */}
              <button
                type="submit"
                disabled={!canSubmit}
                className="w-full py-3.5 bg-gradient-to-r from-[#6C63FF] to-[#8B5CF6] text-white text-sm font-semibold rounded-xl hover:opacity-90 transition-opacity shadow-sm shadow-[#6C63FF]/30 disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-2"
              >
                {uploading ? (
                  <>
                    <span className="w-4 h-4 rounded-full border-2 border-white border-t-transparent animate-spin" />
                    Uploading...
                  </>
                ) : (
                  <>
                    <UploadCloud size={16} />
                    Upload & Process Lecture
                  </>
                )}
              </button>
            </form>
          </div>

          {/* RIGHT — Info */}
          <div className="space-y-4">
            {/* How it works */}
            <div className="bg-white rounded-2xl border border-[#E5E7EB] p-6">
              <h3 className="text-sm font-bold text-[#1A1A2E] mb-4">How it works</h3>
              <div className="space-y-3">
                {[
                  { icon: "📤", step: "1", label: "Upload your video file" },
                  { icon: "🎙️", step: "2", label: "AIVA transcribes automatically" },
                  { icon: "🧠", step: "3", label: "Transcript is chunked + embedded" },
                  { icon: "✅", step: "4", label: "Students can ask doubts instantly" },
                ].map(({ icon, step, label }) => (
                  <div key={step} className="flex items-center gap-3">
                    <div className="w-8 h-8 rounded-xl bg-[#6C63FF]/10 flex items-center justify-center flex-shrink-0 text-base">
                      {icon}
                    </div>
                    <div>
                      <p className="text-xs text-[#9CA3AF] leading-none mb-0.5">Step {step}</p>
                      <p className="text-sm font-medium text-[#1A1A2E]">{label}</p>
                    </div>
                  </div>
                ))}
              </div>
            </div>

            {/* Processing time */}
            <div className="bg-amber-50 border border-amber-200 rounded-2xl p-4">
              <div className="flex items-center gap-2 mb-1.5">
                <span className="text-base">⏱️</span>
                <p className="text-sm font-semibold text-amber-800">Processing Time</p>
              </div>
              <p className="text-xs text-amber-700">
                A 1 hour lecture takes <strong>~3–5 minutes</strong> to process. You can close this page — processing continues in the background.
              </p>
            </div>

            {/* Formats */}
            <div className="bg-white rounded-2xl border border-[#E5E7EB] p-4">
              <p className="text-xs font-semibold text-[#9CA3AF] uppercase mb-3">Supported Formats</p>
              <div className="grid grid-cols-2 gap-2">
                {["MP4", "MOV", "AVI", "MKV"].map((fmt) => (
                  <div key={fmt} className="flex items-center gap-2 p-2.5 bg-[#F5F6FA] rounded-xl">
                    <CheckCircle2 size={13} className="text-[#10B981]" />
                    <span className="text-sm font-semibold text-[#1A1A2E]">{fmt}</span>
                  </div>
                ))}
              </div>
              <p className="text-xs text-[#9CA3AF] mt-3">Max file size: <strong>500 MB</strong></p>
            </div>
          </div>
        </div>
      </main>
    </div>
  );
}
