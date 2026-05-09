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

// Sample data
final List<Subject> sampleSubjects = [
  Subject(
    id: '1',
    name: 'Physics',
    icon: '⚡',
    totalChapters: 12,
    completedChapters: 5,
    progress: 0.42,
    chapters: [
      Chapter(
        id: '1-1',
        name: 'Mechanics',
        totalTopics: 8,
        completedTopics: 6,
        progress: 0.75,
        topics: [
          Topic(
            id: '1-1-1',
            name: 'Newton\'s Laws',
            isCompleted: true,
            notes: [
              NoteFile(id: 'n1', name: 'Newton Laws Notes.pdf', type: 'pdf', createdAt: DateTime.now(), size: '2.4 MB'),
              NoteFile(id: 'n2', name: 'Practice Problems.doc', type: 'doc', createdAt: DateTime.now(), size: '1.1 MB'),
            ],
            quizzes: [
              Quiz(id: 'q1', title: 'Laws of Motion Quiz', totalQuestions: 10, score: 8, isCompleted: true, completedAt: DateTime.now()),
            ],
          ),
          Topic(id: '1-1-2', name: 'Kinematics', isCompleted: true, notes: [], quizzes: []),
          Topic(id: '1-1-3', name: 'Work & Energy', isCompleted: true, notes: [], quizzes: []),
          Topic(id: '1-1-4', name: 'Momentum', isCompleted: true, notes: [], quizzes: []),
          Topic(id: '1-1-5', name: 'Rotational Motion', isCompleted: true, notes: [], quizzes: []),
          Topic(id: '1-1-6', name: 'Gravitation', isCompleted: true, notes: [], quizzes: []),
          Topic(id: '1-1-7', name: 'Oscillations', isCompleted: false, notes: [], quizzes: []),
          Topic(id: '1-1-8', name: 'Waves', isCompleted: false, notes: [], quizzes: []),
        ],
      ),
      Chapter(
        id: '1-2',
        name: 'Thermodynamics',
        totalTopics: 5,
        completedTopics: 2,
        progress: 0.4,
        topics: [
          Topic(id: '1-2-1', name: 'Heat Transfer', isCompleted: true, notes: [], quizzes: []),
          Topic(id: '1-2-2', name: 'Laws of Thermodynamics', isCompleted: true, notes: [], quizzes: []),
          Topic(id: '1-2-3', name: 'Entropy', isCompleted: false, notes: [], quizzes: []),
        ],
      ),
    ],
  ),
  Subject(
    id: '2',
    name: 'Mathematics',
    icon: '📐',
    totalChapters: 15,
    completedChapters: 8,
    progress: 0.53,
    chapters: [
      Chapter(
        id: '2-1',
        name: 'Calculus',
        totalTopics: 10,
        completedTopics: 7,
        progress: 0.7,
        topics: [
          Topic(id: '2-1-1', name: 'Limits', isCompleted: true, notes: [], quizzes: []),
          Topic(id: '2-1-2', name: 'Derivatives', isCompleted: true, notes: [], quizzes: []),
          Topic(id: '2-1-3', name: 'Integration', isCompleted: true, notes: [], quizzes: []),
        ],
      ),
    ],
  ),
  Subject(
    id: '3',
    name: 'Chemistry',
    icon: '🧪',
    totalChapters: 14,
    completedChapters: 6,
    progress: 0.43,
    chapters: [],
  ),
  Subject(
    id: '4',
    name: 'Biology',
    icon: '🧬',
    totalChapters: 10,
    completedChapters: 4,
    progress: 0.40,
    chapters: [],
  ),
  Subject(
    id: '5',
    name: 'History',
    icon: '📜',
    totalChapters: 8,
    completedChapters: 3,
    progress: 0.38,
    chapters: [],
  ),
];

final Map<String, List<RoadmapStep>> subjectRoadmaps = {
  '1': [ // Physics
    RoadmapStep(id: 'r1', title: 'Basics of Motion', description: 'Understand displacement, velocity, acceleration', isCompleted: true, isCurrent: false, order: 1),
    RoadmapStep(id: 'r2', title: 'Newton\'s Laws', description: 'Learn the three laws of motion', isCompleted: true, isCurrent: false, order: 2),
    RoadmapStep(id: 'r3', title: 'Work & Energy', description: 'Kinetic, potential energy concepts', isCompleted: true, isCurrent: false, order: 3),
    RoadmapStep(id: 'r4', title: 'Momentum', description: 'Conservation of momentum', isCompleted: false, isCurrent: true, order: 4),
    RoadmapStep(id: 'r5', title: 'Rotational Motion', description: 'Angular velocity, torque', isCompleted: false, isCurrent: false, order: 5),
    RoadmapStep(id: 'r6', title: 'Gravitation', description: 'Universal law of gravitation', isCompleted: false, isCurrent: false, order: 6),
  ],
  '2': [ // Mathematics
    RoadmapStep(id: 'r1', title: 'Algebra Basics', description: 'Equations, inequalities', isCompleted: true, isCurrent: false, order: 1),
    RoadmapStep(id: 'r2', title: 'Functions', description: 'Types, graphs, transformations', isCompleted: true, isCurrent: false, order: 2),
    RoadmapStep(id: 'r3', title: 'Limits', description: 'Foundation of calculus', isCompleted: true, isCurrent: false, order: 3),
    RoadmapStep(id: 'r4', title: 'Derivatives', description: 'Rate of change, differentiation', isCompleted: true, isCurrent: false, order: 4),
    RoadmapStep(id: 'r5', title: 'Integration', description: 'Area under curves', isCompleted: false, isCurrent: true, order: 5),
    RoadmapStep(id: 'r6', title: 'Applications', description: 'Real-world problems', isCompleted: false, isCurrent: false, order: 6),
  ],
};

