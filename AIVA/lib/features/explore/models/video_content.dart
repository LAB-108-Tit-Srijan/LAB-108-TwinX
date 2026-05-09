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
  });
}

// Sample video data for recommendations
final List<VideoContent> recommendedVideos = [
  VideoContent(
    id: '1',
    title: 'Complete Flutter Course 2024 - Build 10 Real Apps',
    channelName: 'Code Academy',
    thumbnailUrl: 'https://images.unsplash.com/photo-1517694712202-14dd9538aa97?w=800&q=80',
    channelAvatar: 'https://ui-avatars.com/api/?name=CA&background=BBF246&color=192126',
    duration: '12:45:30',
    views: '2.5M views',
    uploadedTime: '2 days ago',
    priority: VideoPriority.high,
    categories: [VideoCategory.coding, VideoCategory.technology],
  ),
  VideoContent(
    id: '2',
    title: 'Quantum Physics Explained - Simple Guide for Students',
    channelName: 'Science Hub',
    thumbnailUrl: 'https://images.unsplash.com/photo-1635070041078-e363dbe005cb?w=800&q=80',
    channelAvatar: 'https://ui-avatars.com/api/?name=SH&background=8B5CF6&color=FFFFFF',
    duration: '28:15',
    views: '890K views',
    uploadedTime: '1 week ago',
    priority: VideoPriority.high,
    categories: [VideoCategory.science, VideoCategory.study],
  ),
  VideoContent(
    id: '3',
    title: 'Study With Me - 3 Hour Deep Focus Session',
    channelName: 'Study Vibes',
    thumbnailUrl: 'https://images.unsplash.com/photo-1434030216411-0b793f4b4173?w=800&q=80',
    channelAvatar: 'https://ui-avatars.com/api/?name=SV&background=10B981&color=FFFFFF',
    duration: '3:00:00',
    views: '1.2M views',
    uploadedTime: '3 days ago',
    priority: VideoPriority.medium,
    categories: [VideoCategory.study, VideoCategory.motivation],
    isLive: true,
  ),
  VideoContent(
    id: '4',
    title: 'Data Structures & Algorithms - Full Course',
    channelName: 'Tech Master',
    thumbnailUrl: 'https://images.unsplash.com/photo-1515879218367-8466d910aaa4?w=800&q=80',
    channelAvatar: 'https://ui-avatars.com/api/?name=TM&background=3B82F6&color=FFFFFF',
    duration: '8:30:00',
    views: '3.1M views',
    uploadedTime: '1 month ago',
    priority: VideoPriority.high,
    categories: [VideoCategory.coding, VideoCategory.study],
  ),
  VideoContent(
    id: '5',
    title: 'How AI is Changing Education Forever',
    channelName: 'Future Tech',
    thumbnailUrl: 'https://images.unsplash.com/photo-1677442136019-21780ecad995?w=800&q=80',
    channelAvatar: 'https://ui-avatars.com/api/?name=FT&background=F59E0B&color=FFFFFF',
    duration: '18:42',
    views: '456K views',
    uploadedTime: '5 days ago',
    priority: VideoPriority.medium,
    categories: [VideoCategory.technology, VideoCategory.study],
  ),
  VideoContent(
    id: '6',
    title: 'Math Tricks - Solve Any Problem in Seconds',
    channelName: 'Math Wizard',
    thumbnailUrl: 'https://images.unsplash.com/photo-1509228468518-180dd4864904?w=800&q=80',
    channelAvatar: 'https://ui-avatars.com/api/?name=MW&background=EF4444&color=FFFFFF',
    duration: '15:28',
    views: '789K views',
    uploadedTime: '2 weeks ago',
    priority: VideoPriority.normal,
    categories: [VideoCategory.math, VideoCategory.study],
  ),
  VideoContent(
    id: '7',
    title: 'Python for Beginners - Complete Tutorial',
    channelName: 'Code Academy',
    thumbnailUrl: 'https://images.unsplash.com/photo-1526379095098-d400fd0bf935?w=800&q=80',
    channelAvatar: 'https://ui-avatars.com/api/?name=CA&background=BBF246&color=192126',
    duration: '6:15:00',
    views: '5.2M views',
    uploadedTime: '3 months ago',
    priority: VideoPriority.high,
    categories: [VideoCategory.coding, VideoCategory.technology],
  ),
  VideoContent(
    id: '8',
    title: 'English Speaking Practice - Daily Conversations',
    channelName: 'Language Lab',
    thumbnailUrl: 'https://images.unsplash.com/photo-1503676260728-1c00da094a0b?w=800&q=80',
    channelAvatar: 'https://ui-avatars.com/api/?name=LL&background=14B8A6&color=FFFFFF',
    duration: '45:30',
    views: '1.8M views',
    uploadedTime: '1 week ago',
    priority: VideoPriority.medium,
    categories: [VideoCategory.language, VideoCategory.study],
  ),
  VideoContent(
    id: '9',
    title: 'Top 10 Productivity Apps for Students 2024',
    channelName: 'Student Life',
    thumbnailUrl: 'https://images.unsplash.com/photo-1484480974693-6ca0a78fb36b?w=800&q=80',
    channelAvatar: 'https://ui-avatars.com/api/?name=SL&background=8B5CF6&color=FFFFFF',
    duration: '12:15',
    views: '234K views',
    uploadedTime: '4 days ago',
    priority: VideoPriority.normal,
    categories: [VideoCategory.technology, VideoCategory.motivation],
  ),
  VideoContent(
    id: '10',
    title: 'Relaxing Music for Studying - Focus Enhancement',
    channelName: 'Chill Beats',
    thumbnailUrl: 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=800&q=80',
    channelAvatar: 'https://ui-avatars.com/api/?name=CB&background=60A5FA&color=FFFFFF',
    duration: '2:00:00',
    views: '4.5M views',
    uploadedTime: '2 months ago',
    priority: VideoPriority.normal,
    categories: [VideoCategory.entertainment, VideoCategory.study],
  ),
  VideoContent(
    id: '11',
    title: 'Machine Learning Crash Course - From Zero to Hero',
    channelName: 'AI Academy',
    thumbnailUrl: 'https://images.unsplash.com/photo-1555949963-aa79dcee981c?w=800&q=80',
    channelAvatar: 'https://ui-avatars.com/api/?name=AA&background=BBF246&color=192126',
    duration: '4:30:00',
    views: '1.9M views',
    uploadedTime: '2 weeks ago',
    priority: VideoPriority.high,
    categories: [VideoCategory.coding, VideoCategory.technology, VideoCategory.science],
  ),
  VideoContent(
    id: '12',
    title: 'Chemistry Experiments You Can Do at Home',
    channelName: 'Science Fun',
    thumbnailUrl: 'https://images.unsplash.com/photo-1532094349884-543bc11b234d?w=800&q=80',
    channelAvatar: 'https://ui-avatars.com/api/?name=SF&background=10B981&color=FFFFFF',
    duration: '22:45',
    views: '567K views',
    uploadedTime: '6 days ago',
    priority: VideoPriority.medium,
    categories: [VideoCategory.science, VideoCategory.entertainment],
  ),
];

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

