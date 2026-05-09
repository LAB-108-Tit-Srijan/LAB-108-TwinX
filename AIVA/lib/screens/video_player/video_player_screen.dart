import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../controllers/video_controller.dart';
import '../../data/models/lecture_model.dart';
import '../../data/models/doubt_model.dart';
import '../../data/mock/mock_data.dart';

class VideoPlayerScreen extends StatelessWidget {
  const VideoPlayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lecture = Get.arguments as LectureModel? ?? MockData.lectures.first;
    final ctrl = Get.find<VideoController>();

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(lecture: lecture),
            _VideoPlayer(ctrl: ctrl, lecture: lecture),
            _TabBar(ctrl: ctrl),
            Expanded(
              child: Obx(() => IndexedStack(
                    index: ctrl.selectedTab.value,
                    children: [
                      _OverviewTab(lecture: lecture),
                      _AivaTab(ctrl: ctrl),
                      _NotesTab(lecture: lecture),
                    ],
                  )),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final LectureModel lecture;
  const _TopBar({required this.lecture});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded,
                color: AppColors.textPrimary),
            onPressed: Get.back,
          ),
          Expanded(
            child: Text(
              lecture.title,
              style: AppTextStyles.labelLarge,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined, color: AppColors.textSecondary),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

class _VideoPlayer extends StatelessWidget {
  final VideoController ctrl;
  final LectureModel lecture;
  const _VideoPlayer({required this.ctrl, required this.lecture});

  List<Color> get _colors {
    switch (lecture.thumbnailGradient) {
      case 'cyan':
        return [const Color(0xFF00D4FF), const Color(0xFF0096C7)];
      case 'purple':
        return [const Color(0xFF8B5CF6), const Color(0xFF7C3AED)];
      default:
        return [AppColors.accentPrimary, const Color(0xFF8B5CF6)];
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return Container(
      width: w,
      height: w * 9 / 16,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Center(
            child: Obx(() => GestureDetector(
                  onTap: ctrl.togglePlay,
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      ctrl.isPlaying.value
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                )),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
              child: Column(
                children: [
                  Obx(() => SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: AppColors.accentSecondary,
                          inactiveTrackColor:
                              Colors.white.withOpacity(0.3),
                          thumbColor: Colors.white,
                          trackHeight: 3,
                          thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 6),
                          overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 14),
                        ),
                        child: Slider(
                          value: ctrl.progress.value,
                          onChanged: ctrl.seekTo,
                        ),
                      )),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Obx(() => Text(ctrl.currentTime.value,
                          style: AppTextStyles.bodySmall
                              .copyWith(color: Colors.white))),
                      Row(
                        children: [
                          Obx(() => PopupMenuButton<double>(
                                onSelected: ctrl.changeSpeed,
                                itemBuilder: (_) => [1.0, 1.25, 1.5, 2.0]
                                    .map((s) => PopupMenuItem(
                                          value: s,
                                          child: Text('${s}x'),
                                        ))
                                    .toList(),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${ctrl.playbackSpeed.value}x',
                                    style: AppTextStyles.bodySmall
                                        .copyWith(color: Colors.white),
                                  ),
                                ),
                              )),
                          const SizedBox(width: 8),
                          Obx(() => Text(ctrl.totalTime.value,
                              style: AppTextStyles.bodySmall
                                  .copyWith(color: Colors.white))),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabBar extends StatelessWidget {
  final VideoController ctrl;
  const _TabBar({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.backgroundCard,
        border: Border(bottom: BorderSide(color: AppColors.borderColor)),
      ),
      child: Obx(() => Row(
            children: [
              _Tab('Overview', 0, ctrl),
              _Tab('AIVA ✨', 1, ctrl),
              _Tab('Notes', 2, ctrl),
            ],
          )),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final int index;
  final VideoController ctrl;
  const _Tab(this.label, this.index, this.ctrl);

  @override
  Widget build(BuildContext context) {
    final selected = ctrl.selectedTab.value == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => ctrl.selectTab(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? AppColors.accentPrimary : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.labelMedium.copyWith(
              color: selected ? AppColors.accentPrimary : AppColors.textSecondary,
              fontWeight:
                  selected ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}

class _AivaTab extends StatefulWidget {
  final VideoController ctrl;
  const _AivaTab({required this.ctrl});

  @override
  State<_AivaTab> createState() => _AivaTabState();
}

class _AivaTabState extends State<_AivaTab> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _send() {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;
    _inputCtrl.clear();
    widget.ctrl.askDoubt(text);
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('AIVA Chat', style: AppTextStyles.labelLarge),
              Obx(() => GestureDetector(
                    onTap: widget.ctrl.toggleLanguage,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.accentPrimary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: AppColors.accentPrimary.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('EN',
                              style: AppTextStyles.labelMedium.copyWith(
                                color: !widget.ctrl.isHindi.value
                                    ? AppColors.accentPrimary
                                    : AppColors.textHint,
                                fontWeight:
                                    !widget.ctrl.isHindi.value
                                        ? FontWeight.w700
                                        : FontWeight.w400,
                              )),
                          Text(' | ',
                              style: AppTextStyles.labelMedium
                                  .copyWith(color: AppColors.textHint)),
                          Text('हिं',
                              style: AppTextStyles.labelMedium.copyWith(
                                color: widget.ctrl.isHindi.value
                                    ? AppColors.accentPrimary
                                    : AppColors.textHint,
                                fontWeight: widget.ctrl.isHindi.value
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                              )),
                        ],
                      ),
                    ),
                  )),
            ],
          ),
        ),
        Expanded(
          child: Obx(() => ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.all(16),
                itemCount: widget.ctrl.chatMessages.length +
                    (widget.ctrl.isTyping.value ? 1 : 0),
                itemBuilder: (_, i) {
                  if (i == widget.ctrl.chatMessages.length &&
                      widget.ctrl.isTyping.value) {
                    return _TypingIndicator();
                  }
                  final msg = widget.ctrl.chatMessages[i];
                  return msg.isAi
                      ? _AiBubble(doubt: msg)
                      : _UserBubble(doubt: msg);
                },
              )),
        ),
        _QuickActions(ctrl: widget.ctrl),
        _InputBar(ctrl: _inputCtrl, onSend: _send),
      ],
    );
  }
}

class _UserBubble extends StatelessWidget {
  final DoubtModel doubt;
  const _UserBubble({required this.doubt});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16, left: 40),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(4),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(
                color: AppColors.accentPrimary.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Text(doubt.question,
            style: AppTextStyles.bodyMedium.copyWith(color: Colors.white)),
      ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.2),
    );
  }
}

class _AiBubble extends StatefulWidget {
  final DoubtModel doubt;
  const _AiBubble({required this.doubt});

  @override
  State<_AiBubble> createState() => _AiBubbleState();
}

class _AiBubbleState extends State<_AiBubble> {
  String _displayed = '';
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _typewriter();
  }

  void _typewriter() async {
    final words = widget.doubt.answer.split(' ');
    for (final word in words) {
      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 35));
      setState(() => _displayed += '$word ');
    }
    setState(() => _done = true);
  }

  @override
  Widget build(BuildContext context) {
    final text = _done ? widget.doubt.answer : _displayed;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          margin: const EdgeInsets.only(right: 10, bottom: 16),
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Text('A',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14)),
          ),
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: 16, right: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.backgroundCard,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              border: Border.all(color: AppColors.borderColor),
              boxShadow: [
                BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 8,
                    offset: const Offset(0, 2)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(text,
                    style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textPrimary, height: 1.6)),
                if (_done) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: [
                      _TimestampChip(
                          label: '📍 From ${widget.doubt.timestamp}'),
                      if (widget.doubt.language == 'EN')
                        const _TimestampChip(
                            label: '🔗 Also Lecture 4 · 18:22'),
                    ],
                  ),
                ],
              ],
            ),
          ).animate().fadeIn(duration: 300.ms).slideX(begin: -0.2),
        ),
      ],
    );
  }
}

class _TimestampChip extends StatelessWidget {
  final String label;
  const _TimestampChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.accentPrimary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: AppColors.accentPrimary.withOpacity(0.2)),
        ),
        child: Text(label,
            style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.accentPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 11)),
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with TickerProviderStateMixin {
  late List<AnimationController> _ctrls;

  @override
  void initState() {
    super.initState();
    _ctrls = List.generate(
      3,
      (i) => AnimationController(
          vsync: this, duration: const Duration(milliseconds: 600))
        ..repeat(reverse: true, min: 0, max: 1,
            period: Duration(milliseconds: 600 + i * 150)),
    );
  }

  @override
  void dispose() {
    for (final c in _ctrls) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            margin: const EdgeInsets.only(right: 10),
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('A',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14)),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.backgroundCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderColor),
            ),
            child: Row(
              children: List.generate(
                3,
                (i) => AnimatedBuilder(
                  animation: _ctrls[i],
                  builder: (_, __) => Container(
                    width: 7,
                    height: 7,
                    margin: EdgeInsets.only(right: i < 2 ? 4 : 0),
                    decoration: BoxDecoration(
                      color: AppColors.accentPrimary
                          .withOpacity(0.4 + _ctrls[i].value * 0.6),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  final VideoController ctrl;
  const _QuickActions({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: ['📝 Summary', '🔗 Related', '💡 Explain Simply']
            .map((a) => GestureDetector(
                  onTap: () => ctrl.sendQuickAction(a),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundSecondary,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.borderColor),
                    ),
                    child: Text(a,
                        style: AppTextStyles.labelMedium
                            .copyWith(color: AppColors.accentPrimary)),
                  ),
                ))
            .toList(),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController ctrl;
  final VoidCallback onSend;
  const _InputBar({required this.ctrl, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: const BoxDecoration(
        color: AppColors.backgroundCard,
        border: Border(top: BorderSide(color: AppColors.borderColor)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.mic_none_rounded,
                color: AppColors.textSecondary),
            onPressed: () {},
          ),
          Expanded(
            child: TextField(
              controller: ctrl,
              onSubmitted: (_) => onSend(),
              decoration: InputDecoration(
                hintText: 'Ask any doubt...',
                hintStyle: AppTextStyles.hint,
                filled: true,
                fillColor: AppColors.backgroundSecondary,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onSend,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentPrimary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.send_rounded,
                  color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final LectureModel lecture;
  const _OverviewTab({required this.lecture});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(lecture.title, style: AppTextStyles.headingMedium),
          const SizedBox(height: 8),
          Text(lecture.description,
              style: AppTextStyles.bodyMedium.copyWith(height: 1.6)),
          const SizedBox(height: 20),
          Text('Topics Covered', style: AppTextStyles.headingSmall),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: lecture.topics
                .map((t) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.accentPrimary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: AppColors.accentPrimary.withOpacity(0.2)),
                      ),
                      child: Text(t,
                          style: AppTextStyles.labelMedium.copyWith(
                              color: AppColors.accentPrimary)),
                    ))
                .toList(),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.backgroundSecondary,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderColor),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      lecture.instructorName[0],
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(lecture.instructorName,
                        style: AppTextStyles.labelLarge),
                    Text('Instructor · ${lecture.courseName}',
                        style: AppTextStyles.bodySmall),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NotesTab extends StatelessWidget {
  final LectureModel lecture;
  const _NotesTab({required this.lecture});

  @override
  Widget build(BuildContext context) {
    final notes = '''# ${lecture.title}

## Key Concepts

${lecture.topics.asMap().entries.map((e) => '${e.key + 1}. **${e.value}** — Core concept covered in this lecture').join('\n')}

## Summary

${lecture.description}

## Important Points

- Pay attention to the examples given between 20:00 - 35:00
- The comparison demo at the end is especially important for interviews
- Practice the code examples shown at 42:31

## AIVA Generated Notes
*Automatically generated from lecture content*
''';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Lecture Notes', style: AppTextStyles.headingSmall),
              GestureDetector(
                onTap: () {},
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.download_rounded,
                          color: Colors.white, size: 16),
                      const SizedBox(width: 6),
                      Text('PDF',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.backgroundSecondary,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderColor),
            ),
            child: Text(notes,
                style: AppTextStyles.bodyMedium.copyWith(height: 1.8)),
          ),
        ],
      ),
    );
  }
}
