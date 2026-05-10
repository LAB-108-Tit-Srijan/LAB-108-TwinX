class WeekLecture {
  final String lectureId;
  final String title;
  final int day;
  final int estimatedMinutes;
  final String priority;

  const WeekLecture({
    required this.lectureId,
    required this.title,
    required this.day,
    required this.estimatedMinutes,
    required this.priority,
  });

  factory WeekLecture.fromJson(Map<String, dynamic> json) => WeekLecture(
    lectureId: json['lecture_id'] as String,
    title: json['title'] as String,
    day: (json['day'] as num).toInt(),
    estimatedMinutes: (json['estimated_minutes'] as num).toInt(),
    priority: json['priority'] as String? ?? 'medium',
  );
}

class WeekPlan {
  final int week;
  final String focus;
  final List<WeekLecture> lectures;

  const WeekPlan({required this.week, required this.focus, required this.lectures});

  factory WeekPlan.fromJson(Map<String, dynamic> json) => WeekPlan(
    week: (json['week'] as num).toInt(),
    focus: json['focus'] as String,
    lectures: (json['lectures'] as List<dynamic>? ?? [])
        .map((e) => WeekLecture.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

class Roadmap {
  final String id;
  final String overview;
  final int dailyGoalHours;
  final int estimatedDays;
  final List<WeekPlan> weeklyPlan;
  final List<String> todayLectureIds;
  final List<String> tips;

  const Roadmap({
    required this.id,
    required this.overview,
    required this.dailyGoalHours,
    required this.estimatedDays,
    required this.weeklyPlan,
    required this.todayLectureIds,
    required this.tips,
  });

  factory Roadmap.fromJson(Map<String, dynamic> json) {
    final plan = json['plan'] as Map<String, dynamic>? ?? {};
    return Roadmap(
      id: json['id'] as String? ?? '',
      overview: plan['overview'] as String? ?? '',
      dailyGoalHours: (plan['daily_goal_hours'] as num?)?.toInt() ?? 1,
      estimatedDays: (plan['estimated_completion_days'] as num?)?.toInt() ?? 30,
      weeklyPlan: (plan['weekly_plan'] as List<dynamic>? ?? [])
          .map((e) => WeekPlan.fromJson(e as Map<String, dynamic>))
          .toList(),
      todayLectureIds: (plan['today_lectures'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      tips: (plan['tips'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }
}
