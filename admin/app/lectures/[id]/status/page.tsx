"use client";

import { useState, useEffect, useRef } from "react";
import { useParams, useRouter } from "next/navigation";
import Link from "next/link";
import { ArrowLeft, CheckCircle2, XCircle, Upload } from "lucide-react";
import { Header } from "@/components/layout/header";
import { api, LectureStatus, formatDuration } from "@/lib/api";

function TranscribingState() {
  return (
    <div className="text-center py-6">
      <div className="relative w-16 h-16 mx-auto mb-5">
        <div className="absolute inset-0 rounded-full border-4 border-[#6C63FF]/20" />
        <div className="absolute inset-0 rounded-full border-4 border-[#6C63FF] border-t-transparent animate-spin" />
        <div className="absolute inset-2 rounded-full bg-[#6C63FF]/10 flex items-center justify-center">
          <span className="text-lg">🎙️</span>
        </div>
      </div>
      <h3 className="text-xl font-bold text-[#1A1A2E] mb-2">Transcribing Audio...</h3>
      <p className="text-sm text-[#6B7280] max-w-xs mx-auto">
        Converting your lecture audio to text with timestamps using Whisper AI
      </p>
      <div className="mt-5 flex items-center justify-center gap-2">
        {[1, 2, 3].map((step) => (
          <div
            key={step}
            className={`flex items-center justify-center w-7 h-7 rounded-full text-xs font-bold ${
              step === 1 ? "bg-[#6C63FF] text-white" : "bg-[#F3F4F6] text-[#9CA3AF]"
            }`}
          >
            {step}
          </div>
        ))}
      </div>
      <p className="text-xs text-[#9CA3AF] mt-2">Step 1 of 3 — Transcription</p>
    </div>
  );
}

function ProcessingState() {
  return (
    <div className="text-center py-6">
      <div className="relative w-16 h-16 mx-auto mb-5">
        <div className="absolute inset-0 rounded-full border-4 border-blue-200" />
        <div className="absolute inset-0 rounded-full border-4 border-blue-500 border-t-transparent animate-spin" />
        <div className="absolute inset-2 rounded-full bg-blue-50 flex items-center justify-center">
          <span className="text-lg animate-pulse">🧠</span>
        </div>
      </div>
      <h3 className="text-xl font-bold text-[#1A1A2E] mb-2">Processing Transcript...</h3>
      <p className="text-sm text-[#6B7280] max-w-xs mx-auto">
        Chunking and embedding your lecture for AI-powered search
      </p>
      <div className="mt-5 flex items-center justify-center gap-2">
        {[1, 2, 3].map((step) => (
          <div
            key={step}
            className={`flex items-center justify-center w-7 h-7 rounded-full text-xs font-bold ${
              step <= 2 ? "bg-[#6C63FF] text-white" : "bg-[#F3F4F6] text-[#9CA3AF]"
            }`}
          >
            {step}
          </div>
        ))}
      </div>
      <p className="text-xs text-[#9CA3AF] mt-2">Step 2 of 3 — Embedding</p>
    </div>
  );
}

function ReadyState({ lecture, id }: { lecture: LectureStatus; id: string }) {
  const router = useRouter();
  return (
    <div className="text-center py-6">
      <div className="w-16 h-16 rounded-full bg-green-100 flex items-center justify-center mx-auto mb-5">
        <CheckCircle2 size={36} className="text-[#10B981]" />
      </div>
      <h3 className="text-xl font-bold text-[#1A1A2E] mb-2">Lecture Ready!</h3>
      <p className="text-sm text-[#6B7280] mb-6">
        Students can now ask doubts from this lecture
      </p>
      <div className="flex items-center justify-center gap-8 py-4 px-6 bg-[#F8F9FC] rounded-2xl mb-6">
        <div className="text-center">
          <p className="text-2xl font-bold text-[#6C63FF]">{lecture.chunks_count}</p>
          <p className="text-xs text-[#9CA3AF] mt-0.5">Chunks Created</p>
        </div>
        <div className="w-px h-10 bg-[#E5E7EB]" />
        <div className="text-center">
          <p className="text-2xl font-bold text-[#6C63FF]">{formatDuration(lecture.duration)}</p>
          <p className="text-xs text-[#9CA3AF] mt-0.5">Duration</p>
        </div>
      </div>
      <div className="flex gap-3">
        <button
          onClick={() => router.push(`/lectures/${id}`)}
          className="flex-1 py-3 bg-gradient-to-r from-[#6C63FF] to-[#8B5CF6] text-white text-sm font-semibold rounded-xl hover:opacity-90 transition-opacity"
        >
          View Lecture Details
        </button>
        <button
          onClick={() => router.push("/lectures/upload")}
          className="flex-1 py-3 border border-[#E5E7EB] rounded-xl text-sm font-semibold text-[#6B7280] hover:bg-[#F5F6FA] transition-colors"
        >
          Upload Another
        </button>
      </div>
    </div>
  );
}

function FailedState() {
  const router = useRouter();
  return (
    <div className="text-center py-6">
      <div className="w-16 h-16 rounded-full bg-red-100 flex items-center justify-center mx-auto mb-5">
        <XCircle size={36} className="text-[#EF4444]" />
      </div>
      <h3 className="text-xl font-bold text-[#1A1A2E] mb-2">Processing Failed</h3>
      <p className="text-sm text-[#6B7280] mb-6">
        Something went wrong. Please try uploading again.
      </p>
      <button
        onClick={() => router.push("/lectures/upload")}
        className="flex items-center gap-2 mx-auto px-6 py-3 bg-gradient-to-r from-[#EF4444] to-[#DC2626] text-white text-sm font-semibold rounded-xl hover:opacity-90 transition-opacity"
      >
        <Upload size={15} />
        Retry Upload
      </button>
    </div>
  );
}

function UploadingState() {
  return (
    <div className="text-center py-6">
      <div className="relative w-16 h-16 mx-auto mb-5">
        <div className="absolute inset-0 rounded-full border-4 border-gray-200" />
        <div className="absolute inset-0 rounded-full border-4 border-[#6C63FF] border-t-transparent animate-spin" />
        <div className="absolute inset-2 rounded-full bg-[#F5F6FA] flex items-center justify-center">
          <Upload size={20} className="text-[#6C63FF]" />
        </div>
      </div>
      <h3 className="text-xl font-bold text-[#1A1A2E] mb-2">Uploading...</h3>
      <p className="text-sm text-[#6B7280]">Your video is being uploaded to the server</p>
    </div>
  );
}

export default function LectureStatusPage() {
  const params = useParams();
  const id = params.id as string;

  const [lecture, setLecture] = useState<LectureStatus | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const intervalRef = useRef<ReturnType<typeof setInterval> | null>(null);

  const pollStatus = async () => {
    try {
      const data = await api.getLectureStatus(id);
      setLecture(data);
      setLoading(false);
      if (data.status === "ready" || data.status === "failed") {
        if (intervalRef.current) clearInterval(intervalRef.current);
      }
    } catch {
      setError("Failed to fetch status. Backend may be unreachable.");
      setLoading(false);
    }
  };

  useEffect(() => {
    pollStatus();
    intervalRef.current = setInterval(pollStatus, 3000);
    return () => {
      if (intervalRef.current) clearInterval(intervalRef.current);
    };
  }, [id]);

  return (
    <div className="flex flex-col min-h-screen">
      <Header title="Processing Status" />
      <main className="flex-1 p-6">
        <div className="flex items-center gap-3 mb-6">
          <Link
            href="/lectures"
            className="p-2 rounded-xl border border-[#E5E7EB] hover:bg-[#F5F6FA] text-[#6B7280] hover:text-[#1A1A2E] transition-colors"
          >
            <ArrowLeft size={16} />
          </Link>
          <div>
            <h2 className="text-lg font-bold text-[#1A1A2E]">
              {lecture?.title ?? "Processing Lecture"}
            </h2>
            <p className="text-xs text-[#9CA3AF]">ID: {id}</p>
          </div>
        </div>

        {error && (
          <div className="max-w-lg mx-auto mb-6 flex items-center gap-2 p-4 bg-red-50 border border-red-200 rounded-xl text-sm text-red-700">
            <XCircle size={15} className="flex-shrink-0" />
            {error}
          </div>
        )}

        <div className="max-w-lg mx-auto">
          <div className="bg-white rounded-2xl border border-[#E5E7EB] p-8 shadow-sm">
            {loading ? (
              <div className="text-center py-8">
                <div className="w-12 h-12 rounded-full border-4 border-[#6C63FF] border-t-transparent animate-spin mx-auto mb-4" />
                <p className="text-sm text-[#6B7280]">Checking status...</p>
              </div>
            ) : !lecture ? (
              <div className="text-center py-8 text-sm text-[#6B7280]">Lecture not found</div>
            ) : lecture.status === "uploading" ? (
              <UploadingState />
            ) : lecture.status === "transcribing" ? (
              <TranscribingState />
            ) : lecture.status === "processing" ? (
              <ProcessingState />
            ) : lecture.status === "ready" ? (
              <ReadyState lecture={lecture} id={id} />
            ) : (
              <FailedState />
            )}
          </div>

          {lecture && lecture.status !== "ready" && lecture.status !== "failed" && (
            <p className="text-center text-xs text-[#9CA3AF] mt-4">
              Checking every 3 seconds · You can safely close this page
            </p>
          )}
        </div>
      </main>
    </div>
  );
}
