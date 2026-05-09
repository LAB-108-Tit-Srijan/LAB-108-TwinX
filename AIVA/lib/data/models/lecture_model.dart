class LectureModel {
  final String id;
  final String title;
  final String courseName;
  final String instructorName;
  final String duration;
  final String thumbnailGradient;
  final double progress;
  final int doubtsCount;
  final bool isNew;
  final String level;
  final int views;
  final String description;
  final List<String> topics;

  const LectureModel({
    required this.id,
    required this.title,
    required this.courseName,
    required this.instructorName,
    required this.duration,
    required this.thumbnailGradient,
    required this.progress,
    required this.doubtsCount,
    this.isNew = false,
    required this.level,
    required this.views,
    required this.description,
    required this.topics,
  });
}
