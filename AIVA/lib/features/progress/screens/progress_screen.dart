import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/profile_service.dart';
import '../../../core/services/notes_service.dart';
import '../../../core/services/quiz_service.dart';
import '../models/progress_data.dart';
import '../../profile/models/profile_data.dart';

class ProgressScreen extends StatefulWidget {
  final int initialTabIndex;

  const ProgressScreen({super.key, this.initialTabIndex = 0});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Subject? _selectedSubject;
  Chapter? _selectedChapter;
  String _currentView = 'subjects'; // subjects, chapters, topics, files

  // Real data
  List<Map<String, dynamic>> _enrolledCourses = [];
  Map<String, dynamic>? _creditsData;
  bool _coursesLoading = true;
  bool _creditsLoading = true;

  // Notes state
  String? _notesLectureId;
  String? _notesContent;
  bool _notesLoading = false;
  List<Map<String, dynamic>> _notesLectures = [];
  String? _notesCourseId;

  // Quiz state
  Map<String, dynamic>? _activeQuiz;
  String? _quizLectureId;
  bool _quizLoading = false;
  List<Map<String, dynamic>> _quizLectures = [];
  String? _quizCourseId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
    _loadEnrolledCourses();
    _loadCredits();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadEnrolledCourses() async {
    setState(() => _coursesLoading = true);
    try {
      final data = await ApiService.get('/api/my-courses');
      if (mounted && data['success'] == true) {
        setState(() {
          _enrolledCourses = List<Map<String, dynamic>>.from(
            data['courses'] as List<dynamic>? ?? [],
          );
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _coursesLoading = false);
  }

  Future<void> _loadCredits() async {
    setState(() => _creditsLoading = true);
    try {
      final data = await ProfileService.getCredits();
      if (mounted) {
        setState(() => _creditsData = data);
      }
    } catch (_) {}
    if (mounted) setState(() => _creditsLoading = false);
  }

  Future<void> _loadNotesLectures(String courseId) async {
    setState(() {
      _notesCourseId = courseId;
      _notesLectures = [];
      _notesContent = null;
      _notesLectureId = null;
    });
    try {
      final data = await ApiService.get('/api/courses/$courseId');
      if (mounted && data['success'] == true) {
        setState(() {
          _notesLectures = List<Map<String, dynamic>>.from(
            data['lectures'] as List<dynamic>? ?? [],
          );
        });
      }
    } catch (_) {}
  }

  Future<void> _loadNotes(String lectureId) async {
    setState(() {
      _notesLectureId = lectureId;
      _notesLoading = true;
      _notesContent = null;
    });
    try {
      final data = await NotesService.getLectureNotes(lectureId);
      if (mounted) {
        setState(() {
          _notesContent = data['notes']?.toString() ?? data['content']?.toString() ?? 'No notes available for this lecture.';
          _notesLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _notesContent = 'Failed to load notes: $e';
          _notesLoading = false;
        });
      }
    }
  }

  Future<void> _loadQuizLectures(String courseId) async {
    setState(() {
      _quizCourseId = courseId;
      _quizLectures = [];
      _activeQuiz = null;
      _quizLectureId = null;
    });
    try {
      final data = await ApiService.get('/api/courses/$courseId');
      if (mounted && data['success'] == true) {
        setState(() {
          _quizLectures = List<Map<String, dynamic>>.from(
            data['lectures'] as List<dynamic>? ?? [],
          );
        });
      }
    } catch (_) {}
  }

  Future<void> _loadQuiz(String lectureId) async {
    setState(() {
      _quizLectureId = lectureId;
      _quizLoading = true;
      _activeQuiz = null;
    });
    try {
      final data = await QuizService.getQuiz(lectureId);
      if (mounted) {
        setState(() {
          _activeQuiz = data['success'] == true ? data : null;
          _quizLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _quizLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dvpw = MediaQuery.of(context).size.width;
    final dvph = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.lightBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(dvpw, dvph),
            _buildTabBar(dvpw, dvph),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildDashboardTab(dvpw, dvph),
                  _buildNotesTab(dvpw, dvph),
                  _buildQuizTab(dvpw, dvph),
                  _buildCreditsTab(dvpw, dvph),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(double dvpw, double dvph) {
    return Container(
      padding: EdgeInsets.all(dvpw * 0.04),
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
          Container(
            padding: EdgeInsets.all(dvpw * 0.025),
            decoration: BoxDecoration(
              color: AppColors.primaryLime,
              borderRadius: BorderRadius.circular(dvpw * 0.03),
            ),
            child: Icon(
              Icons.bar_chart_rounded,
              size: dvpw * 0.06,
              color: AppColors.primaryDark,
            ),
          ),
          SizedBox(width: dvpw * 0.03),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Progress',
                  style: GoogleFonts.lato(
                    fontSize: dvpw * 0.055,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDark,
                  ),
                ),
                Text(
                  'Track your learning journey',
                  style: GoogleFonts.lato(
                    fontSize: dvpw * 0.032,
                    color: AppColors.gray,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.all(dvpw * 0.025),
            decoration: BoxDecoration(
              color: AppColors.lightBg,
              borderRadius: BorderRadius.circular(dvpw * 0.03),
            ),
            child: Icon(
              Icons.calendar_month_rounded,
              size: dvpw * 0.055,
              color: AppColors.primaryDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(double dvpw, double dvph) {
    return Container(
      color: AppColors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.primaryDark,
        unselectedLabelColor: AppColors.gray,
        indicatorColor: AppColors.primaryLime,
        indicatorWeight: 3,
        labelStyle: GoogleFonts.lato(
          fontSize: dvpw * 0.035,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: GoogleFonts.lato(
          fontSize: dvpw * 0.035,
          fontWeight: FontWeight.w500,
        ),
        tabs: const [
          Tab(text: 'Dashboard'),
          Tab(text: 'Notes'),
          Tab(text: 'Quizzes'),
          Tab(text: 'Credits'),
        ],
      ),
    );
  }

  // ==================== DASHBOARD TAB ====================
  Widget _buildDashboardTab(double dvpw, double dvph) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(dvpw * 0.04),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overall Stats Cards
          _buildOverallStats(dvpw, dvph),
          SizedBox(height: dvph * 0.025),
          
          // Weekly Progress
          _buildWeeklyProgress(dvpw, dvph),
          SizedBox(height: dvph * 0.025),
          
          // Course Progress
          Text(
            'Course Progress',
            style: GoogleFonts.lato(
              fontSize: dvpw * 0.045,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryDark,
            ),
          ),
          SizedBox(height: dvph * 0.015),
          if (_coursesLoading)
            const Center(child: CircularProgressIndicator(color: AppColors.primaryDark, strokeWidth: 2))
          else if (_enrolledCourses.isEmpty)
            Container(
              padding: EdgeInsets.all(dvpw * 0.04),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(dvpw * 0.04),
              ),
              child: Center(
                child: Text(
                  'No enrolled courses yet',
                  style: GoogleFonts.lato(fontSize: dvpw * 0.038, color: AppColors.gray),
                ),
              ),
            )
          else
            ..._enrolledCourses.map((c) => _buildCourseProgressCard(c, dvpw, dvph)),
          
          SizedBox(height: dvph * 0.025),
          
          // Recent Activity
          _buildRecentActivity(dvpw, dvph),
        ],
      ),
    );
  }

  Widget _buildOverallStats(double dvpw, double dvph) {
    final totalCourses = _enrolledCourses.length;
    final completedCourses = _enrolledCourses.where((c) =>
      (c['progress_percent'] as num?)?.toDouble() == 100.0
    ).length;
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Enrolled',
            '$totalCourses',
            Icons.school_rounded,
            AppColors.blue,
            dvpw,
            dvph,
          ),
        ),
        SizedBox(width: dvpw * 0.03),
        Expanded(
          child: _buildStatCard(
            'Completed',
            '$completedCourses',
            Icons.check_circle_rounded,
            AppColors.green,
            dvpw,
            dvph,
          ),
        ),
        SizedBox(width: dvpw * 0.03),
        Expanded(
          child: _buildStatCard(
            'In Progress',
            '${totalCourses - completedCourses}',
            Icons.play_circle_rounded,
            AppColors.purple,
            dvpw,
            dvph,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, double dvpw, double dvph) {
    return Container(
      padding: EdgeInsets.all(dvpw * 0.04),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(dvpw * 0.04),
        boxShadow: [
          BoxShadow(
            color: AppColors.gray.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(dvpw * 0.025),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(dvpw * 0.025),
            ),
            child: Icon(icon, size: dvpw * 0.06, color: color),
          ),
          SizedBox(height: dvph * 0.01),
          Text(
            value,
            style: GoogleFonts.lato(
              fontSize: dvpw * 0.055,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryDark,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.lato(
              fontSize: dvpw * 0.028,
              color: AppColors.gray,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyProgress(double dvpw, double dvph) {
    // Compute average progress across enrolled courses
    double avgProgress = 0;
    if (_enrolledCourses.isNotEmpty) {
      final total = _enrolledCourses.fold<double>(
        0,
        (sum, c) => sum + ((c['progress_percent'] as num?)?.toDouble() ?? 0.0),
      );
      avgProgress = total / _enrolledCourses.length;
    }

    return Container(
      padding: EdgeInsets.all(dvpw * 0.04),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(dvpw * 0.04),
        boxShadow: [
          BoxShadow(color: AppColors.gray.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Overall Progress',
            style: GoogleFonts.lato(fontSize: dvpw * 0.042, fontWeight: FontWeight.w700, color: AppColors.primaryDark),
          ),
          SizedBox(height: dvph * 0.015),
          if (_enrolledCourses.isEmpty)
            Text(
              'Enroll in a course to track progress',
              style: GoogleFonts.lato(fontSize: dvpw * 0.035, color: AppColors.gray),
            )
          else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Average completion',
                  style: GoogleFonts.lato(fontSize: dvpw * 0.034, color: AppColors.gray),
                ),
                Text(
                  '${avgProgress.toInt()}%',
                  style: GoogleFonts.lato(fontSize: dvpw * 0.04, fontWeight: FontWeight.w700, color: AppColors.primaryDark),
                ),
              ],
            ),
            SizedBox(height: dvph * 0.012),
            ClipRRect(
              borderRadius: BorderRadius.circular(dvpw * 0.015),
              child: LinearProgressIndicator(
                value: (avgProgress / 100.0).clamp(0.0, 1.0),
                backgroundColor: AppColors.grayLight,
                valueColor: AlwaysStoppedAnimation(AppColors.primaryLime),
                minHeight: dvph * 0.015,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCourseProgressCard(Map<String, dynamic> course, double dvpw, double dvph) {
    final title = course['title']?.toString() ?? 'Course';
    final progress = (course['progress_percent'] as num?)?.toDouble() ?? 0.0;
    Color color;
    try {
      final h = (course['thumbnail_color'] as String? ?? '#6C63FF').replaceAll('#', '');
      color = Color(int.parse('FF$h', radix: 16));
    } catch (_) {
      color = AppColors.purple;
    }
    return Container(
      margin: EdgeInsets.only(bottom: dvph * 0.015),
      padding: EdgeInsets.all(dvpw * 0.04),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(dvpw * 0.04),
        boxShadow: [
          BoxShadow(color: AppColors.gray.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: dvpw * 0.12,
            height: dvpw * 0.12,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(dvpw * 0.03),
            ),
            child: Center(
              child: Text(
                title.isNotEmpty ? title[0].toUpperCase() : 'C',
                style: GoogleFonts.lato(fontSize: dvpw * 0.05, fontWeight: FontWeight.w800, color: color),
              ),
            ),
          ),
          SizedBox(width: dvpw * 0.04),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.lato(fontSize: dvpw * 0.04, fontWeight: FontWeight.w700, color: AppColors.primaryDark),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: dvph * 0.005),
                Text(
                  '${progress.toInt()}% complete',
                  style: GoogleFonts.lato(fontSize: dvpw * 0.032, color: AppColors.gray),
                ),
                SizedBox(height: dvph * 0.008),
                ClipRRect(
                  borderRadius: BorderRadius.circular(dvpw * 0.01),
                  child: LinearProgressIndicator(
                    value: (progress / 100.0).clamp(0.0, 1.0),
                    backgroundColor: AppColors.grayLight,
                    valueColor: AlwaysStoppedAnimation(color),
                    minHeight: dvph * 0.008,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: dvpw * 0.03),
          Text(
            '${progress.toInt()}%',
            style: GoogleFonts.lato(fontSize: dvpw * 0.045, fontWeight: FontWeight.w800, color: AppColors.primaryDark),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectProgressCard(Subject subject, double dvpw, double dvph) {
    return Container(
      margin: EdgeInsets.only(bottom: dvph * 0.015),
      padding: EdgeInsets.all(dvpw * 0.04),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(dvpw * 0.04),
        boxShadow: [
          BoxShadow(
            color: AppColors.gray.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: dvpw * 0.12,
            height: dvpw * 0.12,
            decoration: BoxDecoration(
              color: AppColors.primaryLime.withOpacity(0.2),
              borderRadius: BorderRadius.circular(dvpw * 0.03),
            ),
            child: Center(
              child: Text(
                subject.icon,
                style: TextStyle(fontSize: dvpw * 0.06),
              ),
            ),
          ),
          SizedBox(width: dvpw * 0.04),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subject.name,
                  style: GoogleFonts.lato(
                    fontSize: dvpw * 0.04,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark,
                  ),
                ),
                SizedBox(height: dvph * 0.005),
                Text(
                  '${subject.completedChapters}/${subject.totalChapters} chapters',
                  style: GoogleFonts.lato(
                    fontSize: dvpw * 0.032,
                    color: AppColors.gray,
                  ),
                ),
                SizedBox(height: dvph * 0.008),
                ClipRRect(
                  borderRadius: BorderRadius.circular(dvpw * 0.01),
                  child: LinearProgressIndicator(
                    value: subject.progress,
                    backgroundColor: AppColors.grayLight,
                    valueColor: AlwaysStoppedAnimation(AppColors.primaryLime),
                    minHeight: dvph * 0.008,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: dvpw * 0.03),
          Text(
            '${(subject.progress * 100).toInt()}%',
            style: GoogleFonts.lato(
              fontSize: dvpw * 0.045,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity(double dvpw, double dvph) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: GoogleFonts.lato(
            fontSize: dvpw * 0.045,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryDark,
          ),
        ),
        SizedBox(height: dvph * 0.015),
        _buildActivityItem('Completed Physics Quiz', '2 hours ago', Icons.quiz_rounded, AppColors.purple, dvpw, dvph),
        _buildActivityItem('Added notes for Calculus', 'Yesterday', Icons.note_add_rounded, AppColors.blue, dvpw, dvph),
        _buildActivityItem('Finished Chemistry Ch.3', '2 days ago', Icons.check_circle_rounded, AppColors.green, dvpw, dvph),
      ],
    );
  }

  Widget _buildActivityItem(String title, String time, IconData icon, Color color, double dvpw, double dvph) {
    return Container(
      margin: EdgeInsets.only(bottom: dvph * 0.012),
      padding: EdgeInsets.all(dvpw * 0.035),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(dvpw * 0.03),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(dvpw * 0.025),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(dvpw * 0.025),
            ),
            child: Icon(icon, size: dvpw * 0.05, color: color),
          ),
          SizedBox(width: dvpw * 0.03),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.lato(
                    fontSize: dvpw * 0.036,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryDark,
                  ),
                ),
                Text(
                  time,
                  style: GoogleFonts.lato(
                    fontSize: dvpw * 0.03,
                    color: AppColors.gray,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== NOTES TAB ====================
  Widget _buildNotesTab(double dvpw, double dvph) {
    // If notes content is loaded, show it
    if (_notesLectureId != null) {
      return Column(
        children: [
          // Back breadcrumb
          Container(
            padding: EdgeInsets.symmetric(horizontal: dvpw * 0.04, vertical: dvph * 0.015),
            color: AppColors.white,
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => setState(() {
                    _notesLectureId = null;
                    _notesContent = null;
                  }),
                  child: Icon(Icons.arrow_back_rounded, size: dvpw * 0.055, color: AppColors.primaryDark),
                ),
                SizedBox(width: dvpw * 0.03),
                Expanded(
                  child: Text(
                    'AI Notes',
                    style: GoogleFonts.lato(fontSize: dvpw * 0.042, fontWeight: FontWeight.w700, color: AppColors.primaryDark),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _notesLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primaryDark, strokeWidth: 2))
                : SingleChildScrollView(
                    padding: EdgeInsets.all(dvpw * 0.04),
                    child: Container(
                      padding: EdgeInsets.all(dvpw * 0.04),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(dvpw * 0.04),
                        boxShadow: [
                          BoxShadow(color: AppColors.gray.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: MarkdownBody(
                        data: _notesContent ?? 'No notes available.',
                        styleSheet: MarkdownStyleSheet(
                          p: GoogleFonts.lato(fontSize: dvpw * 0.036, color: AppColors.primaryDark, height: 1.6),
                          h1: GoogleFonts.lato(fontSize: dvpw * 0.05, color: AppColors.primaryDark, fontWeight: FontWeight.w800),
                          h2: GoogleFonts.lato(fontSize: dvpw * 0.045, color: AppColors.primaryDark, fontWeight: FontWeight.w700),
                          h3: GoogleFonts.lato(fontSize: dvpw * 0.04, color: AppColors.purple, fontWeight: FontWeight.w600),
                          strong: GoogleFonts.lato(fontSize: dvpw * 0.036, color: AppColors.primaryDark, fontWeight: FontWeight.w700),
                          listBullet: GoogleFonts.lato(fontSize: dvpw * 0.036, color: AppColors.purple),
                          code: GoogleFonts.sourceCodePro(fontSize: dvpw * 0.03, backgroundColor: AppColors.lightBg),
                        ),
                        selectable: true,
                      ),
                    ),
                  ),
          ),
        ],
      );
    }

    // If a course is selected, show lectures list
    if (_notesCourseId != null) {
      return Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: dvpw * 0.04, vertical: dvph * 0.015),
            color: AppColors.white,
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => setState(() {
                    _notesCourseId = null;
                    _notesLectures = [];
                  }),
                  child: Icon(Icons.arrow_back_rounded, size: dvpw * 0.055, color: AppColors.primaryDark),
                ),
                SizedBox(width: dvpw * 0.03),
                Text('Lectures', style: GoogleFonts.lato(fontSize: dvpw * 0.042, fontWeight: FontWeight.w700, color: AppColors.primaryDark)),
              ],
            ),
          ),
          Expanded(
            child: _notesLectures.isEmpty
                ? const Center(child: CircularProgressIndicator(color: AppColors.primaryDark, strokeWidth: 2))
                : ListView.builder(
                    padding: EdgeInsets.all(dvpw * 0.04),
                    itemCount: _notesLectures.length,
                    itemBuilder: (context, i) {
                      final lec = _notesLectures[i];
                      final lecId = lec['id']?.toString() ?? lec['_id']?.toString() ?? '';
                      final lecTitle = lec['title']?.toString() ?? 'Lecture ${i + 1}';
                      return _buildFolderCard(
                        '📄',
                        lecTitle,
                        'Tap to view AI notes',
                        () => _loadNotes(lecId),
                        dvpw, dvph,
                      );
                    },
                  ),
          ),
        ],
      );
    }

    // Top level: show enrolled courses
    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: dvpw * 0.04, vertical: dvph * 0.015),
          color: AppColors.white,
          child: Row(
            children: [
              Text('📚 Notes', style: GoogleFonts.lato(fontSize: dvpw * 0.038, fontWeight: FontWeight.w700, color: AppColors.primaryDark)),
            ],
          ),
        ),
        Expanded(
          child: _coursesLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primaryDark, strokeWidth: 2))
              : _enrolledCourses.isEmpty
                  ? _buildEmptyState('No enrolled courses', 'Enroll in a course to view AI notes', dvpw, dvph)
                  : ListView.builder(
                      padding: EdgeInsets.all(dvpw * 0.04),
                      itemCount: _enrolledCourses.length,
                      itemBuilder: (context, i) {
                        final course = _enrolledCourses[i];
                        final cId = course['id']?.toString() ?? course['_id']?.toString() ?? '';
                        final cTitle = course['title']?.toString() ?? 'Course';
                        return _buildFolderCard(
                          '📚',
                          cTitle,
                          'View lectures',
                          () => _loadNotesLectures(cId),
                          dvpw, dvph,
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildFolderCard(String icon, String title, String subtitle, VoidCallback onTap, double dvpw, double dvph, {double? progress}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: dvph * 0.015),
        padding: EdgeInsets.all(dvpw * 0.04),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(dvpw * 0.04),
          boxShadow: [
            BoxShadow(
              color: AppColors.gray.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: dvpw * 0.12,
              height: dvpw * 0.12,
              decoration: BoxDecoration(
                color: AppColors.primaryLime.withOpacity(0.2),
                borderRadius: BorderRadius.circular(dvpw * 0.03),
              ),
              child: Center(
                child: Text(icon, style: TextStyle(fontSize: dvpw * 0.055)),
              ),
            ),
            SizedBox(width: dvpw * 0.04),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.lato(
                      fontSize: dvpw * 0.04,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  SizedBox(height: dvph * 0.003),
                  Text(
                    subtitle,
                    style: GoogleFonts.lato(
                      fontSize: dvpw * 0.032,
                      color: AppColors.gray,
                    ),
                  ),
                  if (progress != null) ...[
                    SizedBox(height: dvph * 0.008),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(dvpw * 0.01),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: AppColors.grayLight,
                        valueColor: AlwaysStoppedAnimation(AppColors.primaryLime),
                        minHeight: dvph * 0.006,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: dvpw * 0.06, color: AppColors.gray),
          ],
        ),
      ),
    );
  }

  Widget _buildTopicCard(Topic topic, double dvpw, double dvph) {
    return Container(
      margin: EdgeInsets.only(bottom: dvph * 0.015),
      padding: EdgeInsets.all(dvpw * 0.04),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(dvpw * 0.04),
        border: topic.isCompleted ? Border.all(color: AppColors.blue, width: 2) : null,
        boxShadow: [
          BoxShadow(
            color: topic.isCompleted 
                ? AppColors.blue.withOpacity(0.3) 
                : AppColors.gray.withOpacity(0.1),
            blurRadius: topic.isCompleted ? 12 : 8,
            spreadRadius: topic.isCompleted ? 1 : 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(dvpw * 0.025),
                decoration: BoxDecoration(
                  color: topic.isCompleted ? AppColors.blue.withOpacity(0.15) : AppColors.grayLight,
                  borderRadius: BorderRadius.circular(dvpw * 0.025),
                ),
                child: Icon(
                  topic.isCompleted ? Icons.check_circle : Icons.circle_outlined,
                  size: dvpw * 0.05,
                  color: topic.isCompleted ? AppColors.blue : AppColors.gray,
                ),
              ),
              SizedBox(width: dvpw * 0.03),
              Expanded(
                child: Text(
                  topic.name,
                  style: GoogleFonts.lato(
                    fontSize: dvpw * 0.04,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
            ],
          ),
          if (topic.notes.isNotEmpty || topic.quizzes.isNotEmpty) ...[
            SizedBox(height: dvph * 0.015),
            Row(
              children: [
                if (topic.notes.isNotEmpty)
                  _buildInfoChip('${topic.notes.length} notes', Icons.description_outlined, AppColors.blue, dvpw),
                if (topic.notes.isNotEmpty && topic.quizzes.isNotEmpty)
                  SizedBox(width: dvpw * 0.02),
                if (topic.quizzes.isNotEmpty)
                  _buildInfoChip('${topic.quizzes.length} quiz', Icons.quiz_outlined, AppColors.purple, dvpw),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, IconData icon, Color color, double dvpw) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: dvpw * 0.025, vertical: dvpw * 0.015),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(dvpw * 0.02),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: dvpw * 0.04, color: color),
          SizedBox(width: dvpw * 0.015),
          Text(
            label,
            style: GoogleFonts.lato(
              fontSize: dvpw * 0.03,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle, double dvpw, double dvph) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open_rounded, size: dvpw * 0.2, color: AppColors.grayLight),
          SizedBox(height: dvph * 0.02),
          Text(
            title,
            style: GoogleFonts.lato(
              fontSize: dvpw * 0.045,
              fontWeight: FontWeight.w700,
              color: AppColors.gray,
            ),
          ),
          Text(
            subtitle,
            style: GoogleFonts.lato(
              fontSize: dvpw * 0.035,
              color: AppColors.gray,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== ROADMAP TAB ====================
  Widget _buildRoadmapTab(double dvpw, double dvph) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(dvpw * 0.04),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Subject',
            style: GoogleFonts.lato(
              fontSize: dvpw * 0.04,
              fontWeight: FontWeight.w600,
              color: AppColors.gray,
            ),
          ),
          SizedBox(height: dvph * 0.015),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: sampleSubjects.map((subject) {
                final isSelected = _selectedSubject?.id == subject.id;
                return GestureDetector(
                  onTap: () => setState(() => _selectedSubject = subject),
                  child: Container(
                    margin: EdgeInsets.only(right: dvpw * 0.03),
                    padding: EdgeInsets.symmetric(horizontal: dvpw * 0.04, vertical: dvpw * 0.03),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primaryDark : AppColors.white,
                      borderRadius: BorderRadius.circular(dvpw * 0.03),
                      border: Border.all(
                        color: isSelected ? AppColors.primaryDark : AppColors.grayLight,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(subject.icon, style: TextStyle(fontSize: dvpw * 0.045)),
                        SizedBox(width: dvpw * 0.02),
                        Text(
                          subject.name,
                          style: GoogleFonts.lato(
                            fontSize: dvpw * 0.035,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? AppColors.white : AppColors.primaryDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          SizedBox(height: dvph * 0.03),
          if (_selectedSubject != null && subjectRoadmaps.containsKey(_selectedSubject!.id))
            _buildRoadmapSteps(subjectRoadmaps[_selectedSubject!.id]!, dvpw, dvph)
          else
            _buildEmptyState('Select a subject', 'View the learning roadmap', dvpw, dvph),
        ],
      ),
    );
  }

  Widget _buildRoadmapSteps(List<RoadmapStep> steps, double dvpw, double dvph) {
    return Column(
      children: steps.asMap().entries.map((entry) {
        final index = entry.key;
        final step = entry.value;
        final isLast = index == steps.length - 1;
        
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline
            Column(
              children: [
                Container(
                  width: dvpw * 0.1,
                  height: dvpw * 0.1,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: step.isCompleted
                        ? AppColors.green
                        : step.isCurrent
                            ? AppColors.primaryLime
                            : AppColors.grayLight,
                    border: step.isCurrent
                        ? Border.all(color: AppColors.primaryDark, width: 3)
                        : null,
                  ),
                  child: Center(
                    child: step.isCompleted
                        ? Icon(Icons.check, color: AppColors.white, size: dvpw * 0.05)
                        : Text(
                            '${step.order}',
                            style: GoogleFonts.lato(
                              fontSize: dvpw * 0.04,
                              fontWeight: FontWeight.w700,
                              color: step.isCurrent ? AppColors.primaryDark : AppColors.gray,
                            ),
                          ),
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 3,
                    height: dvph * 0.08,
                    color: step.isCompleted ? AppColors.green : AppColors.grayLight,
                  ),
              ],
            ),
            SizedBox(width: dvpw * 0.04),
            // Content
            Expanded(
              child: Container(
                margin: EdgeInsets.only(bottom: dvph * 0.02),
                padding: EdgeInsets.all(dvpw * 0.04),
                decoration: BoxDecoration(
                  color: step.isCurrent ? AppColors.primaryLime.withOpacity(0.15) : AppColors.white,
                  borderRadius: BorderRadius.circular(dvpw * 0.04),
                  border: step.isCurrent ? Border.all(color: AppColors.primaryLime, width: 2) : null,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.gray.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            step.title,
                            style: GoogleFonts.lato(
                              fontSize: dvpw * 0.04,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ),
                        if (step.isCurrent)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: dvpw * 0.02, vertical: dvpw * 0.01),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLime,
                              borderRadius: BorderRadius.circular(dvpw * 0.015),
                            ),
                            child: Text(
                              'Current',
                              style: GoogleFonts.lato(
                                fontSize: dvpw * 0.025,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: dvph * 0.005),
                    Text(
                      step.description,
                      style: GoogleFonts.lato(
                        fontSize: dvpw * 0.033,
                        color: AppColors.gray,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  // ==================== QUIZ TAB ====================
  Widget _buildQuizTab(double dvpw, double dvph) {
    // Show active quiz questions
    if (_activeQuiz != null) {
      return _buildQuizView(dvpw, dvph);
    }

    // Show lectures for a selected course
    if (_quizCourseId != null) {
      return Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: dvpw * 0.04, vertical: dvph * 0.015),
            color: AppColors.white,
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => setState(() { _quizCourseId = null; _quizLectures = []; }),
                  child: Icon(Icons.arrow_back_rounded, size: dvpw * 0.055, color: AppColors.primaryDark),
                ),
                SizedBox(width: dvpw * 0.03),
                Text('Select Lecture', style: GoogleFonts.lato(fontSize: dvpw * 0.042, fontWeight: FontWeight.w700, color: AppColors.primaryDark)),
              ],
            ),
          ),
          Expanded(
            child: _quizLectures.isEmpty
                ? const Center(child: CircularProgressIndicator(color: AppColors.primaryDark, strokeWidth: 2))
                : ListView.builder(
                    padding: EdgeInsets.all(dvpw * 0.04),
                    itemCount: _quizLectures.length,
                    itemBuilder: (ctx, i) {
                      final lec = _quizLectures[i];
                      final lecId = lec['id']?.toString() ?? '';
                      final lecTitle = lec['title']?.toString() ?? 'Lecture ${i + 1}';
                      return Container(
                        margin: EdgeInsets.only(bottom: dvph * 0.015),
                        padding: EdgeInsets.all(dvpw * 0.04),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(dvpw * 0.04),
                          boxShadow: [BoxShadow(color: AppColors.gray.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2))],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(dvpw * 0.03),
                              decoration: BoxDecoration(color: AppColors.purple.withOpacity(0.15), borderRadius: BorderRadius.circular(dvpw * 0.025)),
                              child: Icon(Icons.quiz_rounded, size: dvpw * 0.06, color: AppColors.purple),
                            ),
                            SizedBox(width: dvpw * 0.03),
                            Expanded(
                              child: Text(lecTitle, style: GoogleFonts.lato(fontSize: dvpw * 0.038, fontWeight: FontWeight.w600, color: AppColors.primaryDark)),
                            ),
                            ElevatedButton(
                              onPressed: _quizLoading ? null : () => _loadQuiz(lecId),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryLime,
                                foregroundColor: AppColors.primaryDark,
                                elevation: 0,
                                padding: EdgeInsets.symmetric(horizontal: dvpw * 0.04, vertical: dvpw * 0.02),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(dvpw * 0.025)),
                              ),
                              child: _quizLoading && _quizLectureId == lecId
                                  ? SizedBox(width: dvpw * 0.04, height: dvpw * 0.04, child: const CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryDark))
                                  : Text('Start', style: GoogleFonts.lato(fontSize: dvpw * 0.035, fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      );
    }

    // Top level: stats + enrolled courses list
    return SingleChildScrollView(
      padding: EdgeInsets.all(dvpw * 0.04),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildQuizStats(dvpw, dvph),
          SizedBox(height: dvph * 0.025),
          Text(
            'Quizzes by Course',
            style: GoogleFonts.lato(fontSize: dvpw * 0.045, fontWeight: FontWeight.w700, color: AppColors.primaryDark),
          ),
          SizedBox(height: dvph * 0.015),
          if (_coursesLoading)
            const Center(child: CircularProgressIndicator(color: AppColors.primaryDark, strokeWidth: 2))
          else if (_enrolledCourses.isEmpty)
            _buildEmptyState('No enrolled courses', 'Enroll in a course to take quizzes', dvpw, dvph)
          else
            ..._enrolledCourses.map((course) {
              final cId = course['id']?.toString() ?? '';
              final cTitle = course['title']?.toString() ?? 'Course';
              return Container(
                margin: EdgeInsets.only(bottom: dvph * 0.015),
                padding: EdgeInsets.all(dvpw * 0.04),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(dvpw * 0.04),
                  boxShadow: [BoxShadow(color: AppColors.gray.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: Row(
                  children: [
                    Container(
                      width: dvpw * 0.12,
                      height: dvpw * 0.12,
                      decoration: BoxDecoration(
                        color: AppColors.purple.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(dvpw * 0.03),
                      ),
                      child: Center(
                        child: Text(
                          cTitle.isNotEmpty ? cTitle[0].toUpperCase() : 'C',
                          style: GoogleFonts.lato(fontSize: dvpw * 0.05, fontWeight: FontWeight.w800, color: AppColors.purple),
                        ),
                      ),
                    ),
                    SizedBox(width: dvpw * 0.04),
                    Expanded(
                      child: Text(cTitle, style: GoogleFonts.lato(fontSize: dvpw * 0.04, fontWeight: FontWeight.w700, color: AppColors.primaryDark)),
                    ),
                    ElevatedButton(
                      onPressed: () => _loadQuizLectures(cId),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryLime,
                        foregroundColor: AppColors.primaryDark,
                        elevation: 0,
                        padding: EdgeInsets.symmetric(horizontal: dvpw * 0.04, vertical: dvph * 0.01),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(dvpw * 0.025)),
                      ),
                      child: Text('Select', style: GoogleFonts.lato(fontSize: dvpw * 0.035, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildQuizView(double dvpw, double dvph) {
    // Backend returns { success, quiz: { questions: [...] } }
    final quiz = _activeQuiz?['quiz'] as Map<String, dynamic>?;
    final questions = (quiz?['questions'] as List<dynamic>?) ?? [];
    if (questions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.quiz_rounded, size: dvpw * 0.2, color: AppColors.grayLight),
            SizedBox(height: dvph * 0.02),
            Text('No questions available', style: GoogleFonts.lato(fontSize: dvpw * 0.042, color: AppColors.gray)),
            SizedBox(height: dvph * 0.02),
            ElevatedButton(
              onPressed: () => setState(() { _activeQuiz = null; _quizLectureId = null; }),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryDark, foregroundColor: AppColors.white),
              child: Text('Go Back', style: GoogleFonts.lato(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
    }
    return _QuizRunner(
      quiz: _activeQuiz!,
      lectureId: _quizLectureId!,
      onDone: () => setState(() { _activeQuiz = null; _quizLectureId = null; }),
      dvpw: dvpw,
      dvph: dvph,
    );
  }

  Widget _buildQuizStats(double dvpw, double dvph) {
    return Container(
      padding: EdgeInsets.all(dvpw * 0.04),
      decoration: BoxDecoration(
        gradient: AppColors.darkGradient,
        borderRadius: BorderRadius.circular(dvpw * 0.04),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildQuizStatItem('Total Quizzes', '24', dvpw),
              Container(width: 1, height: dvph * 0.05, color: AppColors.white.withOpacity(0.3)),
              _buildQuizStatItem('Completed', '18', dvpw),
              Container(width: 1, height: dvph * 0.05, color: AppColors.white.withOpacity(0.3)),
              _buildQuizStatItem('Avg Score', '85%', dvpw),
            ],
          ),
          SizedBox(height: dvph * 0.02),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryLime,
              foregroundColor: AppColors.primaryDark,
              padding: EdgeInsets.symmetric(horizontal: dvpw * 0.08, vertical: dvph * 0.015),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(dvpw * 0.03),
              ),
            ),
            child: Text(
              'Start Random Quiz',
              style: GoogleFonts.lato(
                fontSize: dvpw * 0.04,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizStatItem(String label, String value, double dvpw) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.lato(
            fontSize: dvpw * 0.06,
            fontWeight: FontWeight.w800,
            color: AppColors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.lato(
            fontSize: dvpw * 0.03,
            color: AppColors.grayLight,
          ),
        ),
      ],
    );
  }

  Widget _buildSubjectQuizCard(Subject subject, double dvpw, double dvph) {
    return Container(
      margin: EdgeInsets.only(bottom: dvph * 0.015),
      padding: EdgeInsets.all(dvpw * 0.04),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(dvpw * 0.04),
        boxShadow: [
          BoxShadow(
            color: AppColors.gray.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: dvpw * 0.12,
            height: dvpw * 0.12,
            decoration: BoxDecoration(
              color: AppColors.purple.withOpacity(0.15),
              borderRadius: BorderRadius.circular(dvpw * 0.03),
            ),
            child: Center(
              child: Text(subject.icon, style: TextStyle(fontSize: dvpw * 0.055)),
            ),
          ),
          SizedBox(width: dvpw * 0.04),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subject.name,
                  style: GoogleFonts.lato(
                    fontSize: dvpw * 0.04,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark,
                  ),
                ),
                SizedBox(height: dvph * 0.003),
                Text(
                  '${subject.totalChapters} quizzes available',
                  style: GoogleFonts.lato(
                    fontSize: dvpw * 0.032,
                    color: AppColors.gray,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryLime,
              foregroundColor: AppColors.primaryDark,
              elevation: 0,
              padding: EdgeInsets.symmetric(horizontal: dvpw * 0.04, vertical: dvph * 0.01),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(dvpw * 0.025),
              ),
            ),
            child: Text(
              'Start',
              style: GoogleFonts.lato(
                fontSize: dvpw * 0.035,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== CREDITS TAB ====================
  Widget _buildCreditsTab(double dvpw, double dvph) {
    if (_creditsLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primaryDark, strokeWidth: 2));
    }
    final totalCredits = (_creditsData?['total'] as num?)?.toInt() ??
        (_creditsData?['credits_total'] as num?)?.toInt() ??
        sampleUserStats.totalXP;
    final history = (_creditsData?['history'] as List<dynamic>?) ?? [];

    return SingleChildScrollView(
      padding: EdgeInsets.all(dvpw * 0.04),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // XP Overview Card
          _buildXpOverview(dvpw, dvph, totalCredits),
          SizedBox(height: dvph * 0.025),

          // Credits history if available
          if (history.isNotEmpty) ...[
            Text(
              'Credits History',
              style: GoogleFonts.lato(fontSize: dvpw * 0.045, fontWeight: FontWeight.w700, color: AppColors.primaryDark),
            ),
            SizedBox(height: dvph * 0.015),
            ...history.map((item) {
              final m = item as Map<String, dynamic>;
              final amount = m['amount']?.toString() ?? '0';
              final reason = m['reason']?.toString() ?? m['description']?.toString() ?? 'Credit earned';
              final date = m['date']?.toString() ?? m['created_at']?.toString() ?? '';
              return Container(
                margin: EdgeInsets.only(bottom: dvph * 0.012),
                padding: EdgeInsets.all(dvpw * 0.04),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(dvpw * 0.035),
                  boxShadow: [BoxShadow(color: AppColors.gray.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(dvpw * 0.025),
                      decoration: BoxDecoration(color: AppColors.primaryLime.withOpacity(0.2), borderRadius: BorderRadius.circular(dvpw * 0.025)),
                      child: Icon(Icons.star_rounded, size: dvpw * 0.055, color: AppColors.primaryDark),
                    ),
                    SizedBox(width: dvpw * 0.03),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(reason, style: GoogleFonts.lato(fontSize: dvpw * 0.036, fontWeight: FontWeight.w600, color: AppColors.primaryDark)),
                          if (date.isNotEmpty)
                            Text(date, style: GoogleFonts.lato(fontSize: dvpw * 0.03, color: AppColors.gray)),
                        ],
                      ),
                    ),
                    Text(
                      '+$amount XP',
                      style: GoogleFonts.lato(fontSize: dvpw * 0.04, fontWeight: FontWeight.w800, color: AppColors.green),
                    ),
                  ],
                ),
              );
            }),
            SizedBox(height: dvph * 0.025),
          ],

          // Achievements Section
          _buildAchievementsSection(dvpw, dvph),
          SizedBox(height: dvph * 0.025),

          // Certifications Section
          _buildCertificationsSection(dvpw, dvph),
          SizedBox(height: dvph * 0.05),
        ],
      ),
    );
  }

  Widget _buildXpOverview(double dvpw, double dvph, [int? totalCredits]) {
    final xp = totalCredits ?? sampleUserStats.totalXP;
    final level = sampleUserStats.level;
    return Container(
      padding: EdgeInsets.all(dvpw * 0.05),
      decoration: BoxDecoration(
        gradient: AppColors.darkGradient,
        borderRadius: BorderRadius.circular(dvpw * 0.05),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: dvpw * 0.18,
                height: dvpw * 0.18,
                decoration: BoxDecoration(
                  color: AppColors.primaryLime,
                  borderRadius: BorderRadius.circular(dvpw * 0.045),
                ),
                child: Center(
                  child: Text(
                    '⭐',
                    style: TextStyle(fontSize: dvpw * 0.09),
                  ),
                ),
              ),
              SizedBox(width: dvpw * 0.04),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Level $level',
                      style: GoogleFonts.lato(
                        fontSize: dvpw * 0.055,
                        fontWeight: FontWeight.w800,
                        color: AppColors.white,
                      ),
                    ),
                    Text(
                      '$xp XP earned',
                      style: GoogleFonts.lato(
                        fontSize: dvpw * 0.035,
                        color: AppColors.grayLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: dvph * 0.02),
          ClipRRect(
            borderRadius: BorderRadius.circular(dvpw * 0.015),
            child: LinearProgressIndicator(
              value: 0.65,
              backgroundColor: AppColors.darkerGray,
              valueColor: AlwaysStoppedAnimation(AppColors.primaryLime),
              minHeight: dvph * 0.012,
            ),
          ),
          SizedBox(height: dvph * 0.008),
          Text(
            'Level ${level + 1} coming up!',
            style: GoogleFonts.lato(
              fontSize: dvpw * 0.03,
              color: AppColors.grayLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsSection(double dvpw, double dvph) {
    final unlockedAchievements = sampleAchievements.where((a) => a.isUnlocked).toList();
    final lockedAchievements = sampleAchievements.where((a) => !a.isUnlocked).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Achievements',
              style: GoogleFonts.lato(
                fontSize: dvpw * 0.045,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryDark,
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: dvpw * 0.025,
                vertical: dvpw * 0.012,
              ),
              decoration: BoxDecoration(
                color: AppColors.primaryLime.withOpacity(0.2),
                borderRadius: BorderRadius.circular(dvpw * 0.02),
              ),
              child: Text(
                '${unlockedAchievements.length}/${sampleAchievements.length}',
                style: GoogleFonts.lato(
                  fontSize: dvpw * 0.032,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDark,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: dvph * 0.015),
        
        // Unlocked achievements
        Container(
          padding: EdgeInsets.all(dvpw * 0.04),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(dvpw * 0.04),
            boxShadow: [
              BoxShadow(
                color: AppColors.gray.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Unlocked',
                style: GoogleFonts.lato(
                  fontSize: dvpw * 0.035,
                  fontWeight: FontWeight.w600,
                  color: AppColors.purple,
                ),
              ),
              SizedBox(height: dvph * 0.012),
              Wrap(
                spacing: dvpw * 0.03,
                runSpacing: dvph * 0.015,
                children: unlockedAchievements.map((achievement) {
                  return _buildAchievementBadge(achievement, dvpw, dvph, true);
                }).toList(),
              ),
            ],
          ),
        ),
        SizedBox(height: dvph * 0.015),
        
        // Locked achievements
        Container(
          padding: EdgeInsets.all(dvpw * 0.04),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(dvpw * 0.04),
            boxShadow: [
              BoxShadow(
                color: AppColors.gray.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'In Progress',
                style: GoogleFonts.lato(
                  fontSize: dvpw * 0.035,
                  fontWeight: FontWeight.w600,
                  color: AppColors.gray,
                ),
              ),
              SizedBox(height: dvph * 0.012),
              ...lockedAchievements.map((achievement) {
                return _buildLockedAchievement(achievement, dvpw, dvph);
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementBadge(Achievement achievement, double dvpw, double dvph, bool isUnlocked) {
    return SizedBox(
      width: dvpw * 0.18,
      child: Column(
        children: [
          Container(
            width: dvpw * 0.15,
            height: dvpw * 0.15,
            decoration: BoxDecoration(
              color: isUnlocked ? AppColors.primaryLime.withOpacity(0.2) : AppColors.grayLight,
              shape: BoxShape.circle,
              border: isUnlocked ? Border.all(color: AppColors.primaryLime, width: 2) : null,
            ),
            child: Center(
              child: Text(
                achievement.icon,
                style: TextStyle(fontSize: dvpw * 0.07),
              ),
            ),
          ),
          SizedBox(height: dvph * 0.005),
          Text(
            achievement.title,
            style: GoogleFonts.lato(
              fontSize: dvpw * 0.026,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryDark,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildLockedAchievement(Achievement achievement, double dvpw, double dvph) {
    return Container(
      margin: EdgeInsets.only(bottom: dvph * 0.012),
      padding: EdgeInsets.all(dvpw * 0.03),
      decoration: BoxDecoration(
        color: AppColors.lightBg,
        borderRadius: BorderRadius.circular(dvpw * 0.03),
      ),
      child: Row(
        children: [
          Container(
            width: dvpw * 0.12,
            height: dvpw * 0.12,
            decoration: BoxDecoration(
              color: AppColors.grayLight,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                achievement.icon,
                style: TextStyle(fontSize: dvpw * 0.05),
              ),
            ),
          ),
          SizedBox(width: dvpw * 0.03),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement.title,
                  style: GoogleFonts.lato(
                    fontSize: dvpw * 0.035,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryDark,
                  ),
                ),
                Text(
                  achievement.description,
                  style: GoogleFonts.lato(
                    fontSize: dvpw * 0.028,
                    color: AppColors.gray,
                  ),
                ),
                SizedBox(height: dvph * 0.006),
                ClipRRect(
                  borderRadius: BorderRadius.circular(dvpw * 0.01),
                  child: LinearProgressIndicator(
                    value: achievement.progress,
                    backgroundColor: AppColors.grayLight,
                    valueColor: AlwaysStoppedAnimation(AppColors.primaryLime),
                    minHeight: dvph * 0.006,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: dvpw * 0.02),
          Text(
            '${(achievement.progress * 100).toInt()}%',
            style: GoogleFonts.lato(
              fontSize: dvpw * 0.032,
              fontWeight: FontWeight.w700,
              color: AppColors.gray,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCertificationsSection(double dvpw, double dvph) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Certifications',
              style: GoogleFonts.lato(
                fontSize: dvpw * 0.045,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryDark,
              ),
            ),
            Text(
              '${sampleCertifications.length} earned',
              style: GoogleFonts.lato(
                fontSize: dvpw * 0.032,
                color: AppColors.gray,
              ),
            ),
          ],
        ),
        SizedBox(height: dvph * 0.015),
        ...sampleCertifications.map((cert) => _buildCertificationCard(cert, dvpw, dvph)),
      ],
    );
  }

  Widget _buildCertificationCard(Certification cert, double dvpw, double dvph) {
    return Container(
      margin: EdgeInsets.only(bottom: dvph * 0.015),
      padding: EdgeInsets.all(dvpw * 0.04),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryDark, const Color(0xFF2D3A42)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(dvpw * 0.04),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: dvpw * 0.15,
            height: dvpw * 0.15,
            decoration: BoxDecoration(
              color: AppColors.primaryLime,
              borderRadius: BorderRadius.circular(dvpw * 0.03),
            ),
            child: Center(
              child: Icon(
                Icons.workspace_premium_rounded,
                size: dvpw * 0.08,
                color: AppColors.primaryDark,
              ),
            ),
          ),
          SizedBox(width: dvpw * 0.04),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cert.title,
                  style: GoogleFonts.lato(
                    fontSize: dvpw * 0.04,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                ),
                SizedBox(height: dvph * 0.003),
                Text(
                  cert.issuer,
                  style: GoogleFonts.lato(
                    fontSize: dvpw * 0.03,
                    color: AppColors.grayLight,
                  ),
                ),
                SizedBox(height: dvph * 0.006),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: dvpw * 0.02,
                        vertical: dvpw * 0.008,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.darkerGray,
                        borderRadius: BorderRadius.circular(dvpw * 0.015),
                      ),
                      child: Text(
                        cert.subject,
                        style: GoogleFonts.lato(
                          fontSize: dvpw * 0.025,
                          color: AppColors.primaryLime,
                        ),
                      ),
                    ),
                    SizedBox(width: dvpw * 0.02),
                    Text(
                      cert.credentialId,
                      style: GoogleFonts.lato(
                        fontSize: dvpw * 0.025,
                        color: AppColors.gray,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(
            Icons.verified_rounded,
            size: dvpw * 0.07,
            color: AppColors.primaryLime,
          ),
        ],
      ),
    );
  }
}

// ==================== QUIZ RUNNER WIDGET ====================
class _QuizRunner extends StatefulWidget {
  final Map<String, dynamic> quiz;
  final String lectureId;
  final VoidCallback onDone;
  final double dvpw;
  final double dvph;

  const _QuizRunner({
    required this.quiz,
    required this.lectureId,
    required this.onDone,
    required this.dvpw,
    required this.dvph,
  });

  @override
  State<_QuizRunner> createState() => _QuizRunnerState();
}

class _QuizRunnerState extends State<_QuizRunner> {
  int _currentQuestion = 0;
  int? _selectedOption;
  final List<int> _answers = [];
  bool _submitted = false;
  Map<String, dynamic>? _result;
  bool _submitting = false;

  // Backend returns { success, quiz: { questions: [...] } }
  List<dynamic> get _questions =>
      ((widget.quiz['quiz'] as Map<String, dynamic>?)?['questions'] as List<dynamic>?) ?? [];

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      final res = await QuizService.submitAttempt(widget.lectureId, _answers);
      if (mounted) {
        setState(() {
          _result = res;
          _submitted = true;
          _submitting = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dvpw = widget.dvpw;
    final dvph = widget.dvph;

    if (_submitted && _result != null) {
      final score = _result!['score'] ?? 0;
      final total = _result!['total'] ?? _questions.length;
      final passed = _result!['passed'] == true;
      final credits = _result!['credits_earned'] ?? 0;
      return Center(
        child: Padding(
          padding: EdgeInsets.all(dvpw * 0.06),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                passed ? '🎉' : '📚',
                style: TextStyle(fontSize: dvpw * 0.15),
              ),
              SizedBox(height: dvph * 0.02),
              Text(
                passed ? 'Passed!' : 'Keep Practicing!',
                style: GoogleFonts.lato(fontSize: dvpw * 0.065, fontWeight: FontWeight.w800, color: AppColors.primaryDark),
              ),
              SizedBox(height: dvph * 0.01),
              Text(
                'Score: $score / $total',
                style: GoogleFonts.lato(fontSize: dvpw * 0.05, color: AppColors.gray),
              ),
              if (credits > 0) ...[
                SizedBox(height: dvph * 0.01),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: dvpw * 0.04, vertical: dvpw * 0.02),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLime.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(dvpw * 0.03),
                  ),
                  child: Text(
                    '+$credits XP Earned!',
                    style: GoogleFonts.lato(fontSize: dvpw * 0.045, fontWeight: FontWeight.w700, color: AppColors.primaryDark),
                  ),
                ),
              ],
              SizedBox(height: dvph * 0.04),
              ElevatedButton(
                onPressed: widget.onDone,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDark,
                  foregroundColor: AppColors.white,
                  padding: EdgeInsets.symmetric(horizontal: dvpw * 0.08, vertical: dvph * 0.018),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(dvpw * 0.035)),
                ),
                child: Text('Done', style: GoogleFonts.lato(fontSize: dvpw * 0.042, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      );
    }

    if (_questions.isEmpty) {
      return Center(
        child: Text('No questions available', style: GoogleFonts.lato(fontSize: dvpw * 0.042, color: AppColors.gray)),
      );
    }

    final q = _questions[_currentQuestion] as Map<String, dynamic>;
    final questionText = q['question']?.toString() ?? q['text']?.toString() ?? 'Question ${_currentQuestion + 1}';
    final options = (q['options'] as List<dynamic>?) ?? [];

    return Column(
      children: [
        // Header
        Container(
          padding: EdgeInsets.symmetric(horizontal: dvpw * 0.04, vertical: dvph * 0.015),
          color: AppColors.white,
          child: Row(
            children: [
              GestureDetector(
                onTap: widget.onDone,
                child: Icon(Icons.close_rounded, size: dvpw * 0.06, color: AppColors.primaryDark),
              ),
              SizedBox(width: dvpw * 0.03),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(dvpw * 0.01),
                  child: LinearProgressIndicator(
                    value: (_currentQuestion + 1) / _questions.length,
                    backgroundColor: AppColors.grayLight,
                    valueColor: AlwaysStoppedAnimation(AppColors.primaryLime),
                    minHeight: dvph * 0.01,
                  ),
                ),
              ),
              SizedBox(width: dvpw * 0.03),
              Text(
                '${_currentQuestion + 1}/${_questions.length}',
                style: GoogleFonts.lato(fontSize: dvpw * 0.035, fontWeight: FontWeight.w600, color: AppColors.gray),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(dvpw * 0.05),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  questionText,
                  style: GoogleFonts.lato(fontSize: dvpw * 0.045, fontWeight: FontWeight.w700, color: AppColors.primaryDark),
                ),
                SizedBox(height: dvph * 0.03),
                ...options.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final opt = entry.value.toString();
                  final isSelected = _selectedOption == idx;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedOption = idx),
                    child: Container(
                      margin: EdgeInsets.only(bottom: dvph * 0.015),
                      padding: EdgeInsets.all(dvpw * 0.04),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primaryLime.withOpacity(0.15) : AppColors.white,
                        borderRadius: BorderRadius.circular(dvpw * 0.035),
                        border: Border.all(
                          color: isSelected ? AppColors.primaryLime : AppColors.grayLight,
                          width: isSelected ? 2 : 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: dvpw * 0.07,
                            height: dvpw * 0.07,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected ? AppColors.primaryLime : AppColors.lightBg,
                              border: Border.all(color: isSelected ? AppColors.primaryLime : AppColors.grayLight, width: 2),
                            ),
                            child: isSelected
                                ? Icon(Icons.check_rounded, size: dvpw * 0.04, color: AppColors.primaryDark)
                                : null,
                          ),
                          SizedBox(width: dvpw * 0.03),
                          Expanded(
                            child: Text(opt, style: GoogleFonts.lato(fontSize: dvpw * 0.038, color: AppColors.primaryDark)),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                SizedBox(height: dvph * 0.03),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _selectedOption == null || _submitting
                        ? null
                        : () {
                            _answers.add(_selectedOption!);
                            if (_currentQuestion < _questions.length - 1) {
                              setState(() {
                                _currentQuestion++;
                                _selectedOption = null;
                              });
                            } else {
                              _submit();
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryDark,
                      foregroundColor: AppColors.white,
                      disabledBackgroundColor: AppColors.grayLight,
                      padding: EdgeInsets.symmetric(vertical: dvph * 0.02),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(dvpw * 0.04)),
                    ),
                    child: _submitting
                        ? SizedBox(width: dvpw * 0.05, height: dvpw * 0.05, child: const CircularProgressIndicator(strokeWidth: 2, color: AppColors.white))
                        : Text(
                            _currentQuestion < _questions.length - 1 ? 'Next' : 'Submit',
                            style: GoogleFonts.lato(fontSize: dvpw * 0.042, fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

