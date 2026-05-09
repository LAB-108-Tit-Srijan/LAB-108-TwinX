class CourseModel {
  final String id;
  final String name;
  final String instructor;
  final int totalLectures;
  final int completedLectures;
  final String category;
  final double progress;

  const CourseModel({
    required this.id,
    required this.name,
    required this.instructor,
    required this.totalLectures,
    required this.completedLectures,
    required this.category,
    required this.progress,
  });
}
