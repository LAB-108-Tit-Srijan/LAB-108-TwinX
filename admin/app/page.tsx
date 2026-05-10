"use client";

import { useEffect, useState } from "react";
import { Header } from "@/components/layout/header";
import { StatCard } from "@/components/shared/stat-card";
import {
  Users,
  BookOpen,
  Video,
  TrendingUp,
  HelpCircle,
  CheckCircle,
} from "lucide-react";
import { api, AdminStats, DoubtsAnalytics, formatDate } from "@/lib/api";

export default function DashboardPage() {
  const [stats, setStats] = useState<AdminStats | null>(null);
  const [doubts, setDoubts] = useState<DoubtsAnalytics | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    Promise.all([api.getAdminStats(), api.getDoubtsAnalytics()])
      .then(([statsRes, doubtsRes]) => {
        if (statsRes.success) setStats(statsRes.stats);
        if (doubtsRes.success) setDoubts(doubtsRes.analytics);
      })
      .catch(() => setError("Failed to load dashboard data"))
      .finally(() => setLoading(false));
  }, []);

  return (
    <div className="flex flex-col min-h-screen">
      <Header title="Dashboard" />
      <main className="flex-1 p-6 space-y-6">
        {/* Welcome banner */}
        <div className="bg-gradient-to-r from-[#6C63FF] to-[#8B5CF6] rounded-2xl p-6 text-white">
          <h2 className="text-2xl font-bold">Welcome, Admin</h2>
          <p className="text-white/70 mt-1 text-sm">
            Here&apos;s a live overview of your AIVA platform.
          </p>
          {!loading && stats && (
            <div className="flex items-center gap-2 mt-4">
              <div className="bg-white/20 rounded-lg px-3 py-1.5 text-sm font-medium">
                {stats.total_students} students enrolled
              </div>
              <div className="bg-white/20 rounded-lg px-3 py-1.5 text-sm font-medium">
                {stats.published_courses} courses published
              </div>
            </div>
          )}
        </div>

        {error && (
          <div className="bg-red-50 border border-red-200 text-red-700 rounded-xl px-4 py-3 text-sm">
            {error}
          </div>
        )}

        {/* Stats row */}
        <div className="grid grid-cols-3 gap-4 lg:grid-cols-6">
          <StatCard
            title="Total Students"
            value={loading ? "…" : String(stats?.total_students ?? "—")}
            icon={Users}
            iconColor="text-[#6C63FF]"
            iconBg="bg-[#6C63FF]/10"
          />
          <StatCard
            title="Total Courses"
            value={loading ? "…" : String(stats?.total_courses ?? "—")}
            icon={BookOpen}
            iconColor="text-[#10B981]"
            iconBg="bg-[#10B981]/10"
          />
          <StatCard
            title="Published Courses"
            value={loading ? "…" : String(stats?.published_courses ?? "—")}
            icon={TrendingUp}
            iconColor="text-[#00D4FF]"
            iconBg="bg-[#00D4FF]/10"
          />
          <StatCard
            title="Total Lectures"
            value={loading ? "…" : String(stats?.total_lectures ?? "—")}
            icon={Video}
            iconColor="text-[#F59E0B]"
            iconBg="bg-[#F59E0B]/10"
          />
          <StatCard
            title="Total Enrollments"
            value={loading ? "…" : String(stats?.total_enrollments ?? "—")}
            icon={Users}
            iconColor="text-[#8B5CF6]"
            iconBg="bg-[#8B5CF6]/10"
          />
          <StatCard
            title="Total Doubts Asked"
            value={loading ? "…" : String(doubts?.total_doubts ?? "—")}
            icon={HelpCircle}
            iconColor="text-[#EF4444]"
            iconBg="bg-[#EF4444]/10"
          />
        </div>

        {/* Second stats row */}
        <div className="grid grid-cols-2 gap-4">
          <div className="bg-white rounded-2xl border border-[#E5E7EB] p-5 flex items-center gap-4">
            <div className="w-12 h-12 rounded-xl bg-[#10B981]/10 flex items-center justify-center flex-shrink-0">
              <CheckCircle size={22} className="text-[#10B981]" />
            </div>
            <div>
              <p className="text-xs font-semibold text-[#9CA3AF] uppercase tracking-wide">Completed Lectures</p>
              <p className="text-2xl font-bold text-[#1A1A2E] mt-0.5">
                {loading ? "…" : (stats?.completed_lectures ?? "—")}
              </p>
              <p className="text-xs text-[#9CA3AF] mt-0.5">Total watch completions across all students</p>
            </div>
          </div>
          <div className="bg-white rounded-2xl border border-[#E5E7EB] p-5 flex items-center gap-4">
            <div className="w-12 h-12 rounded-xl bg-[#F59E0B]/10 flex items-center justify-center flex-shrink-0">
              <Video size={22} className="text-[#F59E0B]" />
            </div>
            <div>
              <p className="text-xs font-semibold text-[#9CA3AF] uppercase tracking-wide">Ready Lectures</p>
              <p className="text-2xl font-bold text-[#1A1A2E] mt-0.5">
                {loading ? "…" : (stats?.ready_lectures ?? "—")}
              </p>
              <p className="text-xs text-[#9CA3AF] mt-0.5">Lectures fully processed and available to students</p>
            </div>
          </div>
        </div>

        {/* Bottom row */}
        <div className="grid grid-cols-3 gap-6">
          {/* Recent Enrollments */}
          <div className="col-span-2 bg-white rounded-2xl border border-[#E5E7EB] p-6">
            <h3 className="font-semibold text-[#1A1A2E] mb-4">Recent Enrollments</h3>
            {loading ? (
              <p className="text-sm text-[#9CA3AF]">Loading…</p>
            ) : stats?.recent_enrollments && stats.recent_enrollments.length > 0 ? (
              <table className="w-full">
                <thead>
                  <tr className="text-left">
                    {["Student", "Phone", "Course", "Enrolled At"].map((h) => (
                      <th key={h} className="text-xs font-semibold text-[#9CA3AF] uppercase pb-3 pr-4">{h}</th>
                    ))}
                  </tr>
                </thead>
                <tbody className="divide-y divide-[#F3F4F6]">
                  {stats.recent_enrollments.map((e, i) => (
                    <tr key={i} className="hover:bg-[#F5F6FA] transition-colors">
                      <td className="py-3 pr-4">
                        <div className="flex items-center gap-2">
                          <div className="w-7 h-7 rounded-full bg-gradient-to-br from-[#6C63FF] to-[#8B5CF6] flex items-center justify-center flex-shrink-0">
                            <span className="text-white text-[10px] font-bold">
                              {e.student_name ? e.student_name[0].toUpperCase() : "?"}
                            </span>
                          </div>
                          <span className="text-sm font-medium text-[#1A1A2E] whitespace-nowrap">
                            {e.student_name ?? "—"}
                          </span>
                        </div>
                      </td>
                      <td className="py-3 pr-4 text-sm text-[#6B7280] whitespace-nowrap">{e.phone}</td>
                      <td className="py-3 pr-4 text-sm text-[#1A1A2E] max-w-[200px] truncate">{e.course_title}</td>
                      <td className="py-3 text-xs text-[#9CA3AF] whitespace-nowrap">{formatDate(e.enrolled_at)}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            ) : (
              <p className="text-sm text-[#9CA3AF]">No enrollments yet.</p>
            )}
          </div>

          {/* Top lectures by doubts */}
          <div className="bg-white rounded-2xl border border-[#E5E7EB] p-6">
            <div className="flex items-center gap-2 mb-4">
              <h3 className="font-semibold text-[#1A1A2E]">Top Lectures by Doubts</h3>
            </div>
            {loading ? (
              <p className="text-sm text-[#9CA3AF]">Loading…</p>
            ) : doubts?.top_lectures_by_doubts && doubts.top_lectures_by_doubts.length > 0 ? (
              <div className="space-y-3">
                {doubts.top_lectures_by_doubts.map((l, i) => (
                  <div key={i} className="flex items-center gap-3">
                    <div className="w-6 h-6 rounded-full bg-[#6C63FF]/10 flex items-center justify-center flex-shrink-0">
                      <span className="text-[#6C63FF] text-xs font-bold">{i + 1}</span>
                    </div>
                    <div className="flex-1 min-w-0">
                      <p className="text-sm font-medium text-[#1A1A2E] truncate">{l.title}</p>
                    </div>
                    <span className="flex-shrink-0 text-sm font-bold text-[#6C63FF]">{l.doubts_count}</span>
                  </div>
                ))}
              </div>
            ) : (
              <p className="text-sm text-[#9CA3AF]">No doubt data yet.</p>
            )}
          </div>
        </div>
      </main>
    </div>
  );
}
