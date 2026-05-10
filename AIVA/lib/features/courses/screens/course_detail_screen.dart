import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/course.dart';
import '../../../core/models/lecture.dart';
import '../../../core/services/api_service.dart';
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
  String? _enrollmentId;
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
      // Load lectures
      final courseData = await ApiService.get('/api/courses/${widget.course.id}');
      if (courseData['success'] == true) {
        setState(() {
          _lectures = (courseData['lectures'] as List<dynamic>? ?? [])
              .map((e) => Lecture.fromJson(e as Map<String, dynamic>))
              .toList();
        });
      }
      // Check enrollment
      if (ApiService.hasToken) {
        final myCoursesData = await ApiService.get('/api/my-courses');
        if (myCoursesData['success'] == true) {
          final myCourses = myCoursesData['courses'] as List<dynamic>;
          final found = myCourses.where((c) => (c as Map)['id'] == widget.course.id).toList();
          if (found.isNotEmpty) {
            _isEnrolled = true;
            _enrollmentId = (found.first as Map)['enrollment_id'] as String?;
          }
        }
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _enroll() async {
    final dvpw = MediaQuery.of(context).size.width;
    final dvph = MediaQuery.of(context).size.height;
    double targetWeeks = 4;

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Container(
          decoration: BoxDecoration(
            color: AppColors.primaryDark,
            borderRadius: BorderRadius.vertical(top: Radius.circular(dvpw * 0.06)),
          ),
          padding: EdgeInsets.fromLTRB(dvpw * 0.06, dvph * 0.02, dvpw * 0.06, dvph * 0.04),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: dvpw * 0.12,
                height: 4,
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.3), borderRadius: BorderRadius.circular(2)),
              ),
              SizedBox(height: dvph * 0.03),
              Text(
                'Set Your Goal',
                style: GoogleFonts.lato(fontSize: dvpw * 0.055, fontWeight: FontWeight.w800, color: Colors.white),
              ),
              SizedBox(height: dvph * 0.01),
              Text(
                'In how many weeks do you want to complete this course?',
                textAlign: TextAlign.center,
                style: GoogleFonts.lato(fontSize: dvpw * 0.038, color: Colors.white60),
              ),
              SizedBox(height: dvph * 0.03),
              Text(
                '${targetWeeks.round()} weeks',
                style: GoogleFonts.lato(fontSize: dvpw * 0.08, fontWeight: FontWeight.w800, color: AppColors.primaryLime),
              ),
              SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: AppColors.primaryLime,
                  inactiveTrackColor: Colors.white.withOpacity(0.2),
                  thumbColor: AppColors.primaryLime,
                  overlayColor: AppColors.primaryLime.withOpacity(0.2),
                ),
                child: Slider(
                  value: targetWeeks,
                  min: 1,
                  max: 12,
                  divisions: 11,
                  onChanged: (v) => setSheet(() => targetWeeks = v),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('1 week', style: GoogleFonts.lato(fontSize: dvpw * 0.03, color: Colors.white38)),
                  Text('12 weeks', style: GoogleFonts.lato(fontSize: dvpw * 0.03, color: Colors.white38)),
                ],
              ),
              SizedBox(height: dvph * 0.03),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryLime,
                    foregroundColor: AppColors.primaryDark,
                    padding: EdgeInsets.symmetric(vertical: dvph * 0.02),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(dvpw * 0.035)),
                  ),
                  child: Text('Start Learning', style: GoogleFonts.lato(fontSize: dvpw * 0.042, fontWeight: FontWeight.w700)),
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
      final result = await ApiService.post('/api/enroll', {
        'course_id': widget.course.id,
        'target_weeks': targetWeeks.round(),
      });
      if (result['success'] == true) {
        setState(() { _isEnrolled = true; _enrollmentId = result['enrollment_id'] as String?; _enrolling = false; });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Enrolled! Start learning now.'), backgroundColor: AppColors.green, behavior: SnackBarBehavior.floating));
      } else {
        setState(() => _enrolling = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']?.toString() ?? 'Enrollment failed'),
              backgroundColor: AppColors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _enrolling = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Network error: $e'),
            backgroundColor: AppColors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
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
        builder: (_) => VideoPlayerScreen(lectureId: _lectures.first.id, title: _lectures.first.title, courseId: widget.course.id),
      ));
    }
  }

  Widget _statChip(IconData icon, String label, Color color, double w) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: w * 0.035, color: color),
      SizedBox(width: w * 0.012),
      Text(label, style: GoogleFonts.lato(fontSize: w * 0.032, color: AppColors.gray, fontWeight: FontWeight.w500)),
    ]);
  }

  Widget _buildProgressBar(double w, double h, Color color) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(w * 0.01),
        child: LinearProgressIndicator(
          value: 0.0,
          backgroundColor: AppColors.grayLight,
          valueColor: AlwaysStoppedAnimation(color),
          minHeight: h * 0.008,
        ),
      ),
      SizedBox(height: h * 0.005),
      Text('In progress', style: GoogleFonts.lato(fontSize: w * 0.028, color: AppColors.gray)),
    ]);
  }

  Widget _lectureRow(int index, Lecture lec, double w, double h, Color color) {
    final canPlay = _isEnrolled && lec.id.isNotEmpty;
    return GestureDetector(
      onTap: canPlay ? () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => VideoPlayerScreen(lectureId: lec.id, title: lec.title, courseId: widget.course.id),
      )) : null,
      child: Container(
        margin: EdgeInsets.only(bottom: h * 0.008),
        padding: EdgeInsets.symmetric(horizontal: w * 0.02, vertical: h * 0.015),
        decoration: BoxDecoration(
          color: AppColors.lightBg,
          borderRadius: BorderRadius.circular(w * 0.025),
        ),
        child: Row(children: [
          Container(
            width: w * 0.08, height: w * 0.08,
            decoration: BoxDecoration(
              color: canPlay ? color.withOpacity(0.12) : AppColors.grayLight,
              shape: BoxShape.circle,
            ),
            child: Center(child: Text('${index + 1}', style: GoogleFonts.lato(fontSize: w * 0.032, fontWeight: FontWeight.w700, color: canPlay ? color : AppColors.gray))),
          ),
          SizedBox(width: w * 0.03),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(lec.title, style: GoogleFonts.lato(fontSize: w * 0.036, fontWeight: FontWeight.w600, color: AppColors.primaryDark), maxLines: 2, overflow: TextOverflow.ellipsis),
            if (lec.durationMinutes > 0)
              Text('${lec.durationMinutes} min', style: GoogleFonts.lato(fontSize: w * 0.028, color: AppColors.gray)),
          ])),
          Icon(
            canPlay ? Icons.play_circle_rounded : Icons.lock_outline_rounded,
            size: w * 0.055,
            color: canPlay ? color : AppColors.grayLight,
          ),
        ]),
      ),
    );
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
          // Collapsible header
          SliverAppBar(
            expandedHeight: h * 0.28,
            pinned: true,
            backgroundColor: color,
            automaticallyImplyLeading: false,
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: EdgeInsets.all(w * 0.02),
                decoration: const BoxDecoration(color: Colors.black26, shape: BoxShape.circle),
                child: Icon(Icons.arrow_back_rounded, color: Colors.white, size: w * 0.055),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: [color, color.withOpacity(0.7)],
                  ),
                ),
                child: Stack(
                  children: [
                    Center(child: Text(
                      widget.course.title.isNotEmpty ? widget.course.title[0].toUpperCase() : 'A',
                      style: GoogleFonts.lato(fontSize: w * 0.45, fontWeight: FontWeight.w900, color: Colors.white.withOpacity(0.08)),
                    )),
                    Positioned(
                      bottom: h * 0.025, left: w * 0.05, right: w * 0.05,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_isEnrolled)
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: w * 0.025, vertical: h * 0.005),
                              decoration: BoxDecoration(color: AppColors.primaryLime, borderRadius: BorderRadius.circular(w * 0.02)),
                              child: Text('ENROLLED', style: GoogleFonts.lato(fontSize: w * 0.025, fontWeight: FontWeight.w800, color: AppColors.primaryDark)),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Container(
              color: AppColors.lightBg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title card
                  Container(
                    width: double.infinity,
                    color: AppColors.white,
                    padding: EdgeInsets.fromLTRB(w * 0.05, h * 0.025, w * 0.05, h * 0.02),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.course.title, style: GoogleFonts.lato(fontSize: w * 0.058, fontWeight: FontWeight.w800, color: AppColors.primaryDark, height: 1.2)),
                        SizedBox(height: h * 0.012),
                        // Stats row
                        Row(children: [
                          _statChip(Icons.person_rounded, widget.course.instructor ?? 'AIVA', color, w),
                          SizedBox(width: w * 0.02),
                          _statChip(Icons.bar_chart_rounded, widget.course.level, AppColors.purple, w),
                          SizedBox(width: w * 0.02),
                          _statChip(Icons.schedule_rounded, '${widget.course.estimatedHours}h', AppColors.teal, w),
                        ]),
                        if (_isEnrolled) ...[
                          SizedBox(height: h * 0.015),
                          _buildProgressBar(w, h, color),
                        ],
                        if (_error != null) ...[
                          SizedBox(height: h * 0.01),
                          Text(_error!, style: GoogleFonts.lato(color: AppColors.red, fontSize: w * 0.032)),
                        ],
                      ],
                    ),
                  ),

                  SizedBox(height: h * 0.01),

                  // Description
                  if (widget.course.description?.isNotEmpty == true)
                    Container(
                      color: AppColors.white,
                      padding: EdgeInsets.all(w * 0.05),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('About', style: GoogleFonts.lato(fontSize: w * 0.045, fontWeight: FontWeight.w800, color: AppColors.primaryDark)),
                          SizedBox(height: h * 0.01),
                          Text(widget.course.description!, style: GoogleFonts.lato(fontSize: w * 0.036, color: AppColors.gray, height: 1.6)),
                        ],
                      ),
                    ),

                  SizedBox(height: h * 0.01),

                  // Curriculum
                  if (!_isLoading && _lectures.isNotEmpty)
                    Container(
                      color: AppColors.white,
                      padding: EdgeInsets.fromLTRB(w * 0.05, h * 0.02, w * 0.05, h * 0.01),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Curriculum', style: GoogleFonts.lato(fontSize: w * 0.045, fontWeight: FontWeight.w800, color: AppColors.primaryDark)),
                              Text('${_lectures.length} lectures', style: GoogleFonts.lato(fontSize: w * 0.032, color: AppColors.gray)),
                            ],
                          ),
                          SizedBox(height: h * 0.015),
                          ..._lectures.asMap().entries.map((e) => _lectureRow(e.key, e.value, w, h, color)),
                        ],
                      ),
                    ),

                  if (_isLoading)
                    Container(
                      color: AppColors.white,
                      padding: EdgeInsets.symmetric(vertical: h * 0.05),
                      child: const Center(child: CircularProgressIndicator(color: AppColors.primaryDark, strokeWidth: 2)),
                    ),

                  SizedBox(height: h * 0.14),
                ],
              ),
            ),
          ),
        ],
      ),

      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(w * 0.05, h * 0.015, w * 0.05, h * 0.025),
        decoration: const BoxDecoration(
          color: AppColors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, -3))],
        ),
        child: SafeArea(
          top: false,
          child: _isLoading
              ? const SizedBox.shrink()
              : ElevatedButton(
                  onPressed: _enrolling ? null : (_isEnrolled ? _startLearning : _enroll),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: AppColors.white,
                    disabledBackgroundColor: AppColors.grayLight,
                    elevation: 0,
                    minimumSize: Size(double.infinity, h * 0.065),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(w * 0.035)),
                  ),
                  child: _enrolling
                      ? SizedBox(width: w * 0.05, height: w * 0.05, child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : Text(_isEnrolled ? 'Continue Learning' : 'Enroll — Free', style: GoogleFonts.lato(fontSize: w * 0.042, fontWeight: FontWeight.w800)),
                ),
        ),
      ),
    );
  }
}
