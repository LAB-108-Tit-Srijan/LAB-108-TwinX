class StudentModel {
  final String id;
  final String name;
  final String phone;
  final String institute;
  final String avatarInitials;
  final int streakDays;
  final int lecturesWatched;
  final int doubtsAsked;

  const StudentModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.institute,
    required this.avatarInitials,
    required this.streakDays,
    required this.lecturesWatched,
    required this.doubtsAsked,
  });
}
