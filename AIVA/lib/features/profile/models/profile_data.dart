// Achievement model
class Achievement {
  final String id;
  final String title;
  final String description;
  final String icon;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final double progress; // 0.0 to 1.0 for locked achievements

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.isUnlocked,
    this.unlockedAt,
    this.progress = 0.0,
  });
}

// Certification model
class Certification {
  final String id;
  final String title;
  final String issuer;
  final String subject;
  final DateTime earnedAt;
  final String credentialId;

  Certification({
    required this.id,
    required this.title,
    required this.issuer,
    required this.subject,
    required this.earnedAt,
    required this.credentialId,
  });
}

// User stats model
class UserStats {
  final int currentStreak;
  final int longestStreak;
  final int totalHours;
  final int topicsCompleted;
  final int quizzesTaken;
  final int averageScore;
  final int totalXP;
  final int level;

  UserStats({
    required this.currentStreak,
    required this.longestStreak,
    required this.totalHours,
    required this.topicsCompleted,
    required this.quizzesTaken,
    required this.averageScore,
    required this.totalXP,
    required this.level,
  });
}

// Sample data
final UserStats sampleUserStats = UserStats(
  currentStreak: 12,
  longestStreak: 28,
  totalHours: 156,
  topicsCompleted: 89,
  quizzesTaken: 45,
  averageScore: 87,
  totalXP: 4580,
  level: 15,
);

final List<Achievement> sampleAchievements = [
  Achievement(
    id: '1',
    title: 'First Steps',
    description: 'Complete your first lesson',
    icon: '🎯',
    isUnlocked: true,
    unlockedAt: DateTime.now().subtract(const Duration(days: 30)),
  ),
  Achievement(
    id: '2',
    title: 'Week Warrior',
    description: 'Maintain a 7-day streak',
    icon: '🔥',
    isUnlocked: true,
    unlockedAt: DateTime.now().subtract(const Duration(days: 20)),
  ),
  Achievement(
    id: '3',
    title: 'Quiz Master',
    description: 'Score 100% on 5 quizzes',
    icon: '🏆',
    isUnlocked: true,
    unlockedAt: DateTime.now().subtract(const Duration(days: 10)),
  ),
  Achievement(
    id: '4',
    title: 'Night Owl',
    description: 'Study after midnight',
    icon: '🦉',
    isUnlocked: true,
    unlockedAt: DateTime.now().subtract(const Duration(days: 5)),
  ),
  Achievement(
    id: '5',
    title: 'Early Bird',
    description: 'Study before 6 AM',
    icon: '🌅',
    isUnlocked: false,
    progress: 0.0,
  ),
  Achievement(
    id: '6',
    title: 'Marathon Learner',
    description: 'Study for 5 hours in one day',
    icon: '⚡',
    isUnlocked: false,
    progress: 0.6,
  ),
  Achievement(
    id: '7',
    title: 'Perfectionist',
    description: 'Complete 10 perfect quizzes',
    icon: '💎',
    isUnlocked: false,
    progress: 0.3,
  ),
  Achievement(
    id: '8',
    title: 'Monthly Champion',
    description: 'Maintain a 30-day streak',
    icon: '👑',
    isUnlocked: false,
    progress: 0.4,
  ),
];

final List<Certification> sampleCertifications = [
  Certification(
    id: '1',
    title: 'Physics Fundamentals',
    issuer: 'AIVA Academy',
    subject: 'Physics',
    earnedAt: DateTime.now().subtract(const Duration(days: 15)),
    credentialId: 'PHY-2024-001',
  ),
  Certification(
    id: '2',
    title: 'Calculus Mastery',
    issuer: 'AIVA Academy',
    subject: 'Mathematics',
    earnedAt: DateTime.now().subtract(const Duration(days: 8)),
    credentialId: 'MATH-2024-002',
  ),
  Certification(
    id: '3',
    title: 'Chemistry Basics',
    issuer: 'AIVA Academy',
    subject: 'Chemistry',
    earnedAt: DateTime.now().subtract(const Duration(days: 3)),
    credentialId: 'CHEM-2024-003',
  ),
];

// Weekly streak data (true = studied, false = missed)
final List<bool> weeklyStreak = [true, true, true, false, true, true, true];

