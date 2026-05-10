import '../../../core/services/api_service.dart';
import '../../../core/models/course.dart';
import '../models/video_content.dart';

class ExploreService {
  static Future<List<Course>> fetchCourses({String? category, String? level}) async {
    try {
      String path = '/api/courses';
      final params = <String>[];
      if (category != null) params.add('category=${Uri.encodeComponent(category)}');
      if (level != null) params.add('level=${Uri.encodeComponent(level)}');
      if (params.isNotEmpty) path += '?${params.join('&')}';

      final data = await ApiService.get(path);
      if (data['success'] == true) {
        return (data['courses'] as List<dynamic>)
            .map((e) => Course.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<List<Map<String, dynamic>>> fetchLectureCards() async {
    try {
      final data = await ApiService.get('/api/lectures/published');
      if (data['success'] == true) {
        return List<Map<String, dynamic>>.from(data['lectures'] as List? ?? []);
      }
    } catch (_) {}
    return [];
  }

  static Future<List<TodayLecture>> fetchTodayLectures() async {
    try {
      if (!ApiService.hasToken) return [];
      final data = await ApiService.get('/api/roadmap/today');
      if (data['success'] == true) {
        return (data['today_lectures'] as List<dynamic>)
            .map((e) => TodayLecture.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  static VideoContent courseToVideoContent(Course course, {bool isToday = false, String priority = 'normal'}) {
    final colorHex = course.thumbnailColor.replaceAll('#', '');
    final avatarUrl = 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(course.title[0])}'
        '&background=$colorHex&color=fff&size=128';

    final priorityEnum = isToday
        ? (priority == 'high' ? VideoPriority.high : VideoPriority.medium)
        : VideoPriority.normal;

    VideoCategory cat;
    switch ((course.category ?? '').toLowerCase()) {
      case 'react':
      case 'node.js':
      case 'javascript':
      case 'typescript':
      case 'frontend':
      case 'backend':
        cat = VideoCategory.coding;
        break;
      case 'dsa':
        cat = VideoCategory.study;
        break;
      case 'python':
        cat = VideoCategory.coding;
        break;
      case 'system design':
      case 'database':
        cat = VideoCategory.technology;
        break;
      default:
        cat = VideoCategory.study;
    }

    return VideoContent(
      id: course.id,
      title: course.title,
      channelName: course.instructor ?? 'AIVA',
      thumbnailUrl: '',
      channelAvatar: avatarUrl,
      duration: '${course.estimatedHours}h',
      views: '${course.totalLectures} lectures',
      uploadedTime: course.level ?? 'Beginner',
      priority: priorityEnum,
      categories: [cat],
      courseId: course.id,
      thumbnailColor: course.thumbnailColor,
    );
  }
}

class TodayLecture {
  final String lectureId;
  final String title;
  final String courseTitle;
  final String courseId;
  final int estimatedMinutes;
  final String priority;
  final bool isCompleted;
  final String thumbnailColor;

  const TodayLecture({
    required this.lectureId,
    required this.title,
    required this.courseTitle,
    required this.courseId,
    required this.estimatedMinutes,
    required this.priority,
    required this.isCompleted,
    required this.thumbnailColor,
  });

  factory TodayLecture.fromJson(Map<String, dynamic> json) => TodayLecture(
    lectureId: json['lecture_id'] as String,
    title: json['title'] as String,
    courseTitle: json['course_title'] as String,
    courseId: json['course_id'] as String,
    estimatedMinutes: (json['estimated_minutes'] as num).toInt(),
    priority: json['priority'] as String? ?? 'medium',
    isCompleted: json['is_completed'] as bool? ?? false,
    thumbnailColor: json['thumbnail_color'] as String? ?? '#6C63FF',
  );
}
