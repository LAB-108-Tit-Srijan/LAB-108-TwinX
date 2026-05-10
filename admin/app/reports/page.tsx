"use client";

import { useEffect, useState } from "react";
import { Header } from "@/components/layout/header";
import { FileText, Download, Calendar, Mail, BarChart3 } from "lucide-react";
import { api, AdminStats } from "@/lib/api";

const reportTypes = [
  { id: "weekly", label: "Weekly Summary", desc: "Overview of all activity in the past week", icon: BarChart3, color: "text-[#6C63FF]", bg: "bg-[#6C63FF]/10" },
  { id: "progress", label: "Student Progress", desc: "Individual student progress and completion rates", icon: FileText, color: "text-[#10B981]", bg: "bg-[#10B981]/10" },
  { id: "doubts", label: "Doubt Analytics", desc: "Detailed breakdown of all doubts asked", icon: FileText, color: "text-[#F59E0B]", bg: "bg-[#F59E0B]/10" },
  { id: "course", label: "Course Performance", desc: "Engagement and completion per course", icon: BarChart3, color: "text-[#00D4FF]", bg: "bg-[#00D4FF]/10" },
];

export default function ReportsPage() {
  const [selected, setSelected] = useState("weekly");
  const [scheduled, setScheduled] = useState(false);
  const [stats, setStats] = useState<AdminStats | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    api.getAdminStats()
      .then((res) => { if (res.success) setStats(res.stats); })
      .catch(() => {})
      .finally(() => setLoading(false));
  }, []);

  const today = new Date();
  const weekAgo = new Date(today.getTime() - 7 * 24 * 60 * 60 * 1000);
  const fmt = (d: Date) => d.toISOString().split("T")[0];

  const previewItems = [
    { label: "Total Students", value: loading ? "…" : String(stats?.total_students ?? "—") },
    { label: "Total Enrollments", value: loading ? "…" : String(stats?.total_enrollments ?? "—") },
    { label: "Published Courses", value: loading ? "…" : String(stats?.published_courses ?? "—") },
    { label: "Ready Lectures", value: loading ? "…" : String(stats?.ready_lectures ?? "—") },
    { label: "Completed Lectures", value: loading ? "…" : String(stats?.completed_lectures ?? "—") },
    { label: "Total Lectures", value: loading ? "…" : String(stats?.total_lectures ?? "—") },
  ];

  return (
    <div className="flex flex-col min-h-screen">
      <Header title="Reports" />
      <main className="flex-1 p-6 space-y-6">
        <div className="grid grid-cols-2 gap-6">
          {/* Left: Report builder */}
          <div className="space-y-6">
            <div className="bg-white rounded-2xl border border-[#E5E7EB] p-6">
              <h3 className="font-semibold text-[#1A1A2E] mb-4">Report Type</h3>
              <div className="space-y-3">
                {reportTypes.map((r) => (
                  <button
                    key={r.id}
                    onClick={() => setSelected(r.id)}
                    className={`w-full flex items-center gap-3 p-4 rounded-xl border text-left transition-all ${selected === r.id ? "border-[#6C63FF] bg-[#6C63FF]/5" : "border-[#E5E7EB] hover:bg-[#F5F6FA]"}`}
                  >
                    <div className={`w-10 h-10 rounded-xl ${r.bg} flex items-center justify-center flex-shrink-0`}>
                      <r.icon size={18} className={r.color} />
                    </div>
                    <div>
                      <p className="text-sm font-semibold text-[#1A1A2E]">{r.label}</p>
                      <p className="text-xs text-[#9CA3AF] mt-0.5">{r.desc}</p>
                    </div>
                    {selected === r.id && (
                      <div className="ml-auto w-5 h-5 rounded-full bg-[#6C63FF] flex items-center justify-center flex-shrink-0">
                        <span className="text-white text-xs">✓</span>
                      </div>
                    )}
                  </button>
                ))}
              </div>
            </div>

            <div className="bg-white rounded-2xl border border-[#E5E7EB] p-6">
              <h3 className="font-semibold text-[#1A1A2E] mb-4">Date Range</h3>
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="text-xs text-[#9CA3AF] block mb-1.5">From</label>
                  <div className="flex items-center gap-2 px-3 py-2.5 border border-[#E5E7EB] rounded-xl">
                    <Calendar size={14} className="text-[#9CA3AF]" />
                    <input type="date" defaultValue={fmt(weekAgo)} className="text-sm text-[#1A1A2E] focus:outline-none flex-1 bg-transparent" />
                  </div>
                </div>
                <div>
                  <label className="text-xs text-[#9CA3AF] block mb-1.5">To</label>
                  <div className="flex items-center gap-2 px-3 py-2.5 border border-[#E5E7EB] rounded-xl">
                    <Calendar size={14} className="text-[#9CA3AF]" />
                    <input type="date" defaultValue={fmt(today)} className="text-sm text-[#1A1A2E] focus:outline-none flex-1 bg-transparent" />
                  </div>
                </div>
              </div>
            </div>

            <div className="bg-white rounded-2xl border border-[#E5E7EB] p-6">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm font-semibold text-[#1A1A2E]">Scheduled Reports</p>
                  <p className="text-xs text-[#9CA3AF] mt-0.5">Send weekly report every Monday at 9AM</p>
                </div>
                <button
                  onClick={() => setScheduled(!scheduled)}
                  className={`w-12 h-6 rounded-full relative transition-colors ${scheduled ? "bg-[#6C63FF]" : "bg-[#E5E7EB]"}`}
                >
                  <div className={`w-5 h-5 bg-white rounded-full absolute top-0.5 transition-all shadow-sm ${scheduled ? "right-0.5" : "left-0.5"}`} />
                </button>
              </div>
            </div>
          </div>

          {/* Right: Preview with real data */}
          <div className="bg-white rounded-2xl border border-[#E5E7EB] p-6">
            <div className="flex items-center justify-between mb-6">
              <h3 className="font-semibold text-[#1A1A2E]">Report Preview</h3>
              <div className="flex gap-2">
                <button className="flex items-center gap-1.5 px-4 py-2 border border-[#E5E7EB] text-sm font-medium text-[#6B7280] rounded-xl hover:bg-[#F5F6FA] transition-colors">
                  <Mail size={14} />
                  Email
                </button>
                <button className="flex items-center gap-1.5 px-4 py-2 bg-gradient-to-r from-[#6C63FF] to-[#8B5CF6] text-white text-sm font-semibold rounded-xl hover:opacity-90 transition-opacity">
                  <Download size={14} />
                  Export PDF
                </button>
              </div>
            </div>

            <div className="border border-[#E5E7EB] rounded-xl p-5 space-y-4 bg-[#F8F9FC]">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-[#6C63FF] to-[#8B5CF6] flex items-center justify-center">
                  <span className="text-white font-bold text-sm">AI</span>
                </div>
                <div>
                  <p className="font-bold text-[#1A1A2E]">AIVA Platform Summary</p>
                  <p className="text-xs text-[#9CA3AF]">Live data snapshot</p>
                </div>
              </div>
              <div className="h-px bg-[#E5E7EB]" />
              {previewItems.map((item) => (
                <div key={item.label} className="flex items-center justify-between py-1">
                  <span className="text-sm text-[#6B7280]">{item.label}</span>
                  <span className="text-sm font-bold text-[#1A1A2E]">{item.value}</span>
                </div>
              ))}
              <div className="h-px bg-[#E5E7EB]" />
              <p className="text-xs text-[#9CA3AF] text-center">Generated by AIVA Admin · aiva.in</p>
            </div>
          </div>
        </div>
      </main>
    </div>
  );
}
