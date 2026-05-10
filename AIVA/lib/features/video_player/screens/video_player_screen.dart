import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:video_player/video_player.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/quiz_service.dart';
import '../../../core/services/chat_history_service.dart';
import '../../../core/services/student_notes_service.dart';
import '../widgets/quiz_modal.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String lectureId;
  final String title;
  final String courseId;

  const VideoPlayerScreen({
    super.key,
    required this.lectureId,
    required this.title,
    required this.courseId,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen>
    with TickerProviderStateMixin {
  VideoPlayerController? _controller;
  late TabController _tabController;
  bool _isInitialized = false;
  bool _showControls = true;
  bool _isFullscreen = false;
  bool _titleExpanded = false;
  Timer? _hideControlsTimer;
  Timer? _progressTimer;
  int _lastReportedSeconds = 0;
  bool _quizTriggered = false;

  // Tab data
  List<Map<String, dynamic>> _transcript = [];
  List<Map<String, dynamic>> _chapters = [];
  String? _summaryFull;
  bool _transcriptLoading = true;
  bool _summaryLoading = true;

  // Caption + transcript scroll state
  bool _showCaptions = true;
  bool _autoScrollTranscript = true;
  bool _programmaticScrolling = false;
  Timer? _userScrollTimer;

  // Student notes
  String? _notesContent;
  bool _notesLoading = true;

  // AIVA chat state
  final List<Map<String, dynamic>> _chatMessages = [];
  final TextEditingController _chatInput = TextEditingController();
  final FocusNode _chatFocusNode = FocusNode();
  bool _chatLoading = false;
  final ScrollController _chatScrollController = ScrollController();
  final ScrollController _transcriptScrollController = ScrollController();

  static const List<String> _quickQuestions = [
    'Summarize this lecture',
    'Explain in simple terms',
    'What are the key points?',
    'Give me examples',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initVideo();
    _loadTranscript();
    _loadSummary();
    _loadChatHistory();
    _loadNotes();

    // Detect when user manually scrolls the transcript — pause auto-scroll briefly
    _transcriptScrollController.addListener(() {
      if (!_programmaticScrolling && _autoScrollTranscript) {
        setState(() => _autoScrollTranscript = false);
        _userScrollTimer?.cancel();
        _userScrollTimer = Timer(const Duration(seconds: 6), () {
          if (mounted) setState(() => _autoScrollTranscript = true);
        });
      }
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    _hideControlsTimer?.cancel();
    _progressTimer?.cancel();
    _userScrollTimer?.cancel();
    _tabController.dispose();
    _chatInput.dispose();
    _chatFocusNode.dispose();
    _chatScrollController.dispose();
    _transcriptScrollController.dispose();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  Future<void> _initVideo() async {
    final videoUrl = '${ApiService.kBaseUrl}/api/video/${widget.lectureId}/stream';
    _controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
    try {
      await _controller!.initialize();
      _controller!.addListener(_onVideoProgress);
      _progressTimer = Timer.periodic(const Duration(seconds: 10), (_) => _reportProgress());
      if (mounted) setState(() => _isInitialized = true);
      _startHideControlsTimer();
    } catch (_) {
      if (mounted) setState(() => _isInitialized = false);
    }
  }

  void _onVideoProgress() {
    if (!mounted) return;
    final pos = _controller?.value.position.inSeconds ?? 0;
    if ((pos - _lastReportedSeconds).abs() >= 10) _reportProgress();

    if (!_quizTriggered && _isInitialized && _controller != null) {
      final total = _controller!.value.duration.inSeconds;
      if (total > 0 && pos / total >= 0.9) {
        _quizTriggered = true;
        _tryTriggerQuiz();
      }
    }

    setState(() {});

    // Auto-scroll transcript to active chunk (only when user isn't manually scrolling)
    if (_autoScrollTranscript && _transcript.isNotEmpty && _tabController.index == 1) {
      final activeIdx = _findActiveChunkIndex();
      if (activeIdx >= 0 && _transcriptScrollController.hasClients) {
        final fraction = activeIdx / _transcript.length;
        final target = (fraction * _transcriptScrollController.position.maxScrollExtent)
            .clamp(0.0, _transcriptScrollController.position.maxScrollExtent);
        _programmaticScrolling = true;
        _transcriptScrollController
            .animateTo(target,
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOut)
            .then((_) => _programmaticScrolling = false);
      }
    }
  }

  Future<void> _tryTriggerQuiz({bool manual = false}) async {
    try {
      final quizData = await QuizService.getQuiz(widget.lectureId);
      if (!mounted) return;
      final quiz = quizData['quiz'] as Map<String, dynamic>?;
      final questions = quiz?['questions'] as List<dynamic>?;
      if (quizData['success'] == true && (questions?.isNotEmpty == true)) {
        _controller?.pause();
        if (!mounted) return;
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => QuizModal(lectureId: widget.lectureId, questions: questions!),
        );
      } else if (manual) {
        // Show feedback to user when triggered manually and quiz isn't ready
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(quizData['error']?.toString() ?? 'Quiz not available yet — try again after the lecture is fully processed.'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ));
        }
        // Reset so auto-trigger can fire again next time
        setState(() => _quizTriggered = false);
      } else {
        // Auto-trigger failed (transcript not ready, etc.) — reset so we can retry
        setState(() => _quizTriggered = false);
      }
    } catch (e) {
      if (manual && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Could not load quiz. Please check your connection and try again.'),
          behavior: SnackBarBehavior.floating,
        ));
      }
      setState(() => _quizTriggered = false);
    }
  }

  Future<void> _reportProgress() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    final watched = _controller!.value.position.inSeconds;
    final total = _controller!.value.duration.inSeconds;
    if (watched == _lastReportedSeconds) return;
    _lastReportedSeconds = watched;
    try {
      await ApiService.post('/api/progress/update', {
        'lecture_id': widget.lectureId,
        'course_id': widget.courseId,
        'watched_seconds': watched,
        'total_seconds': total,
      });
    } catch (_) {}
  }

  Future<void> _loadTranscript() async {
    try {
      final data = await ApiService.get('/api/lectures/${widget.lectureId}/transcript');
      if (data['success'] == true && mounted) {
        setState(() {
          _transcript = List<Map<String, dynamic>>.from(data['transcript'] as List? ?? []);
          _transcriptLoading = false;
        });
      } else {
        if (mounted) setState(() => _transcriptLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _transcriptLoading = false);
    }
  }

  Future<void> _loadSummary() async {
    try {
      final data = await ApiService.get('/api/lectures/${widget.lectureId}/summary');
      if (data['success'] == true && mounted) {
        setState(() {
          _summaryFull = data['summary_full'] as String?;
          _chapters = List<Map<String, dynamic>>.from(data['chapters'] as List? ?? []);
          _summaryLoading = false;
        });
      } else {
        if (mounted) setState(() => _summaryLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _summaryLoading = false);
    }
  }

  Future<void> _loadChatHistory() async {
    if (!ApiService.hasToken) return;
    final history = await ChatHistoryService.getHistory(widget.lectureId);
    if (!mounted) return;
    setState(() {
      for (final item in history) {
        _chatMessages.add({'role': 'user', 'text': item['question']?.toString() ?? ''});
        _chatMessages.add({'role': 'aiva', 'text': item['answer']?.toString() ?? ''});
      }
    });
  }

  Future<void> _loadNotes() async {
    if (!ApiService.hasToken) {
      if (mounted) setState(() => _notesLoading = false);
      return;
    }
    try {
      final notes = await StudentNotesService.getNotes(widget.lectureId);
      if (mounted) {
        setState(() {
          _notesContent = notes?['content'] as String?;
          _notesLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _notesLoading = false);
    }
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _controller?.value.isPlaying == true) {
        setState(() => _showControls = false);
      }
    });
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) _startHideControlsTimer();
  }

  void _togglePlayPause() {
    if (_controller == null) return;
    if (_controller!.value.isPlaying) {
      _controller!.pause();
      setState(() => _showControls = true);
      _hideControlsTimer?.cancel();
    } else {
      _controller!.play();
      _startHideControlsTimer();
    }
    setState(() {});
  }

  void _seekRelative(int seconds) {
    if (_controller == null) return;
    final current = _controller!.value.position;
    final duration = _controller!.value.duration;
    final target = current + Duration(seconds: seconds);
    _controller!.seekTo(target.isNegative ? Duration.zero : (target > duration ? duration : target));
    _startHideControlsTimer();
  }

  void _toggleFullscreen() {
    setState(() => _isFullscreen = !_isFullscreen);
    if (_isFullscreen) {
      SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  Future<void> _sendMessage([String? prefilled]) async {
    final text = (prefilled ?? _chatInput.text).trim();
    if (text.isEmpty || _chatLoading) return;
    _chatInput.clear();
    _chatFocusNode.unfocus(); // dismiss keyboard

    final currentPos = _controller?.value.position.inSeconds ?? 0;
    setState(() {
      _chatMessages.add({'role': 'user', 'text': text});
      _chatLoading = true;
    });

    _scrollChatToBottom();

    String responseText = '';

    try {
      final req = ApiService.buildStreamRequest('/api/ask', {
        'lecture_id': widget.lectureId,
        'question': text,
        'language': RegExp(r'[ऀ-ॿ]').hasMatch(text) ? 'hi' : 'en',
        'current_timestamp': currentPos,
        'chat_history': _chatMessages.where((m) => m['role'] == 'user').take(5).map((m) => {'role': 'user', 'content': m['text']}).toList(),
      });

      final client = await req.send();
      final stream = client.stream.transform(const Utf8Decoder()).transform(const LineSplitter());

      int aiIndex = -1;

      await for (final line in stream) {
        if (line.startsWith('data: ')) {
          try {
            final json = jsonDecode(line.substring(6)) as Map<String, dynamic>;
            if (json['type'] == 'delta') {
              responseText += json['text'] as String? ?? '';
              if (mounted) {
                setState(() {
                  if (aiIndex == -1) {
                    _chatMessages.add({'role': 'aiva', 'text': responseText});
                    aiIndex = _chatMessages.length - 1;
                  } else {
                    _chatMessages[aiIndex] = {'role': 'aiva', 'text': responseText};
                  }
                });
                _scrollChatToBottom();
              }
            } else if (json['type'] == 'done') {
              break;
            }
          } catch (_) {}
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _chatMessages.add({'role': 'aiva', 'text': 'Sorry, I couldn\'t get a response. Please try again.'});
        });
      }
      return;
    } finally {
      if (mounted) setState(() => _chatLoading = false);
      _scrollChatToBottom();
    }

    // Save Q&A to backend and refresh notes (fire-and-forget)
    if (responseText.isNotEmpty && ApiService.hasToken) {
      final lang = RegExp(r'[ऀ-ॿ]').hasMatch(text) ? 'hi' : 'en';
      ChatHistoryService.save(
        lectureId: widget.lectureId,
        question: text,
        answer: responseText,
        language: lang,
      ).then((_) => _loadNotes());
    }
  }

  void _scrollChatToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    if (_isFullscreen) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(child: _buildVideoSection(w, h)),
      );
    }

    // When the keyboard is open AND the user is on the AIVA chat tab,
    // collapse the video + info panel so the chat fills the whole screen.
    // resizeToAvoidBottomInset:true (default) then shrinks the Scaffold body
    // by the keyboard height, and the chat column fits perfectly.
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 50;
    final onChatTab = _tabController.index == 0;
    final chatFocused = keyboardOpen && onChatTab;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            if (!chatFocused) _buildVideoSection(w, h),
            Expanded(
              child: Column(
                children: [
                  if (!chatFocused) _buildInfoPanel(w, h),
                  _buildTabBar(w, h),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildAIVATab(w, h),
                        _buildTranscriptTab(w, h),
                        _buildSummaryTab(w, h),
                        _buildNotesTab(w, h),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Video Player ──────────────────────────────────────────────────────────

  Widget _buildVideoSection(double w, double h) {
    final videoH = _isFullscreen ? h : w * 9 / 16;
    return GestureDetector(
      onTap: _toggleControls,
      child: Container(
        width: double.infinity,
        height: videoH,
        color: Colors.black,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (_isInitialized && _controller != null)
              Center(
                child: AspectRatio(
                  aspectRatio: _controller!.value.aspectRatio,
                  child: VideoPlayer(_controller!),
                ),
              )
            else
              const Center(
                child: CircularProgressIndicator(color: AppColors.primaryLime, strokeWidth: 2),
              ),

            // Controls overlay
            AnimatedOpacity(
              opacity: _showControls ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: _buildControlsOverlay(w, videoH),
            ),

            // Caption overlay (only when CC enabled, controls hidden, transcript ready)
            if (_showCaptions && !_showControls && _transcript.isNotEmpty && _isInitialized)
              Positioned(
                bottom: w * 0.05,
                left: w * 0.05,
                right: w * 0.05,
                child: _buildCaptionOverlay(w),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlsOverlay(double w, double videoH) {
    return Container(
      width: double.infinity,
      height: videoH,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black54, Colors.transparent, Colors.transparent, Colors.black87],
          stops: [0, 0.25, 0.7, 1],
        ),
      ),
      child: Column(
        children: [
          // Top bar
          Padding(
            padding: EdgeInsets.fromLTRB(w * 0.03, w * 0.03, w * 0.03, 0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () { _reportProgress(); Navigator.pop(context); },
                  child: Container(
                    padding: EdgeInsets.all(w * 0.02),
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(w * 0.02),
                    ),
                    child: Icon(Icons.arrow_back_rounded, color: Colors.white, size: w * 0.05),
                  ),
                ),
                SizedBox(width: w * 0.03),
                Expanded(
                  child: Text(
                    widget.title,
                    style: GoogleFonts.lato(fontSize: w * 0.034, fontWeight: FontWeight.w600, color: Colors.white),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // CC toggle
                GestureDetector(
                  onTap: () => setState(() => _showCaptions = !_showCaptions),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: w * 0.02, vertical: w * 0.012),
                    decoration: BoxDecoration(
                      color: _showCaptions ? AppColors.primaryLime : Colors.white24,
                      borderRadius: BorderRadius.circular(w * 0.015),
                    ),
                    child: Text(
                      'CC',
                      style: GoogleFonts.lato(
                        fontSize: w * 0.026,
                        fontWeight: FontWeight.w800,
                        color: _showCaptions ? AppColors.primaryDark : Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          // Center controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _controlButton(Icons.replay_10_rounded, w * 0.09, () => _seekRelative(-10)),
              SizedBox(width: w * 0.07),
              GestureDetector(
                onTap: _togglePlayPause,
                child: Container(
                  padding: EdgeInsets.all(w * 0.035),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white38, width: 2),
                  ),
                  child: Icon(
                    _controller?.value.isPlaying == true ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: w * 0.09,
                  ),
                ),
              ),
              SizedBox(width: w * 0.07),
              _controlButton(Icons.forward_10_rounded, w * 0.09, () => _seekRelative(10)),
            ],
          ),

          const Spacer(),

          // Progress bar + time
          Padding(
            padding: EdgeInsets.fromLTRB(w * 0.03, 0, w * 0.03, w * 0.02),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isInitialized && _controller != null)
                  SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: AppColors.primaryLime,
                      inactiveTrackColor: Colors.white24,
                      thumbColor: AppColors.primaryLime,
                      overlayColor: AppColors.primaryLime.withOpacity(0.2),
                      thumbShape: RoundSliderThumbShape(enabledThumbRadius: w * 0.018),
                      trackHeight: 3,
                      overlayShape: RoundSliderOverlayShape(overlayRadius: w * 0.04),
                    ),
                    child: Slider(
                      value: _controller!.value.position.inMilliseconds.toDouble(),
                      min: 0,
                      max: _controller!.value.duration.inMilliseconds.toDouble().clamp(1, double.infinity),
                      onChanged: (v) {
                        _controller!.seekTo(Duration(milliseconds: v.toInt()));
                        _startHideControlsTimer();
                      },
                    ),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _isInitialized ? _formatDuration(_controller!.value.position) : '0:00',
                      style: GoogleFonts.lato(color: Colors.white, fontSize: w * 0.03, fontWeight: FontWeight.w600),
                    ),
                    GestureDetector(
                      onTap: _toggleFullscreen,
                      child: Container(
                        padding: EdgeInsets.all(w * 0.015),
                        child: Icon(
                          _isFullscreen ? Icons.fullscreen_exit_rounded : Icons.fullscreen_rounded,
                          color: Colors.white,
                          size: w * 0.055,
                        ),
                      ),
                    ),
                    Text(
                      _isInitialized ? _formatDuration(_controller!.value.duration) : '0:00',
                      style: GoogleFonts.lato(color: Colors.white54, fontSize: w * 0.03),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _controlButton(IconData icon, double size, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(icon, color: Colors.white, size: size),
    );
  }

  Widget _buildCaptionOverlay(double w) {
    final pos = _controller?.value.position.inSeconds.toDouble() ?? 0;
    final activeIdx = _findActiveChunkIndex();
    if (activeIdx < 0) return const SizedBox.shrink();

    final activeChunk = _transcript[activeIdx];
    final chunkText = activeChunk['text'] as String? ?? '';
    final chunkStart = (activeChunk['start_time'] as num?)?.toDouble() ?? 0;
    final chunkEnd = (activeChunk['end_time'] as num?)?.toDouble() ?? chunkStart + 30;
    final chunkDuration = (chunkEnd - chunkStart).clamp(0.5, 300.0);
    final elapsed = (pos - chunkStart).clamp(0.0, chunkDuration);
    final progress = elapsed / chunkDuration;

    final words = chunkText.split(' ').where((wd) => wd.isNotEmpty).toList();
    if (words.isEmpty) return const SizedBox.shrink();

    // Show 6 words at a time, cycling as progress advances
    const wordsPerCaption = 6;
    final currentWordIdx = (progress * words.length).floor().clamp(0, words.length - 1);
    final lineIdx = currentWordIdx ~/ wordsPerCaption;
    final lineStart = lineIdx * wordsPerCaption;
    final lineEnd = (lineStart + wordsPerCaption).clamp(0, words.length);
    final lineText = words.sublist(lineStart, lineEnd).join(' ');

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: Container(
        key: ValueKey('$activeIdx-$lineIdx'),
        padding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: w * 0.018),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.78),
          borderRadius: BorderRadius.circular(w * 0.02),
        ),
        child: Text(
          lineText,
          textAlign: TextAlign.center,
          style: GoogleFonts.lato(fontSize: w * 0.038, fontWeight: FontWeight.w500, color: Colors.white, height: 1.3),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  // ─── Info Panel (below video) ──────────────────────────────────────────────

  Widget _buildInfoPanel(double w, double h) {
    final isPlaying = _controller?.value.isPlaying ?? false;
    final position = _controller?.value.position ?? Duration.zero;
    final duration = _controller?.value.duration ?? Duration.zero;
    final progressVal = duration.inMilliseconds > 0
        ? position.inMilliseconds / duration.inMilliseconds
        : 0.0;

    return Container(
      color: AppColors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thin progress bar at top
          LinearProgressIndicator(
            value: progressVal.clamp(0.0, 1.0),
            backgroundColor: AppColors.grayLight,
            valueColor: const AlwaysStoppedAnimation(AppColors.primaryLime),
            minHeight: 3,
          ),

          Padding(
            padding: EdgeInsets.fromLTRB(w * 0.04, h * 0.012, w * 0.04, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title row
                GestureDetector(
                  onTap: () => setState(() => _titleExpanded = !_titleExpanded),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          widget.title,
                          style: GoogleFonts.lato(
                            fontSize: w * 0.042,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryDark,
                            height: 1.3,
                          ),
                          maxLines: _titleExpanded ? null : 2,
                          overflow: _titleExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: w * 0.02),
                      Icon(
                        _titleExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                        color: AppColors.gray,
                        size: w * 0.05,
                      ),
                    ],
                  ),
                ),

                SizedBox(height: h * 0.005),
                Text(
                  _isInitialized
                      ? '${_formatDuration(position)} / ${_formatDuration(duration)}'
                      : 'Loading...',
                  style: GoogleFonts.lato(fontSize: w * 0.03, color: AppColors.gray),
                ),

                SizedBox(height: h * 0.008),

                // Action buttons row
                Row(
                  children: [
                    _infoActionBtn(
                      isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded,
                      isPlaying ? 'Pause' : 'Resume',
                      w,
                      color: AppColors.primaryDark,
                      onTap: _togglePlayPause,
                    ),
                    _infoActionBtn(Icons.replay_10_rounded, '-10s', w, onTap: () => _seekRelative(-10)),
                    _infoActionBtn(Icons.forward_10_rounded, '+10s', w, onTap: () => _seekRelative(10)),
                    _infoActionBtn(Icons.quiz_rounded, 'Quiz', w,
                        color: _quizTriggered ? AppColors.orange : AppColors.gray,
                        onTap: () => _tryTriggerQuiz(manual: true)),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => _tabController.animateTo(0),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: w * 0.03, vertical: h * 0.007),
                        decoration: BoxDecoration(
                          color: AppColors.primaryDark,
                          borderRadius: BorderRadius.circular(w * 0.05),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.auto_awesome_rounded, color: AppColors.primaryLime, size: w * 0.035),
                          SizedBox(width: w * 0.01),
                          Text('Ask AIVA', style: GoogleFonts.lato(fontSize: w * 0.028, fontWeight: FontWeight.w700, color: AppColors.primaryLime)),
                        ]),
                      ),
                    ),
                  ],
                ),

                // Chapters strip (if available)
                if (_chapters.isNotEmpty) _buildInfoChapters(w, h),
              ],
            ),
          ),

          Divider(height: 1, color: AppColors.grayLight),
        ],
      ),
    );
  }

  Widget _buildInfoChapters(double w, double h) {
    final activeIdx = _currentChapterIndex();
    return SizedBox(
      height: h * 0.045,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.only(top: h * 0.008, bottom: h * 0.004),
        itemCount: _chapters.length,
        itemBuilder: (_, i) {
          final ch = _chapters[i];
          final title = ch['title']?.toString() ?? 'Chapter ${i + 1}';
          final secs = _chapterSeconds(ch);
          final label = ch['timestamp_label']?.toString()
              ?? _formatDuration(Duration(seconds: secs.toInt()));
          final isActive = i == activeIdx;
          return GestureDetector(
            onTap: () {
              _controller?.seekTo(Duration(seconds: secs.toInt()));
              _controller?.play();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.only(right: w * 0.02),
              padding: EdgeInsets.symmetric(horizontal: w * 0.025, vertical: h * 0.004),
              decoration: BoxDecoration(
                color: isActive ? AppColors.primaryDark : AppColors.lightBg,
                borderRadius: BorderRadius.circular(w * 0.04),
                border: Border.all(color: isActive ? AppColors.primaryDark : AppColors.grayLight),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(
                  isActive ? Icons.play_arrow_rounded : Icons.skip_next_rounded,
                  size: w * 0.03,
                  color: isActive ? AppColors.primaryLime : AppColors.gray,
                ),
                SizedBox(width: w * 0.008),
                Text(
                  title,
                  style: GoogleFonts.lato(
                    fontSize: w * 0.026,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isActive ? AppColors.white : AppColors.primaryDark,
                  ),
                ),
                SizedBox(width: w * 0.01),
                Text(
                  label,
                  style: GoogleFonts.lato(
                    fontSize: w * 0.024,
                    color: isActive ? AppColors.primaryLime : AppColors.gray,
                  ),
                ),
              ]),
            ),
          );
        },
      ),
    );
  }

  Widget _infoActionBtn(IconData icon, String label, double w, {VoidCallback? onTap, Color color = AppColors.gray}) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.only(right: w * 0.04),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: w * 0.055, color: color),
          SizedBox(height: 2),
          Text(label, style: GoogleFonts.lato(fontSize: w * 0.024, color: color)),
        ]),
      ),
    );
  }

  // ─── Tab Bar ──────────────────────────────────────────────────────────────

  Widget _buildTabBar(double w, double h) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(bottom: BorderSide(color: AppColors.grayLight, width: 1)),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.primaryDark,
        unselectedLabelColor: AppColors.gray,
        labelStyle: GoogleFonts.lato(fontSize: w * 0.028, fontWeight: FontWeight.w700),
        unselectedLabelStyle: GoogleFonts.lato(fontSize: w * 0.028, fontWeight: FontWeight.w500),
        indicatorColor: AppColors.primaryLime,
        indicatorWeight: 3,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        tabs: [
          Tab(
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.auto_awesome_rounded, size: w * 0.035),
              SizedBox(width: w * 0.01),
              const Text('AIVA'),
            ]),
          ),
          const Tab(text: 'Transcript'),
          const Tab(text: 'Summary'),
          Tab(
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.note_alt_outlined, size: w * 0.035),
              SizedBox(width: w * 0.01),
              const Text('Notes'),
            ]),
          ),
        ],
      ),
    );
  }

  // ─── AIVA Chat Tab ────────────────────────────────────────────────────────

  Widget _buildAIVATab(double w, double h) {
    return Column(
      children: [
        Expanded(
          child: _chatMessages.isEmpty
              ? _buildChatEmptyState(w, h)
              : ListView.builder(
                  controller: _chatScrollController,
                  padding: EdgeInsets.fromLTRB(w * 0.04, h * 0.015, w * 0.04, h * 0.01),
                  itemCount: _chatMessages.length,
                  itemBuilder: (_, i) => _buildChatBubble(_chatMessages[i], w, h),
                ),
        ),
        if (_chatLoading) _buildTypingIndicator(w, h),
        _buildChatInput(w, h),
      ],
    );
  }

  Widget _buildChatEmptyState(double w, double h) {
    final posStr = _isInitialized
        ? _formatDuration(_controller?.value.position ?? Duration.zero)
        : null;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: w * 0.06, vertical: h * 0.02),
      child: Column(
        children: [
          SizedBox(height: h * 0.015),
          Container(
            width: w * 0.18,
            height: w * 0.18,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primaryDark, Color(0xFF2D3A42)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(w * 0.05),
              boxShadow: [
                BoxShadow(color: AppColors.primaryDark.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6)),
              ],
            ),
            child: Center(
              child: Icon(Icons.auto_awesome_rounded, color: AppColors.primaryLime, size: w * 0.09),
            ),
          ),
          SizedBox(height: h * 0.018),
          Text(
            'Chat with AIVA',
            style: GoogleFonts.lato(fontSize: w * 0.045, fontWeight: FontWeight.w800, color: AppColors.primaryDark),
          ),
          SizedBox(height: h * 0.006),
          Text(
            posStr != null
                ? 'Ask anything about the lecture\nCurrently at $posStr'
                : 'Ask anything about this lecture',
            textAlign: TextAlign.center,
            style: GoogleFonts.lato(fontSize: w * 0.032, color: AppColors.gray, height: 1.5),
          ),
          SizedBox(height: h * 0.025),
          // Quick question chips
          Wrap(
            spacing: w * 0.02,
            runSpacing: h * 0.01,
            alignment: WrapAlignment.center,
            children: _quickQuestions.map((q) => GestureDetector(
              onTap: () => _sendMessage(q),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: w * 0.035, vertical: h * 0.009),
                decoration: BoxDecoration(
                  color: AppColors.lightBg,
                  border: Border.all(color: AppColors.grayLight),
                  borderRadius: BorderRadius.circular(w * 0.05),
                ),
                child: Text(
                  q,
                  style: GoogleFonts.lato(fontSize: w * 0.03, color: AppColors.primaryDark, fontWeight: FontWeight.w600),
                ),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  /// Converts timestamps like "2:30" → "[2:30](#t=150)" so MarkdownBody
  /// renders them as tappable links while keeping full markdown formatting.
  String _injectTimestampLinks(String text) {
    return text.replaceAllMapped(
      RegExp(r'\b(\d{1,2}:\d{2}(?::\d{2})?)\b'),
      (m) {
        final ts = m.group(0)!;
        final parts = ts.split(':');
        int secs = 0;
        try {
          if (parts.length == 2) {
            secs = int.parse(parts[0]) * 60 + int.parse(parts[1]);
          } else if (parts.length == 3) {
            secs = int.parse(parts[0]) * 3600 + int.parse(parts[1]) * 60 + int.parse(parts[2]);
          }
        } catch (_) {}
        return '[$ts](#t=$secs)';
      },
    );
  }

  MarkdownStyleSheet _aivaChatStyle(double w) => MarkdownStyleSheet(
        // Paragraphs
        p: GoogleFonts.lato(fontSize: w * 0.034, color: AppColors.primaryDark, height: 1.6),
        pPadding: const EdgeInsets.only(bottom: 4),
        // Headings
        h1: GoogleFonts.lato(fontSize: w * 0.044, fontWeight: FontWeight.w800, color: AppColors.primaryDark),
        h2: GoogleFonts.lato(fontSize: w * 0.04, fontWeight: FontWeight.w700, color: AppColors.primaryDark),
        h3: GoogleFonts.lato(fontSize: w * 0.037, fontWeight: FontWeight.w600, color: AppColors.purple),
        h4: GoogleFonts.lato(fontSize: w * 0.035, fontWeight: FontWeight.w600, color: AppColors.primaryDark),
        // Inline formatting
        strong: GoogleFonts.lato(fontSize: w * 0.034, fontWeight: FontWeight.w700, color: AppColors.primaryDark),
        em: GoogleFonts.lato(fontSize: w * 0.034, fontStyle: FontStyle.italic, color: AppColors.grayDark),
        del: GoogleFonts.lato(fontSize: w * 0.034, color: AppColors.gray, decoration: TextDecoration.lineThrough),
        // Links — timestamps become lime-coloured links
        a: GoogleFonts.lato(fontSize: w * 0.034, color: AppColors.primaryLime, fontWeight: FontWeight.w700, decoration: TextDecoration.none),
        // Lists
        listBullet: GoogleFonts.lato(fontSize: w * 0.034, color: AppColors.purple, height: 1.6),
        listIndent: w * 0.04,
        listBulletPadding: EdgeInsets.only(right: w * 0.015),
        // Block quote
        blockquote: GoogleFonts.lato(fontSize: w * 0.033, color: AppColors.gray, fontStyle: FontStyle.italic, height: 1.55),
        blockquoteDecoration: BoxDecoration(
          color: Colors.black.withOpacity(0.04),
          border: const Border(left: BorderSide(color: AppColors.primaryLime, width: 3)),
        ),
        blockquotePadding: EdgeInsets.fromLTRB(w * 0.03, 4, w * 0.02, 4),
        // Code
        code: GoogleFonts.sourceCodePro(
          fontSize: w * 0.03,
          color: AppColors.purple,
          backgroundColor: Colors.black.withOpacity(0.06),
        ),
        codeblockDecoration: BoxDecoration(
          color: Colors.black.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        codeblockPadding: EdgeInsets.all(w * 0.035),
        textScaleFactor: 1.0,
      );

  Widget _buildChatBubble(Map<String, dynamic> msg, double w, double h) {
    final isUser = msg['role'] == 'user';
    final text = msg['text'] as String? ?? '';

    return Padding(
      padding: EdgeInsets.only(bottom: h * 0.012),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: w * 0.07,
              height: w * 0.07,
              margin: EdgeInsets.only(right: w * 0.02),
              decoration: const BoxDecoration(color: AppColors.primaryDark, shape: BoxShape.circle),
              child: Center(child: Icon(Icons.auto_awesome_rounded, color: AppColors.primaryLime, size: w * 0.035)),
            ),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(maxWidth: w * 0.8),
              padding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: h * 0.012),
              decoration: BoxDecoration(
                color: isUser ? AppColors.primaryDark : AppColors.lightBg,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(w * 0.045),
                  topRight: Radius.circular(w * 0.045),
                  bottomLeft: Radius.circular(isUser ? w * 0.045 : w * 0.006),
                  bottomRight: Radius.circular(isUser ? w * 0.006 : w * 0.045),
                ),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
              ),
              child: isUser
                  ? Text(text, style: GoogleFonts.lato(fontSize: w * 0.034, color: Colors.white, height: 1.5))
                  : MarkdownBody(
                      // Inject timestamp links so they're tappable within
                      // the fully-formatted markdown response.
                      data: _injectTimestampLinks(
                        text.replaceAll('\r\n', '\n').trim(),
                      ),
                      softLineBreak: true,
                      styleSheet: _aivaChatStyle(w),
                      onTapLink: (linkText, href, title) {
                        // "#t=<seconds>" href → seek video
                        if (href != null && href.startsWith('#t=')) {
                          final secs = int.tryParse(href.substring(3)) ?? 0;
                          _controller?.seekTo(Duration(seconds: secs));
                          _controller?.play();
                        }
                      },
                    ),
            ),
          ),
          if (isUser) SizedBox(width: w * 0.01),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator(double w, double h) {
    return Padding(
      padding: EdgeInsets.fromLTRB(w * 0.04, 0, w * 0.04, h * 0.006),
      child: Row(
        children: [
          Container(
            width: w * 0.07,
            height: w * 0.07,
            decoration: const BoxDecoration(color: AppColors.primaryDark, shape: BoxShape.circle),
            child: Center(child: Icon(Icons.auto_awesome_rounded, color: AppColors.primaryLime, size: w * 0.035)),
          ),
          SizedBox(width: w * 0.02),
          Container(
            padding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: h * 0.012),
            decoration: BoxDecoration(
              color: AppColors.lightBg,
              borderRadius: BorderRadius.circular(w * 0.045),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              SizedBox(width: w * 0.03, height: w * 0.03, child: const CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryDark)),
              SizedBox(width: w * 0.02),
              Text('AIVA is thinking...', style: GoogleFonts.lato(fontSize: w * 0.03, color: AppColors.gray)),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildChatInput(double w, double h) {
    return Container(
      padding: EdgeInsets.fromLTRB(w * 0.04, h * 0.012, w * 0.03, h * 0.012),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.grayLight)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, -2))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              constraints: BoxConstraints(minHeight: h * 0.052),
              padding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: h * 0.013),
              decoration: BoxDecoration(
                color: AppColors.lightBg,
                borderRadius: BorderRadius.circular(w * 0.05),
                border: Border.all(color: AppColors.grayLight),
              ),
              child: TextField(
                controller: _chatInput,
                focusNode: _chatFocusNode,
                style: GoogleFonts.lato(fontSize: w * 0.036, color: AppColors.primaryDark, height: 1.4),
                decoration: InputDecoration(
                  hintText: 'Ask about this lecture...',
                  hintStyle: GoogleFonts.lato(fontSize: w * 0.036, color: AppColors.gray),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                maxLines: 4,
                minLines: 1,
              ),
            ),
          ),
          SizedBox(width: w * 0.025),
          GestureDetector(
            onTap: () => _sendMessage(),
            child: Container(
              width: w * 0.115,
              height: w * 0.115,
              decoration: const BoxDecoration(color: AppColors.primaryDark, shape: BoxShape.circle),
              child: Center(child: Icon(Icons.send_rounded, color: AppColors.primaryLime, size: w * 0.045)),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Transcript Tab ───────────────────────────────────────────────────────

  /// Returns the index of the last transcript chunk whose start_time ≤ current pos.
  /// More robust than start+end range check — handles gaps between chunks.
  int _findActiveChunkIndex() {
    if (_transcript.isEmpty) return -1;
    final pos = _controller?.value.position.inSeconds.toDouble() ?? 0;
    int idx = -1;
    for (int i = 0; i < _transcript.length; i++) {
      final start = (_transcript[i]['start_time'] as num?)?.toDouble() ?? 0;
      if (start <= pos) {
        idx = i;
      } else {
        break;
      }
    }
    return idx;
  }

  /// Chapters use 'seconds' field (not 'start_time') from the backend.
  double _chapterSeconds(Map<String, dynamic> ch) {
    return (ch['seconds'] as num?)?.toDouble()
        ?? (ch['start_time'] as num?)?.toDouble()
        ?? 0;
  }

  int _currentChapterIndex() {
    if (_chapters.isEmpty) return -1;
    final pos = _controller?.value.position.inSeconds.toDouble() ?? 0;
    int idx = 0;
    for (int i = 0; i < _chapters.length; i++) {
      if (_chapterSeconds(_chapters[i]) <= pos) idx = i;
      else break;
    }
    return idx;
  }

  Widget _buildTranscriptTab(double w, double h) {
    if (_transcriptLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primaryDark, strokeWidth: 2));
    }
    if (_transcript.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.closed_caption_off_rounded, size: w * 0.14, color: AppColors.grayLight),
          SizedBox(height: h * 0.015),
          Text('Transcript not available', style: GoogleFonts.lato(fontSize: w * 0.038, color: AppColors.gray, fontWeight: FontWeight.w600)),
          SizedBox(height: h * 0.006),
          Text('Check back after processing', style: GoogleFonts.lato(fontSize: w * 0.032, color: AppColors.gray)),
        ]),
      );
    }

    // Everything in one CustomScrollView — chapters + all chunks.
    // Past chunks stay visible above the current; auto-scroll keeps current in view.
    // No overflow possible because there's no fixed-height outer column.
    return CustomScrollView(
      controller: _transcriptScrollController,
      physics: const ClampingScrollPhysics(),
      slivers: [
        // Chapters strip (if generated)
        if (_chapters.isNotEmpty)
          SliverToBoxAdapter(child: _buildChaptersStrip(w, h)),

        // Compact "Now Playing" bar (fixed height, never overflows)
        SliverToBoxAdapter(child: _buildNowPlayingBar(w, h)),

        // All transcript chunks — past chunks are above the current
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (_, i) {
              final chunk = _transcript[i];
              final start = (chunk['start_time'] as num?)?.toDouble() ?? 0;
              final text = chunk['text'] as String? ?? '';
              final activeIdx = _findActiveChunkIndex();
              final isActive = i == activeIdx;
              final isPast = i < activeIdx;
              final label = chunk['timestamp_label'] as String? ??
                  _formatDuration(Duration(seconds: start.toInt()));

              return GestureDetector(
                onTap: () {
                  _controller?.seekTo(Duration(seconds: start.toInt()));
                  _controller?.play();
                  // Resume auto-scroll when user taps
                  setState(() => _autoScrollTranscript = true);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  color: isActive
                      ? AppColors.primaryLime.withOpacity(0.1)
                      : Colors.transparent,
                  padding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: h * 0.012),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    // Timestamp
                    Container(
                      width: w * 0.13,
                      padding: EdgeInsets.symmetric(horizontal: w * 0.012, vertical: h * 0.004),
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.primaryDark
                            : isPast
                                ? AppColors.lightBg
                                : Colors.transparent,
                        borderRadius: BorderRadius.circular(w * 0.02),
                      ),
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.lato(
                          fontSize: w * 0.025,
                          color: isActive
                              ? AppColors.primaryLime
                              : isPast
                                  ? AppColors.gray
                                  : AppColors.grayLight,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    SizedBox(width: w * 0.03),
                    Expanded(
                      child: Text(
                        text,
                        style: GoogleFonts.lato(
                          fontSize: w * 0.034,
                          color: isActive
                              ? AppColors.primaryDark
                              : isPast
                                  ? AppColors.grayDark
                                  : AppColors.gray,
                          height: 1.55,
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                    if (isActive)
                      Padding(
                        padding: EdgeInsets.only(top: h * 0.006, left: w * 0.02),
                        child: Container(
                          width: w * 0.018,
                          height: w * 0.018,
                          decoration: const BoxDecoration(
                              color: AppColors.primaryLime, shape: BoxShape.circle),
                        ),
                      ),
                  ]),
                ),
              );
            },
            childCount: _transcript.length,
          ),
        ),

        SliverPadding(padding: EdgeInsets.only(bottom: h * 0.03)),
      ],
    );
  }

  /// Compact single-line bar showing what's currently playing — no overflow risk.
  Widget _buildNowPlayingBar(double w, double h) {
    final activeIdx = _findActiveChunkIndex();
    if (activeIdx < 0) return const SizedBox.shrink();

    final chunk = _transcript[activeIdx];
    final label = chunk['timestamp_label'] as String? ??
        _formatDuration(Duration(seconds:
            ((chunk['start_time'] as num?)?.toInt() ?? 0)));

    return Container(
      margin: EdgeInsets.fromLTRB(w * 0.04, h * 0.008, w * 0.04, h * 0.004),
      padding: EdgeInsets.symmetric(horizontal: w * 0.035, vertical: h * 0.009),
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.circular(w * 0.03),
      ),
      child: Row(children: [
        Container(
          width: w * 0.018,
          height: w * 0.018,
          decoration: const BoxDecoration(color: AppColors.primaryLime, shape: BoxShape.circle),
        ),
        SizedBox(width: w * 0.02),
        Text('Now Playing',
            style: GoogleFonts.lato(fontSize: w * 0.028, fontWeight: FontWeight.w700, color: AppColors.primaryLime)),
        const Spacer(),
        Text(label,
            style: GoogleFonts.lato(fontSize: w * 0.026, color: Colors.white54, fontWeight: FontWeight.w600)),
        SizedBox(width: w * 0.015),
        GestureDetector(
          onTap: () => setState(() => _autoScrollTranscript = true),
          child: Icon(
            _autoScrollTranscript ? Icons.my_location_rounded : Icons.location_searching_rounded,
            size: w * 0.038,
            color: _autoScrollTranscript ? AppColors.primaryLime : Colors.white38,
          ),
        ),
      ]),
    );
  }

  // ── Chapters strip (in Transcript tab) ───────────────────────────────────

  Widget _buildChaptersStrip(double w, double h) {
    final activeIdx = _currentChapterIndex();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(w * 0.04, h * 0.01, w * 0.04, h * 0.005),
          child: Text('Chapters', style: GoogleFonts.lato(fontSize: w * 0.03, fontWeight: FontWeight.w700, color: AppColors.gray)),
        ),
        SizedBox(
          height: h * 0.05,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: w * 0.04),
            itemCount: _chapters.length,
            itemBuilder: (_, i) {
              final chapter = _chapters[i];
              final title = chapter['title']?.toString() ?? 'Chapter ${i + 1}';
              final chSecs = _chapterSeconds(chapter);
              // 'timestamp_label' from backend; fallback to computed label
              final label = chapter['timestamp_label']?.toString()
                  ?? _formatDuration(Duration(seconds: chSecs.toInt()));
              final isActive = i == activeIdx;

              return GestureDetector(
                onTap: () {
                  _controller?.seekTo(Duration(seconds: chSecs.toInt()));
                  _controller?.play();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: EdgeInsets.only(right: w * 0.025),
                  padding: EdgeInsets.symmetric(horizontal: w * 0.03, vertical: h * 0.006),
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.primaryDark : AppColors.lightBg,
                    borderRadius: BorderRadius.circular(w * 0.04),
                    border: Border.all(color: isActive ? AppColors.primaryDark : AppColors.grayLight),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(
                      isActive ? Icons.play_arrow_rounded : Icons.skip_next_rounded,
                      size: w * 0.032,
                      color: isActive ? AppColors.primaryLime : AppColors.gray,
                    ),
                    SizedBox(width: w * 0.01),
                    Text(title,
                        style: GoogleFonts.lato(
                          fontSize: w * 0.028,
                          fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                          color: isActive ? AppColors.white : AppColors.primaryDark,
                        )),
                    SizedBox(width: w * 0.012),
                    Text(label,
                        style: GoogleFonts.lato(
                          fontSize: w * 0.025,
                          color: isActive ? AppColors.primaryLime : AppColors.gray,
                          fontWeight: FontWeight.w600,
                        )),
                  ]),
                ),
              );
            },
          ),
        ),
        SizedBox(height: h * 0.006),
      ],
    );
  }

  // ─── Notes Tab (personalized from Q&A) ───────────────────────────────────

  Widget _buildNotesTab(double w, double h) {
    if (!ApiService.hasToken) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.lock_outline_rounded, size: w * 0.14, color: AppColors.grayLight),
          SizedBox(height: h * 0.015),
          Text('Sign in to view your notes', style: GoogleFonts.lato(fontSize: w * 0.038, color: AppColors.gray, fontWeight: FontWeight.w600)),
        ]),
      );
    }

    if (_notesLoading) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const CircularProgressIndicator(color: AppColors.primaryDark, strokeWidth: 2),
          SizedBox(height: h * 0.015),
          Text('Generating your notes...', style: GoogleFonts.lato(fontSize: w * 0.032, color: AppColors.gray)),
        ]),
      );
    }

    return ListView(
      // ListView gives us vertical-only scrolling and proper width constraints
      physics: const ClampingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(w * 0.04, h * 0.016, w * 0.04, h * 0.05),
      children: [
        // ── Header ────────────────────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(children: [
              Container(
                padding: EdgeInsets.all(w * 0.018),
                decoration: BoxDecoration(
                  color: AppColors.primaryDark,
                  borderRadius: BorderRadius.circular(w * 0.02),
                ),
                child: Icon(Icons.note_alt_rounded, color: AppColors.primaryLime, size: w * 0.038),
              ),
              SizedBox(width: w * 0.02),
              Text('My Notes',
                  style: GoogleFonts.lato(fontSize: w * 0.042, fontWeight: FontWeight.w800, color: AppColors.primaryDark)),
            ]),
            GestureDetector(
              onTap: () {
                setState(() => _notesLoading = true);
                _loadNotes();
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: w * 0.03, vertical: h * 0.007),
                decoration: BoxDecoration(
                  color: AppColors.lightBg,
                  borderRadius: BorderRadius.circular(w * 0.03),
                  border: Border.all(color: AppColors.grayLight),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.refresh_rounded, size: w * 0.035, color: AppColors.gray),
                  SizedBox(width: w * 0.01),
                  Text('Refresh', style: GoogleFonts.lato(fontSize: w * 0.028, color: AppColors.gray)),
                ]),
              ),
            ),
          ],
        ),

        SizedBox(height: h * 0.014),

        // ── Empty state ───────────────────────────────────────────────────
        if (_notesContent == null || _notesContent!.isEmpty) ...[
          SizedBox(height: h * 0.04),
          Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                padding: EdgeInsets.all(w * 0.05),
                decoration: const BoxDecoration(color: AppColors.lightBg, shape: BoxShape.circle),
                child: Icon(Icons.chat_bubble_outline_rounded, size: w * 0.12, color: AppColors.gray),
              ),
              SizedBox(height: h * 0.02),
              Text('No notes yet',
                  style: GoogleFonts.lato(fontSize: w * 0.042, fontWeight: FontWeight.w700, color: AppColors.primaryDark)),
              SizedBox(height: h * 0.008),
              Text(
                'Ask AIVA questions while watching.\nNotes are generated from your Q&A.',
                textAlign: TextAlign.center,
                style: GoogleFonts.lato(fontSize: w * 0.033, color: AppColors.gray, height: 1.5),
              ),
              SizedBox(height: h * 0.025),
              GestureDetector(
                onTap: () => _tabController.animateTo(0),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: w * 0.06, vertical: h * 0.014),
                  decoration: BoxDecoration(
                    color: AppColors.primaryDark,
                    borderRadius: BorderRadius.circular(w * 0.035),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.auto_awesome_rounded, color: AppColors.primaryLime, size: w * 0.04),
                    SizedBox(width: w * 0.015),
                    Text('Ask AIVA',
                        style: GoogleFonts.lato(fontSize: w * 0.036, fontWeight: FontWeight.w700, color: AppColors.primaryLime)),
                  ]),
                ),
              ),
            ]),
          ),
        ] else ...[
          // ── "Generated from your questions" badge ─────────────────────
          Container(
            padding: EdgeInsets.symmetric(horizontal: w * 0.03, vertical: h * 0.007),
            decoration: BoxDecoration(
              color: AppColors.primaryLime.withOpacity(0.12),
              borderRadius: BorderRadius.circular(w * 0.02),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.auto_awesome_rounded, color: AppColors.primaryDark, size: w * 0.03),
              SizedBox(width: w * 0.01),
              Text('Generated from your questions',
                  style: GoogleFonts.lato(fontSize: w * 0.028, color: AppColors.primaryDark, fontWeight: FontWeight.w600)),
            ]),
          ),

          SizedBox(height: h * 0.016),

          // ── Markdown notes ────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: MarkdownBody(
              // Normalise line endings so the parser always sees \n
              data: _notesContent!.replaceAll('\r\n', '\n').trim(),
              selectable: true,
              softLineBreak: true,
              // Use MarkdownStyleSheet() directly — fromTheme().copyWith()
              // silently loses overrides when the app theme lacks Lato fonts.
              styleSheet: MarkdownStyleSheet(
                p: GoogleFonts.lato(fontSize: w * 0.036, color: AppColors.primaryDark, height: 1.72),
                pPadding: EdgeInsets.only(bottom: h * 0.01),
                h1: GoogleFonts.lato(fontSize: w * 0.05, fontWeight: FontWeight.w800, color: AppColors.primaryDark),
                h1Padding: EdgeInsets.only(top: h * 0.018, bottom: h * 0.008),
                h2: GoogleFonts.lato(fontSize: w * 0.044, fontWeight: FontWeight.w700, color: AppColors.primaryDark),
                h2Padding: EdgeInsets.only(top: h * 0.014, bottom: h * 0.006),
                h3: GoogleFonts.lato(fontSize: w * 0.04, fontWeight: FontWeight.w600, color: AppColors.purple),
                h3Padding: EdgeInsets.only(top: h * 0.012, bottom: h * 0.005),
                h4: GoogleFonts.lato(fontSize: w * 0.038, fontWeight: FontWeight.w600, color: AppColors.primaryDark),
                strong: GoogleFonts.lato(fontSize: w * 0.036, fontWeight: FontWeight.w700, color: AppColors.primaryDark),
                em: GoogleFonts.lato(fontSize: w * 0.036, fontStyle: FontStyle.italic, color: AppColors.grayDark),
                del: GoogleFonts.lato(fontSize: w * 0.036, color: AppColors.gray, decoration: TextDecoration.lineThrough),
                listBullet: GoogleFonts.lato(fontSize: w * 0.036, color: AppColors.purple),
                listIndent: w * 0.04,
                listBulletPadding: EdgeInsets.only(right: w * 0.02),
                blockquote: GoogleFonts.lato(fontSize: w * 0.034, color: AppColors.gray, fontStyle: FontStyle.italic, height: 1.6),
                blockquoteDecoration: BoxDecoration(
                  color: AppColors.lightBg,
                  border: const Border(left: BorderSide(color: AppColors.primaryLime, width: 3)),
                ),
                blockquotePadding: EdgeInsets.fromLTRB(w * 0.04, h * 0.008, w * 0.02, h * 0.008),
                code: GoogleFonts.sourceCodePro(fontSize: w * 0.031, color: AppColors.primaryDark, backgroundColor: AppColors.lightBg),
                codeblockDecoration: BoxDecoration(
                  color: AppColors.lightBg,
                  borderRadius: BorderRadius.circular(w * 0.025),
                  border: Border.all(color: AppColors.grayLight),
                ),
                codeblockPadding: EdgeInsets.all(w * 0.04),
                horizontalRuleDecoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: AppColors.grayLight, width: 1)),
                ),
                textScaleFactor: 1.0,
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ─── Summary Tab ──────────────────────────────────────────────────────────

  Widget _buildSummaryTab(double w, double h) {
    if (_summaryLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primaryDark, strokeWidth: 2));
    }
    if (_summaryFull == null) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.article_outlined, size: w * 0.14, color: AppColors.grayLight),
          SizedBox(height: h * 0.015),
          Text('Summary not available yet', style: GoogleFonts.lato(fontSize: w * 0.038, color: AppColors.gray, fontWeight: FontWeight.w600)),
          SizedBox(height: h * 0.006),
          Text('Available after video is processed', style: GoogleFonts.lato(fontSize: w * 0.032, color: AppColors.gray)),
        ]),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(w * 0.04, h * 0.02, w * 0.04, h * 0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: w * 0.03, vertical: h * 0.008),
            decoration: BoxDecoration(
              color: AppColors.primaryLime.withOpacity(0.15),
              borderRadius: BorderRadius.circular(w * 0.02),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.auto_awesome_rounded, color: AppColors.primaryDark, size: w * 0.035),
              SizedBox(width: w * 0.015),
              Text('AI-Generated Summary', style: GoogleFonts.lato(fontSize: w * 0.03, fontWeight: FontWeight.w700, color: AppColors.primaryDark)),
            ]),
          ),
          SizedBox(height: h * 0.02),
          MarkdownBody(
            data: _summaryFull!,
            selectable: true,
            styleSheet: MarkdownStyleSheet(
              p: GoogleFonts.lato(fontSize: w * 0.036, color: AppColors.primaryDark, height: 1.7),
              h1: GoogleFonts.lato(fontSize: w * 0.05, fontWeight: FontWeight.w800, color: AppColors.primaryDark),
              h2: GoogleFonts.lato(fontSize: w * 0.044, fontWeight: FontWeight.w700, color: AppColors.primaryDark),
              h3: GoogleFonts.lato(fontSize: w * 0.04, fontWeight: FontWeight.w600, color: AppColors.purple),
              strong: GoogleFonts.lato(fontSize: w * 0.036, fontWeight: FontWeight.w700, color: AppColors.primaryDark),
              em: GoogleFonts.lato(fontSize: w * 0.036, fontStyle: FontStyle.italic, color: AppColors.gray),
              listBullet: GoogleFonts.lato(fontSize: w * 0.036, color: AppColors.purple),
              blockquote: GoogleFonts.lato(fontSize: w * 0.035, color: AppColors.gray, fontStyle: FontStyle.italic),
              blockquoteDecoration: BoxDecoration(
                color: AppColors.lightBg,
                border: const Border(left: BorderSide(color: AppColors.primaryLime, width: 4)),
              ),
              code: GoogleFonts.sourceCodePro(fontSize: w * 0.03, color: AppColors.primaryDark, backgroundColor: AppColors.lightBg),
              horizontalRuleDecoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.grayLight, width: 1))),
            ),
          ),
        ],
      ),
    );
  }
}
