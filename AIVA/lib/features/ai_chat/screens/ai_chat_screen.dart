import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../../../core/theme/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../models/chat_message.dart';
import 'voice_mode_screen.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  bool _showHistory = false;
  late AnimationController _typingAnimationController;

  @override
  void initState() {
    super.initState();
    _typingAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    
    // Add welcome message
    _messages.add(ChatMessage(
      id: '0',
      content: "Hello! I'm AIVA, your AI study companion. How can I help you today? 📚",
      type: MessageType.text,
      sender: MessageSender.ai,
      timestamp: DateTime.now(),
    ));
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _typingAnimationController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: text,
      type: MessageType.text,
      sender: MessageSender.user,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _isTyping = true;
    });

    _messageController.clear();
    _scrollToBottom();
    _streamAIResponse(text);
  }

  Future<void> _streamAIResponse(String userQuery) async {
    final aiMsgId = DateTime.now().millisecondsSinceEpoch.toString();
    String accumulated = '';

    try {
      final req = ApiService.buildStreamRequest('/api/ask', {'question': userQuery});
      final client = http.Client();
      final streamedResponse = await client.send(req);

      // Add an empty AI message to stream into
      setState(() {
        _isTyping = false;
        _messages.add(ChatMessage(
          id: aiMsgId,
          content: '',
          type: MessageType.text,
          sender: MessageSender.ai,
          timestamp: DateTime.now(),
        ));
      });

      final lines = streamedResponse.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      await for (final line in lines) {
        if (!mounted) break;
        if (line.startsWith('data: ')) {
          final data = line.substring(6).trim();
          if (data == '[DONE]') break;
          try {
            final json = jsonDecode(data) as Map<String, dynamic>;
            final token = json['token'] as String? ?? '';
            accumulated += token;
            setState(() {
              final idx = _messages.indexWhere((m) => m.id == aiMsgId);
              if (idx != -1) {
                _messages[idx] = ChatMessage(
                  id: aiMsgId,
                  content: accumulated,
                  type: MessageType.text,
                  sender: MessageSender.ai,
                  timestamp: _messages[idx].timestamp,
                );
              }
            });
            _scrollToBottom();
          } catch (_) {}
        }
      }

      client.close();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isTyping = false;
        final idx = _messages.indexWhere((m) => m.id == aiMsgId);
        if (idx == -1) {
          _messages.add(ChatMessage(
            id: aiMsgId,
            content: "I'm having trouble connecting. Please check your connection and try again.",
            type: MessageType.text,
            sender: MessageSender.ai,
            timestamp: DateTime.now(),
          ));
        } else if (_messages[idx].content.isEmpty) {
          _messages[idx] = ChatMessage(
            id: aiMsgId,
            content: "I'm having trouble connecting. Please check your connection and try again.",
            type: MessageType.text,
            sender: MessageSender.ai,
            timestamp: _messages[idx].timestamp,
          );
        }
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final period = time.hour >= 12 ? 'PM' : 'AM';
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final dvpw = MediaQuery.of(context).size.width;
    final dvph = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.lightBg,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(dvpw, dvph),
                Expanded(child: _buildChatList(dvpw, dvph)),
                _buildQuickActions(dvpw, dvph),
                _buildInputArea(dvpw, dvph),
              ],
            ),
            if (_showHistory) _buildHistoryDrawer(dvpw, dvph),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(double dvpw, double dvph) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dvpw * 0.04,
        vertical: dvph * 0.015,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.grayLight.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Menu button
          GestureDetector(
            onTap: () {
              setState(() {
                _showHistory = !_showHistory;
              });
            },
            child: Container(
              padding: EdgeInsets.all(dvpw * 0.025),
              decoration: BoxDecoration(
                color: AppColors.primaryDark,
                borderRadius: BorderRadius.circular(dvpw * 0.03),
              ),
              child: Icon(
                Icons.menu,
                size: dvpw * 0.055,
                color: AppColors.white,
              ),
            ),
          ),
          
          SizedBox(width: dvpw * 0.03),
          
          // AIVA logo and status
          Container(
            padding: EdgeInsets.all(dvpw * 0.022),
            decoration: BoxDecoration(
              color: AppColors.primaryLime,
              borderRadius: BorderRadius.circular(dvpw * 0.025),
            ),
            child: Icon(
              Icons.auto_awesome,
              size: dvpw * 0.05,
              color: AppColors.primaryDark,
            ),
          ),
          SizedBox(width: dvpw * 0.025),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AIVA',
                  style: GoogleFonts.lato(
                    fontSize: dvpw * 0.05,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDark,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: dvpw * 0.018,
                      height: dvpw * 0.018,
                      decoration: const BoxDecoration(
                        color: AppColors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: dvpw * 0.012),
                    Text(
                      'Online • Ready to help',
                      style: GoogleFonts.lato(
                        fontSize: dvpw * 0.03,
                        color: AppColors.gray,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // New chat button
          GestureDetector(
            onTap: () {
              setState(() {
                _messages.clear();
                _messages.add(ChatMessage(
                  id: '0',
                  content: "Hello! I'm AIVA, your AI study companion. How can I help you today? 📚",
                  type: MessageType.text,
                  sender: MessageSender.ai,
                  timestamp: DateTime.now(),
                ));
              });
            },
            child: Container(
              padding: EdgeInsets.all(dvpw * 0.025),
              decoration: BoxDecoration(
                color: AppColors.lightBg,
                borderRadius: BorderRadius.circular(dvpw * 0.03),
              ),
              child: Icon(
                Icons.add,
                size: dvpw * 0.06,
                color: AppColors.primaryDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatList(double dvpw, double dvph) {
    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.symmetric(
        horizontal: dvpw * 0.04,
        vertical: dvph * 0.02,
      ),
      itemCount: _messages.length + (_isTyping ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length && _isTyping) {
          return _buildTypingIndicator(dvpw, dvph);
        }
        return _buildMessageBubble(_messages[index], dvpw, dvph);
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message, double dvpw, double dvph) {
    final isUser = message.sender == MessageSender.user;
    
    return Padding(
      padding: EdgeInsets.only(bottom: dvph * 0.02),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            // AI Avatar
            Container(
              width: dvpw * 0.1,
              height: dvpw * 0.1,
              decoration: BoxDecoration(
                color: AppColors.primaryLime,
                borderRadius: BorderRadius.circular(dvpw * 0.03),
              ),
              child: Icon(
                Icons.auto_awesome,
                size: dvpw * 0.055,
                color: AppColors.primaryDark,
              ),
            ),
            SizedBox(width: dvpw * 0.025),
          ],
          
          // Message bubble
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: BoxConstraints(maxWidth: dvpw * 0.72),
                  padding: EdgeInsets.all(dvpw * 0.04),
                  decoration: BoxDecoration(
                    color: isUser ? AppColors.primaryDark : AppColors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(dvpw * 0.05),
                      topRight: Radius.circular(dvpw * 0.05),
                      bottomLeft: Radius.circular(isUser ? dvpw * 0.05 : dvpw * 0.01),
                      bottomRight: Radius.circular(isUser ? dvpw * 0.01 : dvpw * 0.05),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.gray.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: _buildFormattedText(
                    message.content,
                    isUser,
                    dvpw,
                  ),
                ),
                SizedBox(height: dvph * 0.005),
                Text(
                  _formatTime(message.timestamp),
                  style: GoogleFonts.lato(
                    fontSize: dvpw * 0.028,
                    color: AppColors.gray,
                  ),
                ),
              ],
            ),
          ),
          
          if (isUser) ...[
            SizedBox(width: dvpw * 0.025),
            // User Avatar
            Container(
              width: dvpw * 0.1,
              height: dvpw * 0.1,
              decoration: BoxDecoration(
                color: AppColors.green,
                borderRadius: BorderRadius.circular(dvpw * 0.03),
              ),
              child: Icon(
                Icons.person,
                size: dvpw * 0.055,
                color: AppColors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFormattedText(String text, bool isUser, double dvpw) {
    final textColor = isUser ? AppColors.white : AppColors.primaryDark;
    final lines = text.split('\n');
    List<Widget> widgets = [];
    
    for (var line in lines) {
      if (line.startsWith('• ')) {
        widgets.add(
          Padding(
            padding: EdgeInsets.only(bottom: dvpw * 0.015),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• ', style: GoogleFonts.lato(
                  fontSize: dvpw * 0.038, 
                  color: textColor,
                  height: 1.4,
                )),
                Expanded(child: _buildRichText(line.substring(2), textColor, dvpw)),
              ],
            ),
          ),
        );
      } else if (line.isEmpty) {
        widgets.add(SizedBox(height: dvpw * 0.025));
      } else {
        widgets.add(
          Padding(
            padding: EdgeInsets.only(bottom: dvpw * 0.015),
            child: _buildRichText(line, textColor, dvpw),
          ),
        );
      }
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  Widget _buildRichText(String text, Color color, double dvpw) {
    List<TextSpan> spans = [];
    final regex = RegExp(r'\*\*(.*?)\*\*');
    int lastEnd = 0;
    
    for (var match in regex.allMatches(text)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style: GoogleFonts.lato(
            fontSize: dvpw * 0.038, 
            color: color, 
            height: 1.4,
          ),
        ));
      }
      spans.add(TextSpan(
        text: match.group(1),
        style: GoogleFonts.lato(
          fontSize: dvpw * 0.038,
          fontWeight: FontWeight.w700,
          color: color,
          height: 1.4,
        ),
      ));
      lastEnd = match.end;
    }
    
    if (lastEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastEnd),
        style: GoogleFonts.lato(
          fontSize: dvpw * 0.038, 
          color: color, 
          height: 1.4,
        ),
      ));
    }
    
    return RichText(text: TextSpan(children: spans));
  }

  Widget _buildTypingIndicator(double dvpw, double dvph) {
    return Padding(
      padding: EdgeInsets.only(bottom: dvph * 0.02),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: dvpw * 0.1,
            height: dvpw * 0.1,
            decoration: BoxDecoration(
              color: AppColors.primaryLime,
              borderRadius: BorderRadius.circular(dvpw * 0.03),
            ),
            child: Icon(
              Icons.auto_awesome,
              size: dvpw * 0.055,
              color: AppColors.primaryDark,
            ),
          ),
          SizedBox(width: dvpw * 0.025),
          Container(
            padding: EdgeInsets.all(dvpw * 0.04),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(dvpw * 0.05),
                topRight: Radius.circular(dvpw * 0.05),
                bottomLeft: Radius.circular(dvpw * 0.01),
                bottomRight: Radius.circular(dvpw * 0.05),
              ),
            ),
            child: AnimatedBuilder(
              animation: _typingAnimationController,
              builder: (context, child) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (index) {
                    final delay = index * 0.2;
                    final value = (_typingAnimationController.value + delay) % 1.0;
                    final opacity = (value < 0.5 ? value : 1.0 - value) * 2;
                    return Container(
                      margin: EdgeInsets.symmetric(horizontal: dvpw * 0.01),
                      width: dvpw * 0.025,
                      height: dvpw * 0.025,
                      decoration: BoxDecoration(
                        color: AppColors.gray.withOpacity(0.3 + (opacity * 0.7)),
                        shape: BoxShape.circle,
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(double dvpw, double dvph) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: dvph * 0.012),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: dvpw * 0.04),
        child: Row(
          children: [
            _buildQuickActionChip(Icons.image_outlined, 'Image', dvpw),
            SizedBox(width: dvpw * 0.02),
            _buildQuickActionChip(Icons.attach_file, 'File', dvpw),
            SizedBox(width: dvpw * 0.02),
            _buildQuickActionChip(Icons.quiz_outlined, 'Quiz me', dvpw),
            SizedBox(width: dvpw * 0.02),
            _buildQuickActionChip(Icons.summarize_outlined, 'Summarize', dvpw),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionChip(IconData icon, String label, double dvpw) {
    return GestureDetector(
      onTap: () {
        if (label == 'Quiz me') {
          _messageController.text = 'Create a quiz for me on ';
        } else if (label == 'Summarize') {
          _messageController.text = 'Summarize this topic: ';
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: dvpw * 0.04,
          vertical: dvpw * 0.028,
        ),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(dvpw * 0.06),
          border: Border.all(color: AppColors.grayLight, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: dvpw * 0.05, color: AppColors.primaryDark),
            SizedBox(width: dvpw * 0.02),
            Text(
              label,
              style: GoogleFonts.lato(
                fontSize: dvpw * 0.035,
                fontWeight: FontWeight.w500,
                color: AppColors.primaryDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea(double dvpw, double dvph) {
    return Container(
      padding: EdgeInsets.all(dvpw * 0.04),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.grayLight.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Text input
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: dvpw * 0.04),
              decoration: BoxDecoration(
                color: AppColors.lightBg,
                borderRadius: BorderRadius.circular(dvpw * 0.06),
                border: Border.all(color: AppColors.grayLight, width: 1),
              ),
              child: TextField(
                controller: _messageController,
                maxLines: 3,
                minLines: 1,
                textAlignVertical: TextAlignVertical.center,
                style: GoogleFonts.lato(
                  fontSize: dvpw * 0.04,
                  color: AppColors.primaryDark,
                ),
                decoration: InputDecoration(
                  hintText: 'Ask AIVA anything...',
                  hintStyle: GoogleFonts.lato(
                    fontSize: dvpw * 0.04,
                    color: AppColors.gray,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: dvph * 0.015),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          
          SizedBox(width: dvpw * 0.025),
          
          // Voice button
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const VoiceModeScreen()),
              );
            },
            child: Container(
              padding: EdgeInsets.all(dvpw * 0.035),
              decoration: BoxDecoration(
                color: AppColors.primaryLime,
                borderRadius: BorderRadius.circular(dvpw * 0.035),
              ),
              child: Icon(
                Icons.mic,
                size: dvpw * 0.06,
                color: AppColors.primaryDark,
              ),
            ),
          ),
          
          SizedBox(width: dvpw * 0.02),
          
          // Send button
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              padding: EdgeInsets.all(dvpw * 0.035),
              decoration: BoxDecoration(
                color: AppColors.primaryLime,
                borderRadius: BorderRadius.circular(dvpw * 0.035),
              ),
              child: Icon(
                Icons.send,
                size: dvpw * 0.06,
                color: AppColors.primaryDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryDrawer(double dvpw, double dvph) {
    return GestureDetector(
      onTap: () => setState(() => _showHistory = false),
      child: Container(
        color: Colors.black.withOpacity(0.3),
        child: Align(
          alignment: Alignment.centerLeft,
          child: GestureDetector(
            onTap: () {},
            child: Container(
              width: dvpw * 0.8,
              height: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.white,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryDark.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(5, 0),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(dvpw * 0.05),
                    decoration: const BoxDecoration(
                      gradient: AppColors.darkGradient,
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(dvpw * 0.025),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLime,
                              borderRadius: BorderRadius.circular(dvpw * 0.03),
                            ),
                            child: Icon(
                              Icons.history,
                              size: dvpw * 0.06,
                              color: AppColors.primaryDark,
                            ),
                          ),
                          SizedBox(width: dvpw * 0.03),
                          Expanded(
                            child: Text(
                              'Chat History',
                              style: GoogleFonts.lato(
                                fontSize: dvpw * 0.05,
                                fontWeight: FontWeight.w700,
                                color: AppColors.white,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => setState(() => _showHistory = false),
                            child: Icon(
                              Icons.close,
                              size: dvpw * 0.06,
                              color: AppColors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: EdgeInsets.all(dvpw * 0.04),
                      itemCount: sampleConversations.length,
                      itemBuilder: (context, index) {
                        final conv = sampleConversations[index];
                        return Container(
                          margin: EdgeInsets.only(bottom: dvph * 0.015),
                          padding: EdgeInsets.all(dvpw * 0.04),
                          decoration: BoxDecoration(
                            color: AppColors.lightBg,
                            borderRadius: BorderRadius.circular(dvpw * 0.03),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.chat_bubble_outline,
                                size: dvpw * 0.05,
                                color: AppColors.gray,
                              ),
                              SizedBox(width: dvpw * 0.03),
                              Expanded(
                                child: Text(
                                  conv.title,
                                  style: GoogleFonts.lato(
                                    fontSize: dvpw * 0.038,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.primaryDark,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
