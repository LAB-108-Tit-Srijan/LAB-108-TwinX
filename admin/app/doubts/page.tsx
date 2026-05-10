"use client";

import { useEffect, useState } from "react";
import { Header } from "@/components/layout/header";
import { StatCard } from "@/components/shared/stat-card";
import { HelpCircle, Globe, BookOpen } from "lucide-react";
import { api, DoubtsAnalytics } from "@/lib/api";

function timeAgo(iso: string): string {
  const diff = Date.now() - new Date(iso).getTime();
  const mins = Math.floor(diff / 60000);
  if (mins < 1) return "just now";
  if (mins < 60) return `${mins}m ago`;
  const hrs = Math.floor(mins / 60);
  if (hrs < 24) return `${hrs}h ago`;
  return `${Math.floor(hrs / 24)}d ago`;
}

export default function DoubtsPage() {
  const [analytics, setAnalytics] = useState<DoubtsAnalytics | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    api.getDoubtsAnalytics()
      .then((res) => {
        if (res.success) setAnalytics(res.analytics);
        else setError("Failed to load analytics");
      })
      .catch(() => setError("Failed to load analytics"))
      .finally(() => setLoading(false));
  }, []);

  const hindiCount = analytics?.recent_doubts.filter((d) => d.language === "hi").length ?? 0;
  const hindiPercent = analytics && analytics.recent_doubts.length > 0
    ? Math.round((hindiCount / analytics.recent_doubts.length) * 100)
    : 0;

  return (
    <div className="flex flex-col min-h-screen">
      <Header title="Doubts Analytics" />
      <main className="flex-1 p-6 space-y-6">
        {error && (
          <div className="bg-red-50 border border-red-200 text-red-700 rounded-xl px-4 py-3 text-sm">
            {error}
          </div>
        )}

        {/* Stats */}
        <div className="grid grid-cols-3 gap-4">
          <StatCard
            title="Total Doubts"
            value={loading ? "…" : String(analytics?.total_doubts ?? "—")}
            icon={HelpCircle}
            iconColor="text-[#6C63FF]"
            iconBg="bg-[#6C63FF]/10"
          />
          <StatCard
            title="Hindi Doubts (recent)"
            value={loading ? "…" : `${hindiPercent}%`}
            icon={Globe}
            iconColor="text-[#10B981]"
            iconBg="bg-[#10B981]/10"
          />
          <StatCard
            title="Top Lectures Tracked"
            value={loading ? "…" : String(analytics?.top_lectures_by_doubts.length ?? "—")}
            icon={BookOpen}
            iconColor="text-[#F59E0B]"
            iconBg="bg-[#F59E0B]/10"
          />
        </div>

        {/* Top Lectures by Doubts */}
        <div className="bg-white rounded-2xl border border-[#E5E7EB] p-6">
          <h3 className="font-semibold text-[#1A1A2E] mb-4">Top Lectures by Doubts</h3>
          {loading ? (
            <p className="text-sm text-[#9CA3AF]">Loading…</p>
          ) : analytics?.top_lectures_by_doubts && analytics.top_lectures_by_doubts.length > 0 ? (
            <div className="space-y-3">
              {analytics.top_lectures_by_doubts.map((l, i) => {
                const maxCount = analytics.top_lectures_by_doubts[0]?.doubts_count ?? 1;
                const pct = Math.round((l.doubts_count / maxCount) * 100);
                return (
                  <div key={i} className="flex items-center gap-4">
                    <div className="w-6 h-6 rounded-full bg-gradient-to-br from-[#6C63FF] to-[#8B5CF6] flex items-center justify-center flex-shrink-0">
                      <span className="text-white text-xs font-bold">{i + 1}</span>
                    </div>
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center justify-between mb-1">
                        <p className="text-sm font-medium text-[#1A1A2E] truncate pr-4">{l.title}</p>
                        <span className="text-sm font-bold text-[#6C63FF] flex-shrink-0">{l.doubts_count}</span>
                      </div>
                      <div className="h-1.5 bg-[#F3F4F6] rounded-full overflow-hidden">
                        <div
                          className="h-full bg-gradient-to-r from-[#6C63FF] to-[#8B5CF6] rounded-full"
                          style={{ width: `${pct}%` }}
                        />
                      </div>
                    </div>
                  </div>
                );
              })}
            </div>
          ) : (
            <p className="text-sm text-[#9CA3AF]">No doubt data yet.</p>
          )}
        </div>

        {/* Recent Doubts table */}
        <div className="bg-white rounded-2xl border border-[#E5E7EB] p-6">
          <h3 className="font-semibold text-[#1A1A2E] mb-4">Recent Doubts</h3>
          {loading ? (
            <p className="text-sm text-[#9CA3AF]">Loading…</p>
          ) : analytics?.recent_doubts && analytics.recent_doubts.length > 0 ? (
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead>
                  <tr className="text-left">
                    {["Question", "Lecture", "Language", "Time"].map((h) => (
                      <th key={h} className="text-xs font-semibold text-[#9CA3AF] uppercase pb-3 pr-4 whitespace-nowrap">{h}</th>
                    ))}
                  </tr>
                </thead>
                <tbody className="divide-y divide-[#F3F4F6]">
                  {analytics.recent_doubts.map((d, i) => (
                    <tr key={i} className="hover:bg-[#F5F6FA] transition-colors">
                      <td className="py-3 pr-4 text-sm text-[#1A1A2E] max-w-[300px] truncate">{d.question}</td>
                      <td className="py-3 pr-4 text-sm text-[#6B7280] whitespace-nowrap max-w-[180px] truncate">
                        {d.lecture_title ?? <span className="text-[#D1D5DB]">—</span>}
                      </td>
                      <td className="py-3 pr-4">
                        <span className={`inline-block px-2 py-0.5 rounded-md text-xs font-semibold ${
                          d.language === "hi"
                            ? "bg-[#10B981]/10 text-[#10B981]"
                            : "bg-[#6C63FF]/10 text-[#6C63FF]"
                        }`}>
                          {d.language === "hi" ? "Hindi" : "English"}
                        </span>
                      </td>
                      <td className="py-3 text-xs text-[#9CA3AF] whitespace-nowrap">{timeAgo(d.created_at)}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          ) : (
            <p className="text-sm text-[#9CA3AF]">No doubts logged yet.</p>
          )}
        </div>
      </main>
    </div>
  );
}
