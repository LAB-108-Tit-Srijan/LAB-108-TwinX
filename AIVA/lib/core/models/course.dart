class Course {
  final String id;
  final String title;
  final String? description;
  final String? instructor;
  final String? category;
  final String thumbnailColor;
  final int totalLectures;
  final int estimatedHours;
  final String level;
  final bool isPublished;
  final String? enrollmentId;

  const Course({
    required this.id,
    required this.title,
    this.description,
    this.instructor,
    this.category,
    this.thumbnailColor = '#6C63FF',
    this.totalLectures = 0,
    this.estimatedHours = 0,
    this.level = 'Beginner',
    this.isPublished = false,
    this.enrollmentId,
  });

  factory Course.fromJson(Map<String, dynamic> json) => Course(
    id: json['id'] as String,
    title: json['title'] as String,
    description: json['description'] as String?,
    instructor: json['instructor'] as String?,
    category: json['category'] as String?,
    thumbnailColor: json['thumbnail_color'] as String? ?? '#6C63FF',
    totalLectures: (json['actual_lectures'] ?? json['total_lectures'] ?? 0) as int,
    estimatedHours: (json['estimated_hours'] ?? 0) as int,
    level: json['level'] as String? ?? 'Beginner',
    isPublished: json['is_published'] as bool? ?? false,
    enrollmentId: json['enrollment_id'] as String?,
  );
}
