class Lecture {
  final String id;
  final String title;
  final String instructor;
  final String? courseId;
  final double duration;
  final String status;
  final int chunksCount;
  final int orderIndex;

  const Lecture({
    required this.id,
    required this.title,
    required this.instructor,
    this.courseId,
    this.duration = 0,
    this.status = 'ready',
    this.chunksCount = 0,
    this.orderIndex = 0,
  });

  factory Lecture.fromJson(Map<String, dynamic> json) => Lecture(
    id: json['id'] as String,
    title: json['title'] as String,
    instructor: json['instructor'] as String? ?? '',
    courseId: json['course_id'] as String?,
    duration: (json['duration'] as num?)?.toDouble() ?? 0,
    status: json['status'] as String? ?? 'ready',
    chunksCount: (json['chunks_count'] ?? 0) as int,
    orderIndex: (json['order_index'] ?? 0) as int,
  );

  int get durationMinutes => (duration / 60).round();
}
