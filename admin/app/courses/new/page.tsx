"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { Header } from "@/components/layout/header";
import { api } from "@/lib/api";
import { auth } from "@/lib/auth";
import { ArrowLeft, Loader2 } from "lucide-react";

const CATEGORIES = ["React", "Node.js", "DSA", "Python", "System Design", "Database", "JavaScript", "TypeScript", "Frontend", "Backend"];
const LEVELS = ["Beginner", "Intermediate", "Advanced"];

export default function NewCoursePage() {
  const router = useRouter();
  const [form, setForm] = useState({
    title: "",
    description: "",
    instructor: "",
    category: "React",
    level: "Beginner",
    estimated_hours: "",
    expected_videos: "",
  });
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  function set(key: string, value: string) {
    setForm((f) => ({ ...f, [key]: value }));
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!auth.isLoggedIn()) { router.push("/login"); return; }
    if (!form.title.trim()) { setError("Course title is required"); return; }

    setLoading(true);
    setError("");
    try {
      const res = await api.createCourse({
        title: form.title,
        description: form.description || undefined,
        instructor: form.instructor || undefined,
        category: form.category,
        level: form.level,
        estimated_hours: form.estimated_hours ? parseInt(form.estimated_hours) : 0,
        expected_videos: form.expected_videos ? parseInt(form.expected_videos) : undefined,
      });
      if (res.success) {
        router.push(`/courses/${res.course.id}/lectures`);
      } else {
        setError("Failed to create course");
      }
    } catch {
      setError("Network error");
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="flex flex-col min-h-screen">
      <Header title="New Course" />
      <main className="flex-1 p-6 max-w-2xl">
        <button
          onClick={() => router.push("/courses")}
          className="flex items-center gap-2 text-sm text-[#6B7280] hover:text-[#1A1A2E] mb-6 transition-colors"
        >
          <ArrowLeft size={16} /> Back to Courses
        </button>

        <div className="bg-white rounded-2xl border border-[#E5E7EB] p-6">
          <h2 className="text-xl font-bold text-[#1A1A2E] mb-6">Create New Course</h2>

          {error && (
            <div className="mb-4 px-4 py-3 bg-[#FEF2F2] border border-[#FECACA] rounded-xl text-sm text-[#EF4444]">
              {error}
            </div>
          )}

          <form onSubmit={handleSubmit} className="space-y-5">
            <div>
              <label className="text-sm font-medium text-[#1A1A2E] block mb-1.5">
                Course Title <span className="text-[#EF4444]">*</span>
              </label>
              <input
                value={form.title}
                onChange={(e) => set("title", e.target.value)}
                placeholder="e.g. Complete React.js Course"
                className="w-full px-4 py-3 border border-[#E5E7EB] rounded-xl text-sm focus:outline-none focus:border-[#6C63FF] focus:ring-2 focus:ring-[#6C63FF]/20"
              />
            </div>

            <div>
              <label className="text-sm font-medium text-[#1A1A2E] block mb-1.5">Description</label>
              <textarea
                value={form.description}
                onChange={(e) => set("description", e.target.value)}
                rows={3}
                placeholder="What will students learn in this course?"
                className="w-full px-4 py-3 border border-[#E5E7EB] rounded-xl text-sm focus:outline-none focus:border-[#6C63FF] focus:ring-2 focus:ring-[#6C63FF]/20 resize-none"
              />
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="text-sm font-medium text-[#1A1A2E] block mb-1.5">Instructor Name</label>
                <input
                  value={form.instructor}
                  onChange={(e) => set("instructor", e.target.value)}
                  placeholder="Instructor name"
                  className="w-full px-4 py-3 border border-[#E5E7EB] rounded-xl text-sm focus:outline-none focus:border-[#6C63FF] focus:ring-2 focus:ring-[#6C63FF]/20"
                />
              </div>
              <div>
                <label className="text-sm font-medium text-[#1A1A2E] block mb-1.5">Estimated Hours</label>
                <input
                  type="number"
                  value={form.estimated_hours}
                  onChange={(e) => set("estimated_hours", e.target.value)}
                  placeholder="e.g. 20"
                  min="0"
                  className="w-full px-4 py-3 border border-[#E5E7EB] rounded-xl text-sm focus:outline-none focus:border-[#6C63FF] focus:ring-2 focus:ring-[#6C63FF]/20"
                />
              </div>
            </div>

            <div>
              <label className="text-sm font-medium text-[#1A1A2E] block mb-1.5">Expected Videos</label>
              <input
                type="number"
                value={form.expected_videos}
                onChange={(e) => set("expected_videos", e.target.value)}
                placeholder="e.g. 20"
                min="1"
                className="w-full px-4 py-3 border border-[#E5E7EB] rounded-xl text-sm focus:outline-none focus:border-[#6C63FF] focus:ring-2 focus:ring-[#6C63FF]/20"
              />
              <p className="text-xs text-[#9CA3AF] mt-1.5">Estimated total number of video lectures in this course</p>
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="text-sm font-medium text-[#1A1A2E] block mb-1.5">Category</label>
                <select
                  value={form.category}
                  onChange={(e) => set("category", e.target.value)}
                  className="w-full px-4 py-3 border border-[#E5E7EB] rounded-xl text-sm focus:outline-none focus:border-[#6C63FF] bg-white"
                >
                  {CATEGORIES.map((c) => <option key={c}>{c}</option>)}
                </select>
              </div>
              <div>
                <label className="text-sm font-medium text-[#1A1A2E] block mb-1.5">Level</label>
                <select
                  value={form.level}
                  onChange={(e) => set("level", e.target.value)}
                  className="w-full px-4 py-3 border border-[#E5E7EB] rounded-xl text-sm focus:outline-none focus:border-[#6C63FF] bg-white"
                >
                  {LEVELS.map((l) => <option key={l}>{l}</option>)}
                </select>
              </div>
            </div>

            <div className="flex gap-3 pt-2">
              <button
                type="button"
                onClick={() => router.push("/courses")}
                className="flex-1 py-3 border border-[#E5E7EB] rounded-xl text-sm font-semibold text-[#6B7280] hover:bg-[#F5F6FA] transition-colors"
              >
                Cancel
              </button>
              <button
                type="submit"
                disabled={loading}
                className="flex-1 flex items-center justify-center gap-2 py-3 bg-gradient-to-r from-[#6C63FF] to-[#8B5CF6] text-white text-sm font-semibold rounded-xl hover:opacity-90 transition-opacity disabled:opacity-60"
              >
                {loading ? <Loader2 size={16} className="animate-spin" /> : null}
                Create & Add Lectures
              </button>
            </div>
          </form>
        </div>
      </main>
    </div>
  );
}
