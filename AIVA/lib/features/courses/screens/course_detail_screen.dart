import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/course.dart';
import '../../../core/models/lecture.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/auth_service.dart';
import '../../onboarding/screens/onboarding_screen.dart';
import '../../video_player/screens/video_player_screen.dart';

class CourseDetailScreen extends StatefulWidget {
  final Course course;
  const CourseDetailScreen({super.key, required this.course});

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  List<Lecture> _lectures = [];
  bool _isLoading = true;
  bool _isEnrolled = false;
  bool _enrolling = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final courseData = await ApiService.get('/api/courses/${widget.course.id}');
      if (courseData['success'] == true) {
        setState(() {
          _lectures = (courseData['lectures'] as List<dynamic>? ?? [])
              .map((e) => Lecture.fromJson(e as Map<String, dynamic>))
              .toList();
        });
      }
      if (ApiService.hasToken) {
        final myCoursesData = await ApiService.get('/api/my-courses');
        if (myCoursesData['success'] == true) {
          final myCourses = myCoursesData['courses'] as List<dynamic>;
          final found = myCourses.where((c) => (c as Map)['id'] == widget.course.id).toList();
          if (found.isNotEmpty) _isEnrolled = true;
        }
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _enroll() async {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;
    double targetWeeks = 4;

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Container(
          decoration: BoxDecoration(
            color: AppColors.primaryDark,
            borderRadius: BorderRadius.vertical(top: Radius.circular(w * 0.06)),
          ),
          padding: EdgeInsets.fromLTRB(w * 0.06, h * 0.02, w * 0.06, h * 0.04 + MediaQuery.of(ctx).viewInsets.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: w * 0.12,
                height: 4,
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.3), borderRadius: BorderRadius.circular(2)),
              ),
              SizedBox(height: h * 0.03),
              Text('Set Your Goal', style: GoogleFonts.lato(fontSize: w * 0.055, fontWeight: FontWeight.w800, color: Colors.white)),
              SizedBox(height: h * 0.008),
              Text(
                'How many weeks to complete this course?',
                textAlign: TextAlign.center,
                style: GoogleFonts.lato(fontSize: w * 0.036, color: Colors.white60),
              ),
              SizedBox(height: h * 0.025),
              Text(
                '${targetWeeks.round()} weeks',
                style: GoogleFonts.lato(fontSize: w * 0.08, fontWeight: FontWeight.w900, color: AppColors.primaryLime),
              ),
              SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: AppColors.primaryLime,
                  inactiveTrackColor: Colors.white.withOpacity(0.2),
                  thumbColor: AppColors.primaryLime,
                  overlayColor: AppColors.primaryLime.withOpacity(0.2),
                ),
                child: Slider(
                  value: targetWeeks, min: 1, max: 12, divisions: 11,
                  onChanged: (v) => setSheet(() => targetWeeks = v),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('1 week', style: GoogleFonts.lato(fontSize: w * 0.03, color: Colors.white38)),
                  Text('12 weeks', style: GoogleFonts.lato(fontSize: w * 0.03, color: Colors.white38)),
                ],
              ),
              SizedBox(height: h * 0.03),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryLime,
                    foregroundColor: AppColors.primaryDark,
                    padding: EdgeInsets.symmetric(vertical: h * 0.02),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(w * 0.035)),
                    elevation: 0,
                  ),
                  child: Text('Start Learning', style: GoogleFonts.lato(fontSize: w * 0.042, fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed != true) return;

    setState(() => _enrolling = true);
    try {
      // Enrollment now responds instantly (roadmap is generated in background)
      final result = await ApiService.post('/api/enroll', {
        'course_id': widget.course.id,
        'target_weeks': (targetWeeks).round(),
      });
      if (result['success'] == true) {
        setState(() { _isEnrolled = true; _enrolling = false; });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Enrolled! Start learning now.'),
          backgroundColor: AppColors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      } else {
        setState(() => _enrolling = false);
        if (!mounted) return;

        // Session expired — clear stale token and send user to login
        if (result['session_expired'] == true) {
          await AuthService.logout();
          if (!mounted) return;
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const OnboardingScreen()),
            (route) => false,
          );
          return;
        }

        final errMsg = result['error']?.toString()
            ?? result['message']?.toString()
            ?? 'Enrollment failed. Please try again.';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(errMsg),
          backgroundColor: AppColors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } catch (e) {
      setState(() => _enrolling = false);
      if (!mounted) return;
      final msg = e.toString().contains('TimeoutException')
          ? 'Request timed out. Please check your connection and try again.'
          : 'Could not connect to server. Please try again.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  Color _parsedColor() {
    try {
      final h = widget.course.thumbnailColor.replaceAll('#', '');
      return Color(int.parse('FF$h', radix: 16));
    } catch (_) {
      return AppColors.purple;
    }
  }

  void _startLearning() {
    if (_lectures.isNotEmpty) {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => VideoPlayerScreen(
          lectureId: _lectures.first.id,
          title: _lectures.first.title,
          courseId: widget.course.id,
        ),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;
    final color = _parsedColor();

    return Scaffold(
      backgroundColor: AppColors.lightBg,
      body: CustomScrollView(
        slivers: [
          _buildHeroAppBar(w, h, color),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTitleSection(w, h, color),
                SizedBox(height: h * 0.01),
                if (widget.course.description?.isNotEmpty == true)
                  _buildAboutSection(w, h),
                SizedBox(height: h * 0.01),
                _buildCurriculumSection(w, h, color),
                SizedBox(height: h * 0.14),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(w, h, color),
    );
  }

  // ─── Hero App Bar ─────────────────────────────────────────────────────────

  Widget _buildHeroAppBar(double w, double h, Color color) {
    return SliverAppBar(
      expandedHeight: h * 0.3,
      pinned: true,
      backgroundColor: color,
      automaticallyImplyLeading: false,
      elevation: 0,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: EdgeInsets.all(w * 0.02),
          decoration: BoxDecoration(color: Colors.black26, shape: BoxShape.circle),
          child: Icon(Icons.arrow_back_rounded, color: Colors.white, size: w * 0.055),
        ),
      ),
      actions: [
        Container(
          margin: EdgeInsets.all(w * 0.02),
          decoration: BoxDecoration(color: Colors.black26, shape: BoxShape.circle),
          child: IconButton(
            onPressed: () {},
            icon: Icon(Icons.share_outlined, color: Colors.white, size: w * 0.05),
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(minWidth: w * 0.1, minHeight: w * 0.1),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color, color.withOpacity(0.75)],
            ),
          ),
          child: Stack(
            children: [
              // Background letter watermark
              Center(
                child: Text(
                  widget.course.title.isNotEmpty ? widget.course.title[0].toUpperCase() : 'A',
                  style: GoogleFonts.lato(
                    fontSize: w * 0.5,
                    fontWeight: FontWeight.w900,
                    color: Colors.white.withOpacity(0.07),
                  ),
                ),
              ),
              // Enrolled badge
              if (_isEnrolled)
                Positioned(
                  bottom: h * 0.025,
                  left: w * 0.05,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: w * 0.03, vertical: h * 0.006),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLime,
                      borderRadius: BorderRadius.circular(w * 0.02),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.check_circle_rounded, size: w * 0.035, color: AppColors.primaryDark),
                      SizedBox(width: w * 0.01),
                      Text('ENROLLED', style: GoogleFonts.lato(fontSize: w * 0.028, fontWeight: FontWeight.w800, color: AppColors.primaryDark)),
                    ]),
                  ),
                ),
              // Play button center
              Center(
                child: Container(
                  padding: EdgeInsets.all(w * 0.04),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white38, width: 2),
                  ),
                  child: Icon(Icons.play_arrow_rounded, color: Colors.white, size: w * 0.1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Title + Stats Section ────────────────────────────────────────────────

  Widget _buildTitleSection(double w, double h, Color color) {
    return Container(
      color: AppColors.white,
      padding: EdgeInsets.fromLTRB(w * 0.05, h * 0.025, w * 0.05, h * 0.02),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.course.title,
            style: GoogleFonts.lato(fontSize: w * 0.058, fontWeight: FontWeight.w800, color: AppColors.primaryDark, height: 1.2),
          ),

          SizedBox(height: h * 0.015),

          // Stats row
          Row(
            children: [
              _statChip(Icons.person_outline_rounded, widget.course.instructor ?? 'AIVA', color, w),
              _divider(w),
              _statChip(Icons.signal_cellular_alt_rounded, widget.course.level, AppColors.purple, w),
              _divider(w),
              _statChip(Icons.schedule_rounded, '${widget.course.estimatedHours}h', AppColors.teal, w),
            ],
          ),

          if (_isEnrolled) ...[
            SizedBox(height: h * 0.018),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Your progress', style: GoogleFonts.lato(fontSize: w * 0.032, color: AppColors.gray, fontWeight: FontWeight.w500)),
                  Text('In progress', style: GoogleFonts.lato(fontSize: w * 0.032, color: color, fontWeight: FontWeight.w600)),
                ],
              ),
              SizedBox(height: h * 0.006),
              ClipRRect(
                borderRadius: BorderRadius.circular(w * 0.01),
                child: LinearProgressIndicator(
                  value: 0.0,
                  backgroundColor: AppColors.grayLight,
                  valueColor: AlwaysStoppedAnimation(color),
                  minHeight: h * 0.008,
                ),
              ),
            ]),
          ],

          if (_error != null) ...[
            SizedBox(height: h * 0.012),
            Container(
              padding: EdgeInsets.all(w * 0.03),
              decoration: BoxDecoration(
                color: AppColors.red.withOpacity(0.08),
                borderRadius: BorderRadius.circular(w * 0.02),
              ),
              child: Text(_error!, style: GoogleFonts.lato(color: AppColors.red, fontSize: w * 0.03)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statChip(IconData icon, String label, Color color, double w) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: w * 0.036, color: color),
      SizedBox(width: w * 0.01),
      Flexible(
        child: Text(
          label,
          style: GoogleFonts.lato(fontSize: w * 0.032, color: AppColors.gray, fontWeight: FontWeight.w500),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ]);
  }

  Widget _divider(double w) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: w * 0.025),
      child: Text('·', style: GoogleFonts.lato(fontSize: w * 0.04, color: AppColors.grayLight)),
    );
  }

  // ─── About Section ────────────────────────────────────────────────────────

  Widget _buildAboutSection(double w, double h) {
    return Container(
      color: AppColors.white,
      padding: EdgeInsets.all(w * 0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('About', style: GoogleFonts.lato(fontSize: w * 0.045, fontWeight: FontWeight.w800, color: AppColors.primaryDark)),
          SizedBox(height: h * 0.01),
          Text(
            widget.course.description!,
            style: GoogleFonts.lato(fontSize: w * 0.036, color: AppColors.grayDark, height: 1.65),
          ),
        ],
      ),
    );
  }

  // ─── Curriculum Section ───────────────────────────────────────────────────

  Widget _buildCurriculumSection(double w, double h, Color color) {
    if (_isLoading) {
      return Container(
        color: AppColors.white,
        padding: EdgeInsets.symmetric(vertical: h * 0.05),
        child: const Center(child: CircularProgressIndicator(color: AppColors.primaryDark, strokeWidth: 2)),
      );
    }
    if (_lectures.isEmpty) return const SizedBox.shrink();

    final totalDuration = _lectures.fold<int>(0, (sum, l) => sum + l.durationMinutes);
    final totalStr = totalDuration >= 60
        ? '${totalDuration ~/ 60}h ${totalDuration % 60}m'
        : '${totalDuration}m';

    return Container(
      color: AppColors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(w * 0.05, h * 0.022, w * 0.05, h * 0.005),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Curriculum', style: GoogleFonts.lato(fontSize: w * 0.045, fontWeight: FontWeight.w800, color: AppColors.primaryDark)),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('${_lectures.length} lectures', style: GoogleFonts.lato(fontSize: w * 0.03, color: AppColors.gray, fontWeight: FontWeight.w600)),
                  if (totalDuration > 0)
                    Text(totalStr, style: GoogleFonts.lato(fontSize: w * 0.028, color: AppColors.gray)),
                ]),
              ],
            ),
          ),

          Divider(height: 1, color: AppColors.grayLight),

          ..._lectures.asMap().entries.map((e) => _buildLectureRow(e.key, e.value, w, h, color)),
        ],
      ),
    );
  }

  Widget _buildLectureRow(int index, Lecture lec, double w, double h, Color color) {
    final canPlay = _isEnrolled && lec.id.isNotEmpty;

    return GestureDetector(
      onTap: canPlay
          ? () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => VideoPlayerScreen(lectureId: lec.id, title: lec.title, courseId: widget.course.id),
              ))
          : null,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: w * 0.05, vertical: h * 0.016),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.grayLight, width: 0.5)),
        ),
        child: Row(
          children: [
            // Index number or status icon
            Container(
              width: w * 0.085,
              height: w * 0.085,
              decoration: BoxDecoration(
                color: canPlay ? color.withOpacity(0.1) : AppColors.lightBg,
                borderRadius: BorderRadius.circular(w * 0.022),
              ),
              child: Center(
                child: canPlay
                    ? Icon(Icons.play_arrow_rounded, color: color, size: w * 0.045)
                    : Text(
                        '${index + 1}',
                        style: GoogleFonts.lato(fontSize: w * 0.032, fontWeight: FontWeight.w700, color: AppColors.gray),
                      ),
              ),
            ),

            SizedBox(width: w * 0.035),

            // Title + duration
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lec.title,
                    style: GoogleFonts.lato(
                      fontSize: w * 0.036,
                      fontWeight: FontWeight.w600,
                      color: canPlay ? AppColors.primaryDark : AppColors.gray,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (lec.durationMinutes > 0) ...[
                    SizedBox(height: h * 0.004),
                    Row(children: [
                      Icon(Icons.schedule_rounded, size: w * 0.03, color: AppColors.gray),
                      SizedBox(width: w * 0.01),
                      Text('${lec.durationMinutes} min', style: GoogleFonts.lato(fontSize: w * 0.028, color: AppColors.gray)),
                    ]),
                  ],
                ],
              ),
            ),

            // Right icon
            Icon(
              canPlay ? Icons.chevron_right_rounded : Icons.lock_outline_rounded,
              size: w * 0.05,
              color: canPlay ? AppColors.gray : AppColors.grayLight,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Bottom CTA ───────────────────────────────────────────────────────────

  Widget _buildBottomBar(double w, double h, Color color) {
    if (_isLoading) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.fromLTRB(w * 0.05, h * 0.015, w * 0.05, h * 0.025),
      decoration: const BoxDecoration(
        color: AppColors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 16, offset: Offset(0, -4))],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (_isEnrolled) ...[
              // Lecture count badge
              Container(
                padding: EdgeInsets.symmetric(horizontal: w * 0.035, vertical: h * 0.015),
                decoration: BoxDecoration(
                  color: AppColors.lightBg,
                  borderRadius: BorderRadius.circular(w * 0.03),
                  border: Border.all(color: AppColors.grayLight),
                ),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('${_lectures.length}', style: GoogleFonts.lato(fontSize: w * 0.04, fontWeight: FontWeight.w800, color: AppColors.primaryDark)),
                  Text('lectures', style: GoogleFonts.lato(fontSize: w * 0.025, color: AppColors.gray)),
                ]),
              ),
              SizedBox(width: w * 0.03),
            ],
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _enrolling ? null : (_isEnrolled ? _startLearning : _enroll),
                icon: _enrolling
                    ? SizedBox(width: w * 0.045, height: w * 0.045, child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : Icon(_isEnrolled ? Icons.play_arrow_rounded : Icons.school_rounded, size: w * 0.055),
                label: Text(
                  _enrolling ? 'Enrolling...' : (_isEnrolled ? 'Continue Learning' : 'Enroll — Free'),
                  style: GoogleFonts.lato(fontSize: w * 0.04, fontWeight: FontWeight.w800),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isEnrolled ? color : AppColors.primaryDark,
                  foregroundColor: _isEnrolled ? AppColors.white : AppColors.primaryLime,
                  disabledBackgroundColor: AppColors.grayLight,
                  elevation: 0,
                  minimumSize: Size(double.infinity, h * 0.065),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(w * 0.035)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
