"use client";

import { useState, useEffect, useCallback } from "react";
import { useRouter } from "next/navigation";
import { Header } from "@/components/layout/header";
import { api, Student } from "@/lib/api";
import { auth } from "@/lib/auth";
import { formatDate } from "@/lib/api";
import { Search, Loader2 } from "lucide-react";

export default function StudentsPage() {
  const router = useRouter();
  const [students, setStudents] = useState<Student[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [search, setSearch] = useState("");

  const loadStudents = useCallback(async () => {
    if (!auth.isLoggedIn()) { router.push("/login"); return; }
    try {
      setLoading(true);
      setError("");
      const res = await api.getStudents();
      if (res.success) setStudents(res.students);
      else setError("Failed to load students");
    } catch {
      setError("Network error — is the backend running?");
    } finally {
      setLoading(false);
    }
  }, [router]);

  useEffect(() => { loadStudents(); }, [loadStudents]);

  const filtered = students.filter((s) => {
    const name = s.name ?? "";
    return (
      name.toLowerCase().includes(search.toLowerCase()) ||
      s.phone.includes(search)
    );
  });

  return (
    <div className="flex flex-col min-h-screen">
      <Header title="Students" />
      <main className="flex-1 p-6">
        <div className="flex items-center justify-between mb-6 gap-4">
          <div className="relative flex-1 max-w-sm">
            <Search size={15} className="absolute left-3 top-1/2 -translate-y-1/2 text-[#9CA3AF]" />
            <input
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              placeholder="Search by name or phone..."
              className="pl-9 pr-4 py-2.5 w-full border border-[#E5E7EB] rounded-xl text-sm bg-white focus:outline-none focus:border-[#6C63FF] focus:ring-2 focus:ring-[#6C63FF]/20"
            />
          </div>
          <p className="text-sm text-[#6B7280]">
            {loading ? "Loading..." : `${students.length} students total`}
          </p>
        </div>

        {error && (
          <div className="mb-4 px-4 py-3 bg-[#FEF2F2] border border-[#FECACA] rounded-xl text-sm text-[#EF4444]">
            {error}
          </div>
        )}

        {loading ? (
          <div className="flex items-center justify-center py-24">
            <Loader2 size={28} className="animate-spin text-[#6C63FF]" />
          </div>
        ) : (
          <div className="bg-white rounded-2xl border border-[#E5E7EB] overflow-hidden">
            <table className="w-full">
              <thead className="bg-[#F8F9FC]">
                <tr className="text-left">
                  {["Student", "Phone", "Credits", "Enrolled"].map((h) => (
                    <th key={h} className="px-6 py-4 text-xs font-semibold text-[#9CA3AF] uppercase">{h}</th>
                  ))}
                </tr>
              </thead>
              <tbody className="divide-y divide-[#F3F4F6]">
                {filtered.map((s) => {
                  const initials = s.name
                    ? s.name.split(" ").map((w) => w[0]).join("").slice(0, 2).toUpperCase()
                    : s.phone.slice(-2);
                  return (
                    <tr key={s.id} className="hover:bg-[#F5F6FA] transition-colors">
                      <td className="px-6 py-4">
                        <div className="flex items-center gap-3">
                          <div className="w-9 h-9 rounded-full bg-gradient-to-br from-[#6C63FF] to-[#8B5CF6] flex items-center justify-center flex-shrink-0">
                            <span className="text-white text-xs font-bold">{initials}</span>
                          </div>
                          <span className="text-sm font-semibold text-[#1A1A2E]">{s.name ?? "—"}</span>
                        </div>
                      </td>
                      <td className="px-6 py-4 text-sm text-[#6B7280]">{s.phone}</td>
                      <td className="px-6 py-4 text-sm font-semibold text-[#1A1A2E]">{s.credits_total}</td>
                      <td className="px-6 py-4 text-sm text-[#6B7280]">{formatDate(s.created_at)}</td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
            {filtered.length === 0 && !loading && (
              <div className="py-16 text-center">
                <p className="text-[#9CA3AF] text-sm">
                  {search ? "No students match your search" : "No students yet"}
                </p>
              </div>
            )}
          </div>
        )}
      </main>
    </div>
  );
}
