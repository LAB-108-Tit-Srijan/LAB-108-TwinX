# AIVA — AI-Powered Learning Companion

**Team TwinX** | Problem Statement 4

---

## Problem Statement

> Learners often struggle to revise long video lectures, locate concepts, and resolve doubts in real time.

## What We Built

An AI-powered assistant integrated into an LMS video player using RAG-based contextual understanding — built with Flutter for cross-platform support (Android, iOS, Web).

## Core Features

| Feature | Description |
|---|---|
| **Contextual Q&A** | Ask questions directly from lecture transcripts |
| **Smart Summaries** | Generate topic-wise and last 5-minute summaries |
| **Jump-to-Moment** | Clickable timestamps to navigate video sections |
| **Streaming Responses** | Real-time AI-generated responses |
| **Session Memory** | Retains conversation context within sessions |

## App Flow

**Splash** → **Onboarding** (3-slide carousel) → **Phone / OTP Login** → **Home**

Home has a bottom navigation bar with 5 sections:

| Tab | Description |
|---|---|
| **Home** | Dashboard with quick actions — Study Mode, Quiz, Roadmap, Flashcards, Notes |
| **Explore** | Video library with category filtering and search |
| **AI** | Chat interface with conversation history and voice mode |
| **Progress** | 4-tab dashboard — Dashboard, Notes, Quiz, Credits |
| **Profile** | User stats, streak counter, settings |

## Tech Stack

- **Flutter** ≥ 3.10.4 (Dart 3) — cross-platform UI
- **Material Design 3** — design system with Lato (Google Fonts)
- **RAG-based AI** — contextual understanding of lecture content

**Key packages:**

| Package | Purpose |
|---|---|
| `http ^1.2.0` | API communication |
| `google_fonts ^6.2.1` | Lato typography |
| `cached_network_image ^3.3.1` | Network image loading with cache |
| `device_info_plus ^10.1.0` | Device metadata |

## Getting Started

**Prerequisites:** Flutter SDK ≥ 3.10.4

```bash
# Install dependencies
flutter pub get

# Run the app
flutter run

# Analyze code
flutter analyze

# Run tests
flutter test
```

## Project Structure

```
lib/
├── core/
│   ├── services/         # API service (login analytics)
│   └── theme/            # Colors, typography, Material 3 theme
└── features/
    ├── auth/             # Phone login, OTP, Google login
    ├── splash/           # Animated splash screen
    ├── onboarding/       # 3-slide intro carousel
    ├── home/             # Main dashboard
    ├── ai_chat/          # Chat interface + voice mode
    ├── explore/          # Video library with search & filter
    ├── progress/         # Learning progress tracking
    ├── profile/          # User profile & achievements
    ├── roadmap/          # Structured learning paths
    └── todo/             # Task management
```

## Design System

- **Primary:** Lime Green `#BBF246` + Dark Navy `#192126`
- **Font:** Lato via Google Fonts
- **Responsive:** All sizes scale with viewport width/height percentages
