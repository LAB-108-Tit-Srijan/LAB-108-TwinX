// Subject model
class Subject {
  final String id;
  final String name;
  final String icon;
  final int totalChapters;
  final int completedChapters;
  final double progress;
  final List<Chapter> chapters;

  Subject({
    required this.id,
    required this.name,
    required this.icon,
    required this.totalChapters,
    required this.completedChapters,
    required this.progress,
    required this.chapters,
  });
}

// Chapter model
class Chapter {
  final String id;
  final String name;
  final int totalTopics;
  final int completedTopics;
  final double progress;
  final List<Topic> topics;

  Chapter({
    required this.id,
    required this.name,
    required this.totalTopics,
    required this.completedTopics,
    required this.progress,
    required this.topics,
  });
}

// Topic model
class Topic {
  final String id;
  final String name;
  final bool isCompleted;
  final List<NoteFile> notes;
  final List<Quiz> quizzes;

  Topic({
    required this.id,
    required this.name,
    required this.isCompleted,
    required this.notes,
    required this.quizzes,
  });
}

// Note file model
class NoteFile {
  final String id;
  final String name;
  final String type; // pdf, doc, image, text
  final DateTime createdAt;
  final String size;

  NoteFile({
    required this.id,
    required this.name,
    required this.type,
    required this.createdAt,
    required this.size,
  });
}

// Quiz model
class Quiz {
  final String id;
  final String title;
  final int totalQuestions;
  final int score;
  final bool isCompleted;
  final DateTime? completedAt;

  Quiz({
    required this.id,
    required this.title,
    required this.totalQuestions,
    required this.score,
    required this.isCompleted,
    this.completedAt,
  });
}

// Roadmap step model
class RoadmapStep {
  final String id;
  final String title;
  final String description;
  final bool isCompleted;
  final bool isCurrent;
  final int order;

  RoadmapStep({
    required this.id,
    required this.title,
    required this.description,
    required this.isCompleted,
    required this.isCurrent,
    required this.order,
  });
}

// Sample data (cleared — use real data from API)
final List<Subject> sampleSubjects = [];

final Map<String, List<RoadmapStep>> subjectRoadmaps = {};

