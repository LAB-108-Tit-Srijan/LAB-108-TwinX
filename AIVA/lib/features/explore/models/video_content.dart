enum VideoPriority {
  high,
  medium,
  normal,
}

enum VideoCategory {
  all,
  coding,
  study,
  entertainment,
  science,
  math,
  language,
  motivation,
  technology,
}

class VideoContent {
  final String id;
  final String title;
  final String channelName;
  final String thumbnailUrl;
  final String channelAvatar;
  final String duration;
  final String views;
  final String uploadedTime;
  final VideoPriority priority;
  final List<VideoCategory> categories;
  final bool isLive;
  // Extended fields for real courses
  final String? courseId;
  final String? thumbnailColor;

  const VideoContent({
    required this.id,
    required this.title,
    required this.channelName,
    required this.thumbnailUrl,
    required this.channelAvatar,
    required this.duration,
    required this.views,
    required this.uploadedTime,
    required this.priority,
    required this.categories,
    this.isLive = false,
    this.courseId,
    this.thumbnailColor,
  });
}

// Sample video data (cleared — use real data from API)
final List<VideoContent> recommendedVideos = [];

// Category display info
Map<VideoCategory, String> categoryNames = {
  VideoCategory.all: 'All',
  VideoCategory.coding: 'Coding',
  VideoCategory.study: 'Study',
  VideoCategory.entertainment: 'Entertainment',
  VideoCategory.science: 'Science',
  VideoCategory.math: 'Math',
  VideoCategory.language: 'Language',
  VideoCategory.motivation: 'Motivation',
  VideoCategory.technology: 'Technology',
};

Map<VideoCategory, String> categoryEmojis = {
  VideoCategory.all: '🌟',
  VideoCategory.coding: '💻',
  VideoCategory.study: '📚',
  VideoCategory.entertainment: '🎬',
  VideoCategory.science: '🔬',
  VideoCategory.math: '🔢',
  VideoCategory.language: '🗣️',
  VideoCategory.motivation: '🚀',
  VideoCategory.technology: '⚡',
};

