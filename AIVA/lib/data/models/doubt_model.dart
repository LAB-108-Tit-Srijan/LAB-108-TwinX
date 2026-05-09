class DoubtModel {
  final String id;
  final String question;
  final String answer;
  final String lectureId;
  final String lectureName;
  final String timestamp;
  final DateTime askedAt;
  final String language;
  final bool isAi;

  const DoubtModel({
    required this.id,
    required this.question,
    required this.answer,
    required this.lectureId,
    required this.lectureName,
    required this.timestamp,
    required this.askedAt,
    required this.language,
    this.isAi = false,
  });
}
