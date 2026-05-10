"use client";

import { useEffect, useState } from "react";
import { Header } from "@/components/layout/header";
import { Save, Eye, EyeOff } from "lucide-react";
import { auth } from "@/lib/auth";

function getAdminFromToken(): { name: string; email: string } | null {
  if (typeof window === "undefined") return null;
  const token = auth.getToken();
  if (!token) return null;
  try {
    const payload = JSON.parse(atob(token.split(".")[1]));
    return { name: payload.name ?? "Admin", email: payload.email ?? "" };
  } catch {
    return null;
  }
}

export default function SettingsPage() {
  const [showApiKey, setShowApiKey] = useState(false);
  const [defaultLang, setDefaultLang] = useState("EN");
  const [maxDoubts, setMaxDoubts] = useState(50);
  const [emailAlerts, setEmailAlerts] = useState(true);
  const [dailySummary, setDailySummary] = useState(true);
  const [visualExp, setVisualExp] = useState(true);
  const [crossLecture, setCrossLecture] = useState(true);
  const [saved, setSaved] = useState(false);
  const [adminInfo, setAdminInfo] = useState<{ name: string; email: string } | null>(null);

  useEffect(() => {
    setAdminInfo(getAdminFromToken());
  }, []);

  function handleSave() {
    setSaved(true);
    setTimeout(() => setSaved(false), 3000);
  }

  return (
    <div className="flex flex-col min-h-screen">
      <Header title="Settings" />
      <main className="flex-1 p-6">
        <div className="max-w-3xl space-y-6">
          {saved && (
            <div className="bg-[#10B981]/10 border border-[#10B981]/30 text-[#10B981] rounded-xl px-4 py-3 text-sm font-medium">
              Settings saved successfully.
            </div>
          )}

          {/* Admin Profile */}
          {adminInfo && (
            <div className="bg-white rounded-2xl border border-[#E5E7EB] p-6">
              <h3 className="font-bold text-[#1A1A2E] mb-4">Admin Profile</h3>
              <div className="flex items-center gap-4">
                <div className="w-12 h-12 rounded-full bg-gradient-to-br from-[#6C63FF] to-[#8B5CF6] flex items-center justify-center flex-shrink-0">
                  <span className="text-white font-bold text-lg">
                    {adminInfo.name ? adminInfo.name[0].toUpperCase() : "A"}
                  </span>
                </div>
                <div>
                  <p className="text-sm font-semibold text-[#1A1A2E]">{adminInfo.name}</p>
                  <p className="text-xs text-[#9CA3AF] mt-0.5">{adminInfo.email}</p>
                </div>
              </div>
            </div>
          )}

          {/* General */}
          <div className="bg-white rounded-2xl border border-[#E5E7EB] p-6">
            <h3 className="font-bold text-[#1A1A2E] mb-4">General</h3>
            <div className="space-y-4">
              <div>
                <label className="text-sm font-medium text-[#1A1A2E] block mb-1.5">Institute Name</label>
                <input defaultValue="AIVA Learning Institute" className="w-full px-4 py-3 border border-[#E5E7EB] rounded-xl text-sm focus:outline-none focus:border-[#6C63FF] focus:ring-2 focus:ring-[#6C63FF]/20" />
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="text-sm font-medium text-[#1A1A2E] block mb-1.5">Timezone</label>
                  <select className="w-full px-4 py-3 border border-[#E5E7EB] rounded-xl text-sm bg-white focus:outline-none focus:border-[#6C63FF]">
                    <option>Asia/Kolkata (IST +5:30)</option>
                    <option>UTC</option>
                  </select>
                </div>
                <div>
                  <label className="text-sm font-medium text-[#1A1A2E] block mb-1.5">Logo</label>
                  <button className="w-full px-4 py-3 border border-dashed border-[#E5E7EB] rounded-xl text-sm text-[#9CA3AF] hover:border-[#6C63FF] hover:text-[#6C63FF] transition-colors text-center">
                    Upload Logo
                  </button>
                </div>
              </div>
            </div>
          </div>

          {/* AIVA Settings */}
          <div className="bg-white rounded-2xl border border-[#E5E7EB] p-6">
            <h3 className="font-bold text-[#1A1A2E] mb-4">AIVA Settings</h3>
            <div className="space-y-4">
              <div>
                <label className="text-sm font-medium text-[#1A1A2E] block mb-1.5">API Key</label>
                <div className="relative">
                  <input
                    type={showApiKey ? "text" : "password"}
                    defaultValue="sk-aiva-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
                    className="w-full px-4 py-3 pr-12 border border-[#E5E7EB] rounded-xl text-sm focus:outline-none focus:border-[#6C63FF] focus:ring-2 focus:ring-[#6C63FF]/20 font-mono"
                  />
                  <button
                    onClick={() => setShowApiKey(!showApiKey)}
                    className="absolute right-3 top-1/2 -translate-y-1/2 text-[#9CA3AF] hover:text-[#6B7280] transition-colors"
                  >
                    {showApiKey ? <EyeOff size={16} /> : <Eye size={16} />}
                  </button>
                </div>
              </div>

              <div className="flex items-center justify-between py-3 px-4 bg-[#F5F6FA] rounded-xl">
                <div>
                  <p className="text-sm font-medium text-[#1A1A2E]">Default Language</p>
                  <p className="text-xs text-[#9CA3AF]">Fallback language for AIVA responses</p>
                </div>
                <div className="flex gap-2">
                  {["EN", "HI"].map((l) => (
                    <button
                      key={l}
                      onClick={() => setDefaultLang(l)}
                      className={`px-4 py-1.5 rounded-lg text-sm font-semibold transition-all ${defaultLang === l ? "bg-[#6C63FF] text-white" : "bg-white border border-[#E5E7EB] text-[#6B7280]"}`}
                    >
                      {l === "EN" ? "English" : "हिंदी"}
                    </button>
                  ))}
                </div>
              </div>

              <div className="flex items-center justify-between py-3 px-4 bg-[#F5F6FA] rounded-xl">
                <div>
                  <p className="text-sm font-medium text-[#1A1A2E]">Max doubts per student/day</p>
                  <p className="text-xs text-[#9CA3AF]">Limit to prevent abuse</p>
                </div>
                <div className="flex items-center gap-3">
                  <button onClick={() => setMaxDoubts(Math.max(10, maxDoubts - 10))} className="w-8 h-8 rounded-lg border border-[#E5E7EB] bg-white text-[#6B7280] hover:bg-[#F5F6FA] flex items-center justify-center font-bold">-</button>
                  <span className="w-10 text-center text-sm font-bold text-[#1A1A2E]">{maxDoubts}</span>
                  <button onClick={() => setMaxDoubts(maxDoubts + 10)} className="w-8 h-8 rounded-lg border border-[#E5E7EB] bg-white text-[#6B7280] hover:bg-[#F5F6FA] flex items-center justify-center font-bold">+</button>
                </div>
              </div>

              {[
                { label: "Visual Explanations", desc: "AI-generated diagrams in responses", val: visualExp, set: setVisualExp },
                { label: "Cross-Lecture Linking", desc: "Suggest related content from other lectures", val: crossLecture, set: setCrossLecture },
              ].map((item) => (
                <div key={item.label} className="flex items-center justify-between py-3 px-4 bg-[#F5F6FA] rounded-xl">
                  <div>
                    <p className="text-sm font-medium text-[#1A1A2E]">{item.label}</p>
                    <p className="text-xs text-[#9CA3AF]">{item.desc}</p>
                  </div>
                  <button onClick={() => item.set(!item.val)} className={`w-12 h-6 rounded-full relative transition-colors ${item.val ? "bg-[#6C63FF]" : "bg-[#E5E7EB]"}`}>
                    <div className={`w-5 h-5 bg-white rounded-full absolute top-0.5 transition-all shadow-sm ${item.val ? "right-0.5" : "left-0.5"}`} />
                  </button>
                </div>
              ))}
            </div>
          </div>

          {/* Notifications */}
          <div className="bg-white rounded-2xl border border-[#E5E7EB] p-6">
            <h3 className="font-bold text-[#1A1A2E] mb-4">Notifications</h3>
            <div className="space-y-3">
              {[
                { label: "Email alerts for at-risk students", val: emailAlerts, set: setEmailAlerts },
                { label: "Daily summary email", val: dailySummary, set: setDailySummary },
              ].map((item) => (
                <div key={item.label} className="flex items-center justify-between py-3 px-4 bg-[#F5F6FA] rounded-xl">
                  <p className="text-sm font-medium text-[#1A1A2E]">{item.label}</p>
                  <button onClick={() => item.set(!item.val)} className={`w-12 h-6 rounded-full relative transition-colors ${item.val ? "bg-[#6C63FF]" : "bg-[#E5E7EB]"}`}>
                    <div className={`w-5 h-5 bg-white rounded-full absolute top-0.5 transition-all shadow-sm ${item.val ? "right-0.5" : "left-0.5"}`} />
                  </button>
                </div>
              ))}
            </div>
          </div>

          <button
            onClick={handleSave}
            className="w-full flex items-center justify-center gap-2 py-3.5 bg-gradient-to-r from-[#6C63FF] to-[#8B5CF6] text-white font-semibold rounded-xl hover:opacity-90 transition-opacity shadow-sm shadow-[#6C63FF]/30"
          >
            <Save size={16} />
            Save All Settings
          </button>
        </div>
      </main>
    </div>
  );
}
