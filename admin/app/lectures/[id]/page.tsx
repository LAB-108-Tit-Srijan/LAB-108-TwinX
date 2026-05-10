"use client";

import { useState, useEffect, useRef } from "react";
import { useParams, useRouter } from "next/navigation";
import Link from "next/link";
import { Header } from "@/components/layout/header";
import { api, Lecture, Chunk, formatDuration, formatDate } from "@/lib/api";
import {
  ArrowLeft,
  BookOpen,
  Clock,
  Layers,
  Search,
  ChevronDown,
  ChevronUp,
  Send,
  Loader2,
  AlertCircle,
  User,
  Calendar,
} from "lucide-react";

// ─── Status badge ────────────────────────────────────────────────
function StatusBadge({ status }: { status: Lecture["status"] }) {
  const map: Record<Lecture["status"], { label: string; cls: string }> = {
    uploading:    { label: "Uploading",     cls: "bg-gray-100 text-gray-600" },
    transcribing: { label: "Transcribing",  cls: "bg-yellow-100 text-yellow-700" },
    processing:   { label: "Processing",    cls: "bg-blue-100 text-blue-700" },
    ready:        { label: "Ready",         cls: "bg-green-100 text-green-700" },
    failed:       { label: "Failed",        cls: "bg-red-100 text-red-700" },
  };
  const { label, cls } = map[status] ?? map.failed;
  return (
    <span className={`px-2.5 py-0.5 rounded-lg text-xs font-semibold ${cls}`}>{label}</span>
  );
}

// ─── Chunk card ──────────────────────────────────────────────────
function ChunkCard({ chunk }: { chunk: Chunk }) {
  const [expanded, setExpanded] = useState(false);
  const preview = chunk.text.slice(0, 150);
  const hasMore = chunk.text.length > 150;

  const topicColors: Record<string, string> = {
    "React Hooks":      "bg-blue-100 text-blue-700",
    "React Components": "bg-cyan-100 text-cyan-700",
    "Async Programming":"bg-purple-100 text-purple-700",
    "Algorithms":       "bg-orange-100 text-orange-700",
    "Databases":        "bg-yellow-100 text-yellow-700",
    "Functions":        "bg-indigo-100 text-indigo-700",
    "Arrays & Loops":   "bg-pink-100 text-pink-700",
    General:            "bg-gray-100 text-gray-600",
  };

  return (
    <div className="bg-[#F8F9FC] border border-[#E5E7EB] rounded-xl p-4 hover:border-[#6C63FF]/30 transition-colors">
      <div className="flex items-center justify-between mb-2">
        <div className="flex items-center gap-2 flex-wrap">
          <span className="text-xs font-bold text-[#9CA3AF]">#{chunk.chunk_index}</span>
          <span className="px-2 py-0.5 bg-green-100 text-green-700 text-xs font-semibold rounded-full">
            ⏱ {chunk.timestamp_label}
          </span>
          <span className={`px-2 py-0.5 text-xs font-semibold rounded-full ${topicColors[chunk.topic] ?? topicColors.General}`}>
            {chunk.topic}
          </span>
        </div>
        <span className="text-xs text-[#9CA3AF]">{chunk.word_count}w</span>
      </div>
      <p className="text-sm text-[#1A1A2E] leading-relaxed">
        {expanded ? chunk.text : (hasMore ? `${preview}...` : chunk.text)}
      </p>
      {hasMore && (
        <button
          onClick={() => setExpanded(!expanded)}
          className="mt-2 flex items-center gap-1 text-xs text-[#6C63FF] font-medium hover:underline"
        >
          {expanded ? <><ChevronUp size={12} /> Show less</> : <><ChevronDown size={12} /> Show more</>}
        </button>
      )}
    </div>
  );
}

// ─── Stat card ───────────────────────────────────────────────────
function StatCard({ icon: Icon, label, value, color }: { icon: React.ElementType; label: string; value: string | number; color: string }) {
  return (
    <div className="bg-white rounded-2xl border border-[#E5E7EB] p-5">
      <div className="flex items-center gap-3">
        <div className={`w-10 h-10 rounded-xl flex items-center justify-center ${color}`}>
          <Icon size={18} className="text-white" />
        </div>
        <div>
          <p className="text-xs text-[#9CA3AF]">{label}</p>
          <p className="text-lg font-bold text-[#1A1A2E]">{value}</p>
        </div>
      </div>
    </div>
  );
}

// ─── Test AIVA component ─────────────────────────────────────────
function TestAIVA({ lectureId }: { lectureId: string }) {
  const [question, setQuestion] = useState("");
  const [answer, setAnswer] = useState("");
  const [asking, setAsking] = useState(false);
  const [language, setLanguage] = useState<"en" | "hi">("en");

  const handleAsk = async () => {
    if (!question.trim() || asking) return;
    setAsking(true);
    setAnswer("");
    try {
      await api.askQuestion(
        lectureId,
        question,
        language,
        (text) => setAnswer((prev) => prev + text),
        () => setAsking(false)
      );
    } catch {
      setAnswer("Failed to get a response. Please try again.");
      setAsking(false);
    }
  };

  return (
    <div className="bg-white rounded-2xl border border-[#E5E7EB] p-5">
      <div className="flex items-center justify-between mb-4">
        <h4 className="text-sm font-bold text-[#1A1A2E]">Test AIVA</h4>
        <select
          value={language}
          onChange={(e) => setLanguage(e.target.value as "en" | "hi")}
          className="px-3 py-1.5 border border-[#E5E7EB] rounded-xl text-xs bg-white focus:outline-none focus:border-[#6C63FF]"
        >
          <option value="en">English</option>
          <option value="hi">Hindi</option>
        </select>
      </div>
      <div className="flex gap-2 mb-3">
        <input
          value={question}
          onChange={(e) => setQuestion(e.target.value)}
          onKeyDown={(e) => e.key === "Enter" && handleAsk()}
          placeholder="Ask a question about this lecture..."
          disabled={asking}
          className="flex-1 px-4 py-3 border border-[#E5E7EB] rounded-xl text-sm focus:outline-none focus:border-[#6C63FF] focus:ring-2 focus:ring-[#6C63FF]/20 disabled:bg-[#F5F6FA] transition-all"
        />
        <button
          onClick={handleAsk}
          disabled={!question.trim() || asking}
          className="px-4 py-3 bg-gradient-to-r from-[#6C63FF] to-[#8B5CF6] text-white rounded-xl hover:opacity-90 transition-opacity disabled:opacity-50 disabled:cursor-not-allowed flex items-center gap-2"
        >
          {asking ? <Loader2 size={15} className="animate-spin" /> : <Send size={15} />}
        </button>
      </div>
      {answer && (
        <div className="p-4 bg-[#F8F9FC] rounded-xl border border-[#E5E7EB]">
          <div className="flex items-center gap-2 mb-2">
            <div className="w-5 h-5 rounded-full bg-gradient-to-br from-[#6C63FF] to-[#8B5CF6] flex items-center justify-center">
              <span className="text-white text-[8px] font-bold">AI</span>
            </div>
            <p className="text-xs font-semibold text-[#6C63FF]">AIVA</p>
            {asking && <Loader2 size={11} className="animate-spin text-[#6C63FF]" />}
          </div>
          <p className="text-sm text-[#1A1A2E] leading-relaxed whitespace-pre-wrap">{answer}</p>
        </div>
      )}
    </div>
  );
}

// ─── Analytics tab ────────────────────────────────────────────────
function AnalyticsTab({ chunks }: { chunks: Chunk[] }) {
  const topicCounts = chunks.reduce<Record<string, number>>((acc, c) => {
    acc[c.topic] = (acc[c.topic] ?? 0) + 1;
    return acc;
  }, {});
  const topics = Object.entries(topicCounts).sort((a, b) => b[1] - a[1]);
  const maxCount = topics[0]?.[1] ?? 1;

  const topByWords = [...chunks].sort((a, b) => b.word_count - a.word_count).slice(0, 5);

  return (
    <div className="space-y-5">
      {/* Topics breakdown */}
      <div className="bg-white rounded-2xl border border-[#E5E7EB] p-5">
        <h4 className="text-sm font-bold text-[#1A1A2E] mb-4">Topics Breakdown</h4>
        <div className="space-y-3">
          {topics.map(([topic, count]) => (
            <div key={topic}>
              <div className="flex justify-between text-xs mb-1">
                <span className="font-medium text-[#1A1A2E]">{topic}</span>
                <span className="text-[#6B7280]">{count} chunks</span>
              </div>
              <div className="h-2 bg-[#F3F4F6] rounded-full overflow-hidden">
                <div
                  className="h-full bg-gradient-to-r from-[#6C63FF] to-[#8B5CF6] rounded-full transition-all"
                  style={{ width: `${(count / maxCount) * 100}%` }}
                />
              </div>
            </div>
          ))}
          {topics.length === 0 && <p className="text-sm text-[#9CA3AF]">No chunks available</p>}
        </div>
      </div>

      {/* Timestamp distribution */}
      <div className="bg-white rounded-2xl border border-[#E5E7EB] p-5">
        <h4 className="text-sm font-bold text-[#1A1A2E] mb-4">Timestamp Distribution</h4>
        <div className="flex items-end gap-1 h-20">
          {chunks.map((chunk, i) => {
            const height = Math.max(20, (chunk.word_count / 400) * 100);
            return (
              <div
                key={chunk.id}
                title={`[${chunk.timestamp_label}] ${chunk.word_count} words`}
                className="flex-1 bg-gradient-to-t from-[#6C63FF] to-[#8B5CF6] rounded-t opacity-70 hover:opacity-100 transition-opacity cursor-pointer min-w-0"
                style={{ height: `${Math.min(100, height)}%` }}
              />
            );
          })}
        </div>
        <div className="flex justify-between text-xs text-[#9CA3AF] mt-1">
          <span>Start</span>
          <span>End</span>
        </div>
      </div>

      {/* Most dense sections */}
      <div className="bg-white rounded-2xl border border-[#E5E7EB] p-5">
        <h4 className="text-sm font-bold text-[#1A1A2E] mb-4">Most Dense Sections</h4>
        <div className="space-y-2">
          {topByWords.map((chunk, i) => (
            <div key={chunk.id} className="flex items-center gap-3 p-3 bg-[#F8F9FC] rounded-xl">
              <span className="text-sm font-bold text-[#6C63FF] w-5">{i + 1}</span>
              <span className="px-2 py-0.5 bg-green-100 text-green-700 text-xs font-semibold rounded-full">
                {chunk.timestamp_label}
              </span>
              <span className="text-xs text-[#6B7280] flex-1 truncate">{chunk.topic}</span>
              <span className="text-xs font-semibold text-[#1A1A2E]">{chunk.word_count}w</span>
            </div>
          ))}
          {topByWords.length === 0 && <p className="text-sm text-[#9CA3AF]">No data available</p>}
        </div>
      </div>
    </div>
  );
}

// ─── Main page ────────────────────────────────────────────────────
type Tab = "overview" | "chunks" | "analytics";

export default function LectureDetailPage() {
  const params = useParams();
  const id = params.id as string;
  const router = useRouter();

  const [lecture, setLecture] = useState<Lecture | null>(null);
  const [chunks, setChunks] = useState<Chunk[]>([]);
  const [loading, setLoading] = useState(true);
  const [chunksLoading, setChunksLoading] = useState(false);
  const [error, setError] = useState("");
  const [tab, setTab] = useState<Tab>("overview");
  const [chunkSearch, setChunkSearch] = useState("");

  useEffect(() => {
    (async () => {
      try {
        const res = await api.getLecture(id);
        if (res.success) {
          setLecture(res.lecture);
        } else {
          setError("Lecture not found");
        }
      } catch {
        setError("Failed to load lecture");
      } finally {
        setLoading(false);
      }
    })();
  }, [id]);

  useEffect(() => {
    if (tab === "chunks" || tab === "analytics") {
      if (chunks.length > 0) return;
      setChunksLoading(true);
      api.getLectureChunks(id)
        .then((res) => { if (res.success) setChunks(res.chunks); })
        .catch(() => {})
        .finally(() => setChunksLoading(false));
    }
  }, [tab, id]);

  const filteredChunks = chunkSearch.trim()
    ? chunks.filter((c) =>
        c.text.toLowerCase().includes(chunkSearch.toLowerCase()) ||
        c.topic.toLowerCase().includes(chunkSearch.toLowerCase()) ||
        c.timestamp_label.includes(chunkSearch)
      )
    : chunks;

  const uniqueTopics = [...new Set(chunks.map((c) => c.topic))].filter(Boolean);

  if (loading) {
    return (
      <div className="flex flex-col min-h-screen">
        <Header title="Lecture Details" />
        <main className="flex-1 p-6">
          <div className="space-y-4">
            {[1, 2, 3].map((i) => (
              <div key={i} className="h-24 bg-white rounded-2xl border border-[#E5E7EB] animate-pulse" />
            ))}
          </div>
        </main>
      </div>
    );
  }

  if (error || !lecture) {
    return (
      <div className="flex flex-col min-h-screen">
        <Header title="Lecture Details" />
        <main className="flex-1 p-6">
          <div className="flex items-center gap-3 p-4 bg-red-50 border border-red-200 rounded-xl text-sm text-red-700">
            <AlertCircle size={16} />
            {error || "Lecture not found"}
          </div>
        </main>
      </div>
    );
  }

  return (
    <div className="flex flex-col min-h-screen">
      <Header title={lecture.title} />
      <main className="flex-1 p-6">
        {/* Back + title row */}
        <div className="flex items-center justify-between mb-6">
          <div className="flex items-center gap-3">
            <Link
              href="/lectures"
              className="p-2 rounded-xl border border-[#E5E7EB] hover:bg-[#F5F6FA] text-[#6B7280] hover:text-[#1A1A2E] transition-colors"
            >
              <ArrowLeft size={16} />
            </Link>
            <div>
              <h2 className="text-lg font-bold text-[#1A1A2E]">{lecture.title}</h2>
              <p className="text-xs text-[#9CA3AF]">{lecture.instructor} · {lecture.course}</p>
            </div>
          </div>
          <StatusBadge status={lecture.status} />
        </div>

        {/* Stat cards */}
        <div className="grid grid-cols-3 gap-4 mb-6">
          <StatCard
            icon={Layers}
            label="Total Chunks"
            value={lecture.chunks_count ?? 0}
            color="bg-gradient-to-br from-[#6C63FF] to-[#8B5CF6]"
          />
          <StatCard
            icon={Clock}
            label="Duration"
            value={lecture.duration > 0 ? formatDuration(lecture.duration) : "—"}
            color="bg-gradient-to-br from-[#10B981] to-[#059669]"
          />
          <StatCard
            icon={BookOpen}
            label="Topics"
            value={uniqueTopics.length > 0 ? uniqueTopics.length : "—"}
            color="bg-gradient-to-br from-[#F59E0B] to-[#D97706]"
          />
        </div>

        {/* Tabs */}
        <div className="flex gap-1 p-1 bg-[#F3F4F6] rounded-xl mb-6 w-fit">
          {(["overview", "chunks", "analytics"] as Tab[]).map((t) => (
            <button
              key={t}
              onClick={() => setTab(t)}
              className={`px-5 py-2 text-sm font-semibold rounded-lg capitalize transition-all ${
                tab === t
                  ? "bg-white text-[#1A1A2E] shadow-sm"
                  : "text-[#6B7280] hover:text-[#1A1A2E]"
              }`}
            >
              {t === "chunks" ? "Transcript Chunks" : t.charAt(0).toUpperCase() + t.slice(1)}
            </button>
          ))}
        </div>

        {/* ── Overview ── */}
        {tab === "overview" && (
          <div className="grid grid-cols-1 lg:grid-cols-[1fr_380px] gap-5">
            <div className="space-y-5">
              {/* Lecture info */}
              <div className="bg-white rounded-2xl border border-[#E5E7EB] p-5">
                <h4 className="text-sm font-bold text-[#1A1A2E] mb-4">Lecture Info</h4>
                <div className="space-y-3">
                  {[
                    { icon: BookOpen, label: "Title", value: lecture.title },
                    { icon: User, label: "Instructor", value: lecture.instructor },
                    { icon: Layers, label: "Course", value: lecture.course },
                    { icon: Calendar, label: "Created", value: formatDate(lecture.created_at) },
                  ].map(({ icon: Icon, label, value }) => (
                    <div key={label} className="flex items-center gap-3 py-2.5 border-b border-[#F3F4F6] last:border-0">
                      <div className="w-8 h-8 rounded-lg bg-[#6C63FF]/10 flex items-center justify-center flex-shrink-0">
                        <Icon size={14} className="text-[#6C63FF]" />
                      </div>
                      <div>
                        <p className="text-xs text-[#9CA3AF]">{label}</p>
                        <p className="text-sm font-semibold text-[#1A1A2E]">{value}</p>
                      </div>
                    </div>
                  ))}
                </div>
              </div>

              {/* Topics */}
              {uniqueTopics.length > 0 && (
                <div className="bg-white rounded-2xl border border-[#E5E7EB] p-5">
                  <h4 className="text-sm font-bold text-[#1A1A2E] mb-3">Topics Covered</h4>
                  <div className="flex flex-wrap gap-2">
                    {uniqueTopics.map((topic) => (
                      <span
                        key={topic}
                        className="px-3 py-1.5 bg-[#6C63FF]/10 text-[#6C63FF] text-xs font-semibold rounded-full"
                      >
                        {topic}
                      </span>
                    ))}
                  </div>
                </div>
              )}
            </div>

            {/* Test AIVA */}
            <div>
              {lecture.status === "ready" ? (
                <TestAIVA lectureId={lecture.id} />
              ) : (
                <div className="bg-white rounded-2xl border border-[#E5E7EB] p-5">
                  <h4 className="text-sm font-bold text-[#1A1A2E] mb-2">Test AIVA</h4>
                  <p className="text-sm text-[#9CA3AF]">
                    AIVA will be available once the lecture finishes processing.
                  </p>
                  <div className="mt-3 p-3 bg-yellow-50 border border-yellow-200 rounded-xl text-xs text-yellow-700">
                    Current status: <strong>{lecture.status}</strong>
                  </div>
                </div>
              )}
            </div>
          </div>
        )}

        {/* ── Transcript Chunks ── */}
        {tab === "chunks" && (
          <div>
            <div className="flex items-center justify-between mb-4">
              <div className="relative flex-1 max-w-sm">
                <Search size={14} className="absolute left-3 top-1/2 -translate-y-1/2 text-[#9CA3AF]" />
                <input
                  value={chunkSearch}
                  onChange={(e) => setChunkSearch(e.target.value)}
                  placeholder="Search chunks by text, topic or timestamp..."
                  className="w-full pl-9 pr-4 py-2.5 border border-[#E5E7EB] rounded-xl text-sm focus:outline-none focus:border-[#6C63FF] focus:ring-2 focus:ring-[#6C63FF]/20"
                />
              </div>
              <span className="ml-3 px-3 py-1.5 bg-[#6C63FF]/10 text-[#6C63FF] text-xs font-semibold rounded-full">
                {filteredChunks.length} chunks
              </span>
            </div>

            {chunksLoading ? (
              <div className="space-y-3">
                {Array.from({ length: 5 }).map((_, i) => (
                  <div key={i} className="h-24 bg-white border border-[#E5E7EB] rounded-xl animate-pulse" />
                ))}
              </div>
            ) : filteredChunks.length === 0 ? (
              <div className="text-center py-16 text-sm text-[#9CA3AF]">
                {chunkSearch ? "No chunks match your search" : "No chunks found for this lecture"}
              </div>
            ) : (
              <div className="space-y-3">
                {filteredChunks.map((chunk) => (
                  <ChunkCard key={chunk.id} chunk={chunk} />
                ))}
              </div>
            )}
          </div>
        )}

        {/* ── Analytics ── */}
        {tab === "analytics" && (
          chunksLoading ? (
            <div className="space-y-4">
              {[1, 2, 3].map((i) => (
                <div key={i} className="h-40 bg-white rounded-2xl border border-[#E5E7EB] animate-pulse" />
              ))}
            </div>
          ) : (
            <AnalyticsTab chunks={chunks} />
          )
        )}
      </main>
    </div>
  );
}
