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

class _VideoPlayerScreenState extends State<VideoPlayerScreen> with TickerProviderStateMixin {
  VideoPlayerController? _controller;
  late TabController _tabController;
  bool _isInitialized = false;
  bool _showControls = true;
  bool _isFullscreen = false;
  Timer? _hideControlsTimer;
  Timer? _progressTimer;
  int _lastReportedSeconds = 0;
  bool _quizTriggered = false;

  // Tab data
  List<Map<String, dynamic>> _transcript = [];
  List<Map<String, dynamic>> _chapters = [];
  String? _summaryFull;
  List<dynamic> _summaryTopics = [];
  bool _transcriptLoading = true;
  bool _summaryLoading = true;

  // AIVA chat state
  final List<Map<String, dynamic>> _chatMessages = [];
  final TextEditingController _chatInput = TextEditingController();
  bool _chatLoading = false;
  final ScrollController _chatScrollController = ScrollController();

  // Transcript scroll controller
  ScrollController _transcriptScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initVideo();
    _loadTranscript();
    _loadSummary();
  }

  @override
  void dispose() {
    _controller?.dispose();
    _hideControlsTimer?.cancel();
    _progressTimer?.cancel();
    _tabController.dispose();
    _chatInput.dispose();
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
    if ((pos - _lastReportedSeconds).abs() >= 10) {
      _reportProgress();
    }

    if (!_quizTriggered && _isInitialized && _controller != null) {
      final total = _controller!.value.duration.inSeconds;
      if (total > 0) {
        final percent = pos / total;
        if (percent >= 0.9) {
          _quizTriggered = true;
          _tryTriggerQuiz();
        }
      }
    }

    setState(() {});

    // Auto-scroll transcript to active chunk
    if (_transcript.isNotEmpty && _tabController.index == 1) {
      final transcriptPos = _controller?.value.position.inSeconds.toDouble() ?? 0;
      for (int i = 0; i < _transcript.length; i++) {
        final start = (_transcript[i]['start_time'] as num?)?.toDouble() ?? 0;
        final end = (_transcript[i]['end_time'] as num?)?.toDouble() ?? start + 30;
        if (transcriptPos >= start && transcriptPos < end) {
          const itemHeight = 80.0;
          final offset = i * itemHeight;
          if (_transcriptScrollController.hasClients) {
            _transcriptScrollController.animateTo(
              offset.clamp(0.0, _transcriptScrollController.position.maxScrollExtent),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
          break;
        }
      }
    }
  }

  Future<void> _tryTriggerQuiz() async {
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
          builder: (_) => QuizModal(
            lectureId: widget.lectureId,
            questions: questions!,
          ),
        );
      }
    } catch (_) {}
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
          _summaryTopics = data['summary_topics'] as List? ?? [];
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

  Future<void> _sendMessage() async {
    final text = _chatInput.text.trim();
    if (text.isEmpty || _chatLoading) return;
    _chatInput.clear();

    final currentPos = _controller?.value.position.inSeconds ?? 0;

    setState(() {
      _chatMessages.add({'role': 'user', 'text': text});
      _chatLoading = true;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });

    try {
      final req = ApiService.buildStreamRequest('/api/ask', {
        'lecture_id': widget.lectureId,
        'question': text,
        'language': RegExp(r'[ऀ-ॿ]').hasMatch(text) ? 'hi' : 'en',
        'current_timestamp': currentPos,
        'chat_history': _chatMessages.where((m) => m['role'] == 'user').take(5).map((m) => {'role': 'user', 'content': m['text']}).toList(),
      });

      final client = await req.send();
      final stream = client.stream
          .transform(const Utf8Decoder())
          .transform(const LineSplitter());

      String responseText = '';
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
    } finally {
      if (mounted) setState(() => _chatLoading = false);
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
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        bottom: !_isFullscreen,
        child: _isFullscreen
            ? _buildVideoSection(w, h)
            : Column(
                children: [
                  _buildVideoSection(w, h),
                  _buildVideoMeta(w, h),
                  _buildPillTabBar(w, h),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildAIVATab(w, h),
                        _buildTranscriptTab(w, h),
                        _buildSummaryTab(w, h),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildVideoSection(double w, double h) {
    final videoH = _isFullscreen ? h : w * 9 / 16;
    return GestureDetector(
      onTap: _toggleControls,
      child: Container(
        width: double.infinity, height: videoH, color: Colors.black,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Video
            if (_isInitialized && _controller != null)
              AspectRatio(aspectRatio: _controller!.value.aspectRatio, child: VideoPlayer(_controller!))
            else
              const Center(child: CircularProgressIndicator(color: AppColors.primaryLime, strokeWidth: 2)),

            // Controls overlay
            AnimatedOpacity(
              opacity: _showControls ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    colors: [Colors.black54, Colors.transparent, Colors.transparent, Colors.black54],
                    stops: [0, 0.3, 0.7, 1],
                  ),
                ),
                child: Column(children: [
                  // Top bar
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: w * 0.03),
                    child: Row(children: [
                      GestureDetector(
                        onTap: () { _reportProgress(); Navigator.pop(context); },
                        child: Icon(Icons.arrow_back_rounded, color: Colors.white, size: w * 0.055),
                      ),
                      SizedBox(width: w * 0.03),
                      Expanded(child: Text(widget.title, style: GoogleFonts.lato(fontSize: w * 0.035, fontWeight: FontWeight.w600, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    ]),
                  ),
                  const Spacer(),
                  // Center controls
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    GestureDetector(onTap: () => _seekRelative(-10), child: Icon(Icons.replay_10_rounded, color: Colors.white, size: w * 0.09)),
                    SizedBox(width: w * 0.06),
                    GestureDetector(
                      onTap: _togglePlayPause,
                      child: Container(
                        padding: EdgeInsets.all(w * 0.03),
                        decoration: const BoxDecoration(color: AppColors.primaryLime, shape: BoxShape.circle),
                        child: Icon(
                          _controller?.value.isPlaying == true ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          color: AppColors.primaryDark, size: w * 0.08,
                        ),
                      ),
                    ),
                    SizedBox(width: w * 0.06),
                    GestureDetector(onTap: () => _seekRelative(10), child: Icon(Icons.forward_10_rounded, color: Colors.white, size: w * 0.09)),
                  ]),
                  const Spacer(),
                  // Progress + time
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: w * 0.04),
                    child: Column(children: [
                      if (_isInitialized && _controller != null)
                        SliderTheme(
                          data: SliderThemeData(
                            activeTrackColor: AppColors.primaryLime,
                            inactiveTrackColor: Colors.white38,
                            thumbColor: AppColors.primaryLime,
                            overlayColor: AppColors.primaryLime.withOpacity(0.2),
                            thumbShape: RoundSliderThumbShape(enabledThumbRadius: w * 0.016),
                            trackHeight: 3,
                            overlayShape: RoundSliderOverlayShape(overlayRadius: w * 0.04),
                          ),
                          child: Slider(
                            value: _controller!.value.position.inMilliseconds.toDouble(),
                            min: 0,
                            max: _controller!.value.duration.inMilliseconds.toDouble().clamp(1, double.infinity),
                            onChanged: (v) { _controller!.seekTo(Duration(milliseconds: v.toInt())); _startHideControlsTimer(); },
                          ),
                        ),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text(_isInitialized ? _formatDuration(_controller!.value.position) : '0:00', style: GoogleFonts.lato(color: Colors.white70, fontSize: w * 0.03)),
                        GestureDetector(onTap: _toggleFullscreen, child: Icon(_isFullscreen ? Icons.fullscreen_exit_rounded : Icons.fullscreen_rounded, color: Colors.white, size: w * 0.055)),
                        Text(_isInitialized ? _formatDuration(_controller!.value.duration) : '0:00', style: GoogleFonts.lato(color: Colors.white70, fontSize: w * 0.03)),
                      ]),
                      SizedBox(height: w * 0.02),
                    ]),
                  ),
                ]),
              ),
            ),

            // Caption overlay (shown when controls hidden and transcript available)
            if (!_showControls && _transcript.isNotEmpty && _isInitialized)
              Positioned(
                bottom: w * 0.06,
                left: w * 0.04,
                right: w * 0.04,
                child: _buildCaptionOverlay(w),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCaptionOverlay(double w) {
    final pos = _controller?.value.position.inSeconds.toDouble() ?? 0;
    Map<String, dynamic>? activeChunk;
    for (final chunk in _transcript) {
      final start = (chunk['start_time'] as num?)?.toDouble() ?? 0;
      final end = (chunk['end_time'] as num?)?.toDouble() ?? start + 30;
      if (pos >= start && pos < end) { activeChunk = chunk; break; }
    }
    if (activeChunk == null) return const SizedBox.shrink();

    final chunkText = activeChunk['text'] as String? ?? '';
    final chunkStart = (activeChunk['start_time'] as num?)?.toDouble() ?? 0;
    final chunkEnd = (activeChunk['end_time'] as num?)?.toDouble() ?? chunkStart + 30;
    final chunkDuration = (chunkEnd - chunkStart).clamp(0.1, 300.0);
    final elapsed = (pos - chunkStart).clamp(0.0, chunkDuration);
    final progress = elapsed / chunkDuration;

    final words = chunkText.split(' ').where((wd) => wd.isNotEmpty).toList();
    if (words.isEmpty) return const SizedBox.shrink();

    // Show 4 words at a time; when those 4 are done, next 4 replace them
    const wordsPerLine = 4;
    final currentWordIdx = (progress * words.length).floor().clamp(0, words.length - 1);
    final lineIdx = currentWordIdx ~/ wordsPerLine;
    final lineStart = lineIdx * wordsPerLine;
    final lineEnd = (lineStart + wordsPerLine).clamp(0, words.length);
    final lineText = words.sublist(lineStart, lineEnd).join(' ');

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      child: Container(
        key: ValueKey(lineIdx),
        padding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: w * 0.022),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.72),
          borderRadius: BorderRadius.circular(w * 0.02),
        ),
        child: Text(
          lineText,
          textAlign: TextAlign.center,
          style: GoogleFonts.lato(fontSize: w * 0.04, fontWeight: FontWeight.w500, color: Colors.white, height: 1.3, shadows: const [Shadow(color: Colors.black, blurRadius: 4)]),
          maxLines: 1,
        ),
      ),
    );
  }

  Widget _buildVideoMeta(double w, double h) {
    return Container(
      color: AppColors.white,
      padding: EdgeInsets.fromLTRB(w * 0.04, h * 0.015, w * 0.04, h * 0.012),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(widget.title, style: GoogleFonts.lato(fontSize: w * 0.042, fontWeight: FontWeight.w700, color: AppColors.primaryDark, height: 1.3), maxLines: 2, overflow: TextOverflow.ellipsis),
        SizedBox(height: h * 0.006),
        Text('Course • ${widget.courseId.length >= 8 ? widget.courseId.substring(0, 8) : widget.courseId}', style: GoogleFonts.lato(fontSize: w * 0.032, color: AppColors.gray)),
      ]),
    );
  }

  Widget _buildPillTabBar(double w, double h) {
    return Container(
      color: AppColors.white,
      padding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: h * 0.01),
      child: Container(
        height: h * 0.042,
        decoration: BoxDecoration(color: AppColors.lightBg, borderRadius: BorderRadius.circular(w * 0.06)),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(color: AppColors.primaryDark, borderRadius: BorderRadius.circular(w * 0.06)),
          labelColor: AppColors.primaryLime,
          unselectedLabelColor: AppColors.gray,
          labelStyle: GoogleFonts.lato(fontSize: w * 0.033, fontWeight: FontWeight.w700),
          unselectedLabelStyle: GoogleFonts.lato(fontSize: w * 0.033),
          dividerColor: Colors.transparent,
          tabs: const [Tab(text: 'Ask AIVA'), Tab(text: 'Transcript'), Tab(text: 'Summary')],
        ),
      ),
    );
  }

  Widget _buildAIVATab(double w, double h) {
    return Column(children: [
      // Messages list
      Expanded(
        child: _chatMessages.isEmpty
            ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.auto_awesome_rounded, color: AppColors.primaryLime, size: w * 0.12),
                SizedBox(height: h * 0.015),
                Text('Ask anything about this lecture', style: GoogleFonts.lato(fontSize: w * 0.038, fontWeight: FontWeight.w600, color: AppColors.primaryDark)),
                SizedBox(height: h * 0.008),
                Text('AIVA answers using the video content', style: GoogleFonts.lato(fontSize: w * 0.032, color: AppColors.gray)),
                SizedBox(height: h * 0.025),
                Wrap(spacing: w * 0.02, runSpacing: h * 0.01, alignment: WrapAlignment.center,
                  children: ['Summarize this', 'Explain simply', 'What just happened?'].map((hint) =>
                    GestureDetector(
                      onTap: () { _chatInput.text = hint; _sendMessage(); },
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: w * 0.035, vertical: h * 0.009),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.primaryLime),
                          borderRadius: BorderRadius.circular(w * 0.05),
                        ),
                        child: Text(hint, style: GoogleFonts.lato(fontSize: w * 0.032, color: AppColors.primaryDark, fontWeight: FontWeight.w600)),
                      ),
                    )
                  ).toList(),
                ),
              ]))
            : ListView.builder(
                controller: _chatScrollController,
                padding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: h * 0.01),
                itemCount: _chatMessages.length,
                itemBuilder: (_, i) {
                  final msg = _chatMessages[i];
                  final isUser = msg['role'] == 'user';
                  return Align(
                    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      constraints: BoxConstraints(maxWidth: w * 0.78),
                      margin: EdgeInsets.only(bottom: h * 0.01),
                      padding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: h * 0.012),
                      decoration: BoxDecoration(
                        color: isUser ? AppColors.primaryDark : AppColors.lightBg,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(w * 0.045),
                          topRight: Radius.circular(w * 0.045),
                          bottomLeft: Radius.circular(isUser ? w * 0.045 : w * 0.008),
                          bottomRight: Radius.circular(isUser ? w * 0.008 : w * 0.045),
                        ),
                      ),
                      child: isUser
                          ? Text(msg['text'] as String, style: GoogleFonts.lato(fontSize: w * 0.034, color: Colors.white, height: 1.5))
                          : MarkdownBody(
                              data: msg['text'] as String,
                              styleSheet: MarkdownStyleSheet(
                                p: GoogleFonts.lato(fontSize: w * 0.034, color: AppColors.primaryDark, height: 1.5),
                                strong: GoogleFonts.lato(fontSize: w * 0.034, color: AppColors.primaryDark, fontWeight: FontWeight.w700),
                                h3: GoogleFonts.lato(fontSize: w * 0.038, color: AppColors.primaryDark, fontWeight: FontWeight.w700),
                                listBullet: GoogleFonts.lato(fontSize: w * 0.034, color: AppColors.purple),
                                code: GoogleFonts.sourceCodePro(fontSize: w * 0.03, backgroundColor: AppColors.white),
                              ),
                            ),
                    ),
                  );
                },
              ),
      ),
      if (_chatLoading)
        Padding(
          padding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: h * 0.008),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: h * 0.012),
              decoration: BoxDecoration(color: AppColors.lightBg, borderRadius: BorderRadius.circular(w * 0.045)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                SizedBox(width: w * 0.035, height: w * 0.035, child: const CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryDark)),
                SizedBox(width: w * 0.02),
                Text('Thinking...', style: GoogleFonts.lato(fontSize: w * 0.032, color: AppColors.gray)),
              ]),
            ),
          ),
        ),
      // Input bar
      Container(
        padding: EdgeInsets.fromLTRB(w * 0.04, h * 0.01, w * 0.03, h * 0.012),
        decoration: BoxDecoration(
          color: AppColors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, -2))],
        ),
        child: Row(children: [
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: h * 0.01),
              decoration: BoxDecoration(color: AppColors.lightBg, borderRadius: BorderRadius.circular(w * 0.06)),
              child: TextField(
                controller: _chatInput,
                style: GoogleFonts.lato(fontSize: w * 0.035, color: AppColors.primaryDark),
                decoration: InputDecoration(
                  hintText: 'Ask about this lecture...',
                  hintStyle: GoogleFonts.lato(fontSize: w * 0.035, color: AppColors.gray),
                  border: InputBorder.none, contentPadding: EdgeInsets.zero, isCollapsed: true,
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                maxLines: null,
              ),
            ),
          ),
          SizedBox(width: w * 0.02),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              padding: EdgeInsets.all(w * 0.028),
              decoration: const BoxDecoration(color: AppColors.primaryDark, shape: BoxShape.circle),
              child: Icon(Icons.send_rounded, color: AppColors.primaryLime, size: w * 0.045),
            ),
          ),
        ]),
      ),
    ]);
  }

  Widget _buildTranscriptTab(double w, double h) {
    if (_transcriptLoading) return const Center(child: CircularProgressIndicator(color: AppColors.primaryDark, strokeWidth: 2));
    if (_transcript.isEmpty) return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.closed_caption_off_rounded, size: w * 0.15, color: AppColors.grayLight),
      SizedBox(height: h * 0.015),
      Text('Transcript not available', style: GoogleFonts.lato(fontSize: w * 0.038, color: AppColors.gray)),
    ]));

    return ListView.builder(
      controller: _transcriptScrollController,
      padding: EdgeInsets.symmetric(vertical: h * 0.01),
      itemCount: _transcript.length,
      itemBuilder: (_, i) {
        final chunk = _transcript[i];
        final start = (chunk['start_time'] as num?)?.toDouble() ?? 0;
        final end = (chunk['end_time'] as num?)?.toDouble() ?? start + 30;
        final text = chunk['text'] as String? ?? '';
        final currentPos = _controller?.value.position.inSeconds.toDouble() ?? 0;
        final isActive = currentPos >= start && currentPos < end;
        final label = chunk['timestamp_label'] as String? ?? _formatDuration(Duration(seconds: start.toInt()));

        return GestureDetector(
          onTap: () { _controller?.seekTo(Duration(seconds: start.toInt())); _controller?.play(); },
          child: Container(
            color: isActive ? AppColors.primaryLime.withOpacity(0.1) : Colors.transparent,
            padding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: h * 0.012),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SizedBox(
                width: w * 0.12,
                child: Text(label, style: GoogleFonts.lato(fontSize: w * 0.028, color: isActive ? AppColors.primaryDark : AppColors.gray, fontWeight: FontWeight.w700)),
              ),
              Expanded(
                child: Text(text, style: GoogleFonts.lato(fontSize: w * 0.033, color: isActive ? AppColors.primaryDark : AppColors.gray, height: 1.5, fontWeight: isActive ? FontWeight.w600 : FontWeight.normal)),
              ),
            ]),
          ),
        );
      },
    );
  }

  Widget _buildSummaryTab(double w, double h) {
    if (_summaryLoading) return const Center(child: CircularProgressIndicator(color: AppColors.primaryDark, strokeWidth: 2));
    if (_summaryFull == null) return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.article_outlined, size: w * 0.15, color: AppColors.grayLight),
      SizedBox(height: h * 0.015),
      Text('Summary not available yet', style: GoogleFonts.lato(fontSize: w * 0.038, color: AppColors.gray)),
      SizedBox(height: h * 0.008),
      Text('Available after video is processed', style: GoogleFonts.lato(fontSize: w * 0.032, color: AppColors.gray)),
    ]));

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(w * 0.04, h * 0.02, w * 0.04, h * 0.05),
      child: MarkdownBody(
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
    );
  }
}
