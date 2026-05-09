class OnboardingContent {
  final String titleLine1;
  final String highlightedWord;
  final String titleLine2;
  final String description;
  final String imageUrl;

  const OnboardingContent({
    required this.titleLine1,
    required this.highlightedWord,
    required this.titleLine2,
    required this.description,
    required this.imageUrl,
  });
}

final List<OnboardingContent> onboardingData = [
  const OnboardingContent(
    titleLine1: 'Wherever You Are',
    highlightedWord: 'Learning',
    titleLine2: 'Is Number One',
    description: 'Start your journey to knowledge with your AI study companion',
    imageUrl: 'https://images.unsplash.com/photo-1542393545-10f5cde2c810?w=800&q=80',
  ),
  const OnboardingContent(
    titleLine1: 'Track Your',
    highlightedWord: 'Progress',
    titleLine2: 'With Ease',
    description: 'Monitor your study sessions and achieve your academic goals',
    imageUrl: 'https://images.unsplash.com/photo-1493612276216-ee3925520721?w=800&q=80',
  ),
  const OnboardingContent(
    titleLine1: 'Join Our',
    highlightedWord: 'Study',
    titleLine2: 'Community',
    description: 'Connect with learners and get AI-powered assistance anytime',
    imageUrl: 'https://images.unsplash.com/photo-1581078426770-6d336e5de7bf?w=800&q=80',
  ),
];
