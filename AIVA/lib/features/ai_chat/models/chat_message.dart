enum MessageType {
  text,
  image,
  voice,
}

enum MessageSender {
  user,
  ai,
}

class ChatMessage {
  final String id;
  final String content;
  final MessageType type;
  final MessageSender sender;
  final DateTime timestamp;
  final String? imageUrl;
  final bool isLoading;

  ChatMessage({
    required this.id,
    required this.content,
    required this.type,
    required this.sender,
    required this.timestamp,
    this.imageUrl,
    this.isLoading = false,
  });

  ChatMessage copyWith({
    String? id,
    String? content,
    MessageType? type,
    MessageSender? sender,
    DateTime? timestamp,
    String? imageUrl,
    bool? isLoading,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      type: type ?? this.type,
      sender: sender ?? this.sender,
      timestamp: timestamp ?? this.timestamp,
      imageUrl: imageUrl ?? this.imageUrl,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class ChatConversation {
  final String id;
  final String title;
  final List<ChatMessage> messages;
  final DateTime createdAt;
  final DateTime lastMessageAt;

  ChatConversation({
    required this.id,
    required this.title,
    required this.messages,
    required this.createdAt,
    required this.lastMessageAt,
  });
}

// Sample chat history
final List<ChatConversation> sampleConversations = [
  ChatConversation(
    id: '1',
    title: 'Physics Homework Help',
    messages: [],
    createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    lastMessageAt: DateTime.now().subtract(const Duration(hours: 2)),
  ),
  ChatConversation(
    id: '2',
    title: 'Math Problem Solving',
    messages: [],
    createdAt: DateTime.now().subtract(const Duration(days: 1)),
    lastMessageAt: DateTime.now().subtract(const Duration(days: 1)),
  ),
  ChatConversation(
    id: '3',
    title: 'Essay Writing Tips',
    messages: [],
    createdAt: DateTime.now().subtract(const Duration(days: 2)),
    lastMessageAt: DateTime.now().subtract(const Duration(days: 2)),
  ),
  ChatConversation(
    id: '4',
    title: 'Chemistry Concepts',
    messages: [],
    createdAt: DateTime.now().subtract(const Duration(days: 3)),
    lastMessageAt: DateTime.now().subtract(const Duration(days: 3)),
  ),
  ChatConversation(
    id: '5',
    title: 'History Quiz Prep',
    messages: [],
    createdAt: DateTime.now().subtract(const Duration(days: 5)),
    lastMessageAt: DateTime.now().subtract(const Duration(days: 5)),
  ),
];

