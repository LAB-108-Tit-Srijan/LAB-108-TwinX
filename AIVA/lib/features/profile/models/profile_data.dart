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

// Default zero stats — real data comes from ProfileService.getProfile()
final UserStats sampleUserStats = UserStats(
  currentStreak: 0,
  longestStreak: 0,
  totalHours: 0,
  topicsCompleted: 0,
  quizzesTaken: 0,
  averageScore: 0,
  totalXP: 0,
  level: 1,
);

// Cleared — achievements and certifications come from real credits/completions
final List<Achievement> sampleAchievements = [];
final List<Certification> sampleCertifications = [];

// Weekly streak data (true = studied, false = missed)
final List<bool> weeklyStreak = [true, true, true, false, true, true, true];

