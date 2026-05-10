"use client";

import { useState, useEffect, useCallback } from "react";
import { useRouter } from "next/navigation";
import { Header } from "@/components/layout/header";
import { Badge } from "@/components/shared/badge";
import { api, Course } from "@/lib/api";
import { auth } from "@/lib/auth";
import { Plus, Video, Users, Eye, Edit, BookOpen } from "lucide-react";

const gradients = [
  "from-[#6C63FF] to-[#8B5CF6]",
  "from-[#00D4FF] to-[#6C63FF]",
  "from-[#8B5CF6] to-[#EC4899]",
  "from-[#F59E0B] to-[#EF4444]",
  "from-[#10B981] to-[#00D4FF]",
  "from-[#EC4899] to-[#8B5CF6]",
];

export default function CoursesPage() {
  const router = useRouter();
  const [courses, setCourses] = useState<Course[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  const loadCourses = useCallback(async () => {
    if (!auth.isLoggedIn()) { router.push("/login"); return; }
    try {
      setLoading(true);
      const res = await api.getCourses();
      if (res.success) setCourses(res.courses);
      else setError("Failed to load courses");
    } catch {
      setError("Network error");
    } finally {
      setLoading(false);
    }
  }, [router]);

  useEffect(() => { loadCourses(); }, [loadCourses]);

  async function handlePublish(id: string) {
    if (!confirm("Publish this course? Students will be able to enroll.")) return;
    await api.publishCourse(id);
    loadCourses();
  }

  return (
    <div className="flex flex-col min-h-screen">
      <Header title="Courses" />
      <main className="flex-1 p-6">
        <div className="flex items-center justify-between mb-6">
          <p className="text-sm text-[#6B7280]">
            {loading ? "Loading..." : `${courses.length} courses total`}
          </p>
          <button
            onClick={() => router.push("/courses/new")}
            className="flex items-center gap-2 px-4 py-2.5 bg-gradient-to-r from-[#6C63FF] to-[#8B5CF6] text-white text-sm font-semibold rounded-xl hover:opacity-90 transition-opacity shadow-sm shadow-[#6C63FF]/30"
          >
            <Plus size={16} />
            New Course
          </button>
        </div>

        {error && (
          <div className="mb-4 px-4 py-3 bg-[#FEF2F2] border border-[#FECACA] rounded-xl text-sm text-[#EF4444]">
            {error}
          </div>
        )}

        {loading ? (
          <div className="grid grid-cols-3 gap-6">
            {[1, 2, 3].map((i) => (
              <div key={i} className="bg-white rounded-2xl border border-[#E5E7EB] overflow-hidden animate-pulse">
                <div className="h-32 bg-[#F5F6FA]" />
                <div className="p-5 space-y-3">
                  <div className="h-4 bg-[#F5F6FA] rounded w-3/4" />
                  <div className="h-3 bg-[#F5F6FA] rounded w-1/2" />
                </div>
              </div>
            ))}
          </div>
        ) : (
          <div className="grid grid-cols-3 gap-6">
            {courses.map((course, i) => (
              <div
                key={course.id}
                className="bg-white rounded-2xl border border-[#E5E7EB] overflow-hidden hover:shadow-md transition-shadow"
              >
                <div
                  className={`h-32 bg-gradient-to-br ${gradients[i % gradients.length]} flex items-center justify-center relative`}
                >
                  <span className="text-white text-4xl font-black opacity-20">
                    {course.title[0]}
                  </span>
                  <div className="absolute top-3 right-3">
                    <Badge
                      label={course.is_published ? "Published" : "Draft"}
                      variant={course.is_published ? "success" : "warning"}
                    />
                  </div>
                  {course.level && (
                    <div className="absolute bottom-3 left-3">
                      <span className="text-xs font-semibold text-white bg-black/30 px-2 py-0.5 rounded-full">
                        {course.level}
                      </span>
                    </div>
                  )}
                </div>
                <div className="p-5">
                  <div className="flex items-start justify-between mb-1">
                    <h3 className="font-bold text-[#1A1A2E] leading-snug">{course.title}</h3>
                  </div>
                  <p className="text-sm text-[#6B7280]">{course.instructor ?? "—"}</p>
                  {course.category && (
                    <span className="inline-block mt-1.5 text-xs font-medium text-[#6C63FF] bg-[#6C63FF]/10 px-2 py-0.5 rounded-full">
                      {course.category}
                    </span>
                  )}
                  <div className="flex items-center gap-4 mt-4 text-sm text-[#6B7280]">
                    <div className="flex items-center gap-1.5">
                      <Video size={14} className="text-[#6C63FF]" />
                      <span>{course.actual_lectures ?? course.total_lectures} lectures</span>
                    </div>
                    <div className="flex items-center gap-1.5">
                      <Users size={14} className="text-[#10B981]" />
                      <span>{course.estimated_hours}h</span>
                    </div>
                  </div>
                  <div className="flex items-center gap-2 mt-4 pt-4 border-t border-[#F3F4F6]">
                    <button
                      onClick={() => router.push(`/courses/${course.id}/lectures`)}
                      className="flex-1 flex items-center justify-center gap-1.5 py-2 text-xs font-semibold text-[#6C63FF] bg-[#6C63FF]/8 rounded-lg hover:bg-[#6C63FF]/15 transition-colors"
                    >
                      <BookOpen size={13} />
                      Lectures
                    </button>
                    <button
                      onClick={() => router.push(`/courses/${course.id}/lectures`)}
                      className="flex-1 flex items-center justify-center gap-1.5 py-2 text-xs font-semibold text-[#6B7280] bg-[#F5F6FA] rounded-lg hover:bg-[#E5E7EB] transition-colors"
                    >
                      <Eye size={13} />
                      View
                    </button>
                    {!course.is_published && (
                      <button
                        onClick={() => handlePublish(course.id)}
                        className="flex-1 flex items-center justify-center gap-1.5 py-2 text-xs font-semibold text-[#10B981] bg-[#10B981]/8 rounded-lg hover:bg-[#10B981]/15 transition-colors"
                      >
                        <Edit size={13} />
                        Publish
                      </button>
                    )}
                  </div>
                </div>
              </div>
            ))}

            {courses.length === 0 && !loading && (
              <div className="col-span-3 text-center py-16">
                <BookOpen size={40} className="text-[#E5E7EB] mx-auto mb-3" />
                <p className="text-[#6B7280] font-medium">No courses yet</p>
                <p className="text-sm text-[#9CA3AF] mt-1">Create your first course to get started</p>
              </div>
            )}
          </div>
        )}
      </main>
    </div>
  );
}
