import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/api_service.dart';
import '../../../core/models/student.dart';
import '../../explore/screens/explore_screen.dart';
import '../../explore/services/explore_service.dart';
import '../../ai_chat/screens/ai_chat_screen.dart';
import '../../progress/screens/progress_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../todo/screens/todo_screen.dart';
import '../../video_player/screens/video_player_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  Student? _student;
  List<TodayLecture> _todayLectures = [];
  List<Map<String, dynamic>> _myCourses = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final student = await AuthService.getCurrentStudent();
    final today = await ExploreService.fetchTodayLectures();
    List<Map<String, dynamic>> courses = [];
    try {
      final import = await ApiService.get('/api/my-courses');
      if (import['success'] == true) {
        courses = List<Map<String, dynamic>>.from(
          (import['courses'] as List<dynamic>? ?? []).take(3),
        );
      }
    } catch (_) {}
    if (mounted) {
      setState(() {
        _student = student;
        _todayLectures = today;
        _myCourses = courses;
      });
    }
  }

  Widget _buildHomeContent(double dvpw, double dvph) {
    return SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: dvpw * 0.05),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: dvph * 0.02),

                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hello, ${_student?.displayName ?? 'Learner'}! 👋',
                          style: GoogleFonts.lato(
                            fontSize: dvpw * 0.045,
                            fontWeight: FontWeight.w400,
                            color: AppColors.gray,
                          ),
                        ),
                        SizedBox(height: dvph * 0.005),
                        Text(
                          "Let's learn something",
                          style: GoogleFonts.lato(
                            fontSize: dvpw * 0.06,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ],
                    ),
                    // Profile avatar
                    Container(
                      width: dvpw * 0.12,
                      height: dvpw * 0.12,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLime,
                        borderRadius: BorderRadius.circular(dvpw * 0.035),
                      ),
                      child: Icon(
                        Icons.person_rounded,
                        size: dvpw * 0.07,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: dvph * 0.03),

                // Search bar — navigates to AiChatScreen
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AiChatScreen()),
                  ),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: dvpw * 0.04,
                      vertical: dvph * 0.015,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(dvpw * 0.04),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.grayLight.withOpacity(0.5),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.search_rounded,
                          size: dvpw * 0.06,
                          color: AppColors.gray,
                        ),
                        SizedBox(width: dvpw * 0.03),
                        Expanded(
                          child: Text(
                            'Ask AIVA anything...',
                            style: GoogleFonts.lato(
                              fontSize: dvpw * 0.04,
                              color: AppColors.gray,
                            ),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.all(dvpw * 0.02),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLime,
                            borderRadius: BorderRadius.circular(dvpw * 0.025),
                          ),
                          child: Icon(
                            Icons.mic_rounded,
                            size: dvpw * 0.05,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: dvph * 0.03),

                // Today's Plan
                if (_todayLectures.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Today's Plan",
                        style: GoogleFonts.lato(fontSize: dvpw * 0.045, fontWeight: FontWeight.w700, color: AppColors.primaryDark),
                      ),
                      Text(
                        '${_todayLectures.where((l) => l.isCompleted).length}/${_todayLectures.length} done',
                        style: GoogleFonts.lato(fontSize: dvpw * 0.035, color: AppColors.gray),
                      ),
                    ],
                  ),
                  SizedBox(height: dvph * 0.012),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _todayLectures.map((lec) {
                        Color color;
                        try {
                          final h = lec.thumbnailColor.replaceAll('#', '');
                          color = Color(int.parse('FF$h', radix: 16));
                        } catch (_) {
                          color = AppColors.purple;
                        }
                        return GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => VideoPlayerScreen(
                                lectureId: lec.lectureId,
                                title: lec.title,
                                courseId: lec.courseId,
                              ),
                            ),
                          ),
                          child: Container(
                            width: dvpw * 0.55,
                            margin: EdgeInsets.only(right: dvpw * 0.03),
                            padding: EdgeInsets.all(dvpw * 0.04),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(dvpw * 0.04),
                              border: Border.all(color: color.withOpacity(0.3)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(dvpw * 0.02),
                                      decoration: BoxDecoration(color: color.withOpacity(0.2), shape: BoxShape.circle),
                                      child: Icon(
                                        lec.isCompleted ? Icons.check_circle_rounded : Icons.play_circle_outline_rounded,
                                        color: color,
                                        size: dvpw * 0.045,
                                      ),
                                    ),
                                    SizedBox(width: dvpw * 0.02),
                                    Expanded(
                                      child: Text(
                                        lec.courseTitle,
                                        style: GoogleFonts.lato(fontSize: dvpw * 0.028, color: AppColors.gray),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: dvph * 0.008),
                                Text(
                                  lec.title,
                                  style: GoogleFonts.lato(fontSize: dvpw * 0.035, fontWeight: FontWeight.w700, color: AppColors.primaryDark),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: dvph * 0.005),
                                Text(
                                  '${lec.estimatedMinutes} min',
                                  style: GoogleFonts.lato(fontSize: dvpw * 0.03, color: AppColors.gray),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  SizedBox(height: dvph * 0.03),
                ],

                // Quick actions
                Text(
                  'Quick Actions',
                  style: GoogleFonts.lato(
                    fontSize: dvpw * 0.045,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark,
                  ),
                ),

                SizedBox(height: dvph * 0.015),

                // Action cards row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildActionCard(
                        context,
                        'Study Mode',
                        Icons.menu_book_rounded,
                        AppColors.purple,
                        AppColors.white,
                        dvpw,
                        dvph,
                        onTap: () => setState(() => _currentIndex = 1), // Explore page
                      ),
                      SizedBox(width: dvpw * 0.03),
                      _buildActionCard(
                        context,
                        'Quiz',
                        Icons.quiz_rounded,
                        AppColors.pink,
                        AppColors.white,
                        dvpw,
                        dvph,
                        onTap: () => _navigateToProgressTab(2), // Quiz tab
                      ),
                      // SizedBox(width: dvpw * 0.03),
                      // _buildActionCard(
                      //   context,
                      //   'Roadmap',
                      //   Icons.route_rounded,
                      //   AppColors.teal,
                      //   AppColors.white,
                      //   dvpw,
                      //   dvph,
                      //   onTap: () => _showRoadmapPopup(context, dvpw, dvph),
                      // ),
                      SizedBox(width: dvpw * 0.03),
                      _buildActionCard(
                        context,
                        'Todo',
                        Icons.checklist_rounded,
                        AppColors.orange,
                        AppColors.white,
                        dvpw,
                        dvph,
                        onTap: () => _navigateToTodo(context),
                      ),
                      // SizedBox(width: dvpw * 0.03),
                      // _buildActionCard(
                      //   context,
                      //   'Flashcards',
                      //   Icons.style_rounded,
                      //   AppColors.blue,
                      //   AppColors.white,
                      //   dvpw,
                      //   dvph,
                      //   comingSoon: true,
                      //   onTap: () => _showComingSoonDialog(context, 'Flashcards'),
                      // ),
                      SizedBox(width: dvpw * 0.03),
                      _buildActionCard(
                        context,
                        'Notes',
                        Icons.note_alt_rounded,
                        AppColors.green,
                        AppColors.white,
                        dvpw,
                        dvph,
                        onTap: () => _navigateToProgressTab(1), // Notes tab
                      ),
                    ],
                  ),
                ),

                SizedBox(height: dvph * 0.03),

                // AI Chat card
                Container(
                  width: dvpw,
                  padding: EdgeInsets.all(dvpw * 0.05),
                  decoration: BoxDecoration(
                    gradient: AppColors.darkGradient,
                    borderRadius: BorderRadius.circular(dvpw * 0.05),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(dvpw * 0.03),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLime,
                              borderRadius: BorderRadius.circular(dvpw * 0.03),
                            ),
                            child: Icon(
                              Icons.auto_awesome_rounded,
                              size: dvpw * 0.06,
                              color: AppColors.primaryDark,
                            ),
                          ),
                          SizedBox(width: dvpw * 0.03),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'AIVA Assistant',
                                style: GoogleFonts.lato(
                                  fontSize: dvpw * 0.045,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.white,
                                ),
                              ),
                              Text(
                                'Your AI study companion',
                                style: GoogleFonts.lato(
                                  fontSize: dvpw * 0.032,
                                  color: AppColors.grayLight,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: dvph * 0.02),
                      Text(
                        'Ask me anything about your studies!\nI can help with explanations, summaries, and practice questions.',
                        style: GoogleFonts.lato(
                          fontSize: dvpw * 0.035,
                          color: AppColors.grayLight,
                          height: 1.5,
                        ),
                      ),
                      SizedBox(height: dvph * 0.02),
                      ElevatedButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AiChatScreen()),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryLime,
                          foregroundColor: AppColors.primaryDark,
                          elevation: 0,
                          padding: EdgeInsets.symmetric(
                            horizontal: dvpw * 0.06,
                            vertical: dvph * 0.012,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(dvpw * 0.025),
                          ),
                        ),
                        child: Text(
                          'Start Chat',
                          style: GoogleFonts.lato(
                            fontSize: dvpw * 0.035,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: dvph * 0.03),

                // My Courses section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'My Courses',
                      style: GoogleFonts.lato(
                        fontSize: dvpw * 0.045,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _currentIndex = 1),
                      child: Text(
                        'View All',
                        style: GoogleFonts.lato(
                          fontSize: dvpw * 0.035,
                          fontWeight: FontWeight.w600,
                          color: AppColors.gray,
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: dvph * 0.015),

                if (_myCourses.isEmpty)
                  Container(
                    padding: EdgeInsets.all(dvpw * 0.05),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(dvpw * 0.04),
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.school_rounded, size: dvpw * 0.12, color: AppColors.grayLight),
                          SizedBox(height: dvph * 0.01),
                          Text(
                            'No enrolled courses yet',
                            style: GoogleFonts.lato(
                              fontSize: dvpw * 0.038,
                              color: AppColors.gray,
                            ),
                          ),
                          SizedBox(height: dvph * 0.008),
                          GestureDetector(
                            onTap: () => setState(() => _currentIndex = 1),
                            child: Text(
                              'Explore Courses',
                              style: GoogleFonts.lato(
                                fontSize: dvpw * 0.038,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ..._myCourses.map((course) {
                    final title = course['title']?.toString() ?? 'Course';
                    final progress = (course['progress_percent'] as num?)?.toDouble() ?? 0.0;
                    final progressFraction = progress / 100.0;
                    Color color;
                    try {
                      final h = (course['thumbnail_color'] as String? ?? '#6C63FF').replaceAll('#', '');
                      color = Color(int.parse('FF$h', radix: 16));
                    } catch (_) {
                      color = AppColors.purple;
                    }
                    return Container(
                      margin: EdgeInsets.only(bottom: dvph * 0.012),
                      padding: EdgeInsets.all(dvpw * 0.04),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(dvpw * 0.04),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.gray.withOpacity(0.07),
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
                              Container(
                                width: dvpw * 0.1,
                                height: dvpw * 0.1,
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(dvpw * 0.025),
                                ),
                                child: Center(
                                  child: Text(
                                    title.isNotEmpty ? title[0].toUpperCase() : 'C',
                                    style: GoogleFonts.lato(
                                      fontSize: dvpw * 0.045,
                                      fontWeight: FontWeight.w800,
                                      color: color,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: dvpw * 0.03),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style: GoogleFonts.lato(
                                        fontSize: dvpw * 0.038,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primaryDark,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: dvph * 0.004),
                                    Text(
                                      '${progress.toInt()}% complete',
                                      style: GoogleFonts.lato(
                                        fontSize: dvpw * 0.032,
                                        color: AppColors.gray,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: dvph * 0.012),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(dvpw * 0.01),
                            child: LinearProgressIndicator(
                              value: progressFraction.clamp(0.0, 1.0),
                              backgroundColor: AppColors.grayLight,
                              valueColor: AlwaysStoppedAnimation(color),
                              minHeight: dvph * 0.008,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                SizedBox(height: dvph * 0.1),
              ],
            ),
          ),
        );
  }

  Widget _buildBody(double dvpw, double dvph) {
    switch (_currentIndex) {
      case 0:
        return SafeArea(child: _buildHomeContent(dvpw, dvph));
      case 1:
        return const ExploreScreen();
      case 2:
        return const ProgressScreen();
      case 3:
        return const ProfileScreen();
      default:
        return SafeArea(child: _buildHomeContent(dvpw, dvph));
    }
  }

  @override
  Widget build(BuildContext context) {
    final dvpw = MediaQuery.of(context).size.width;
    final dvph = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.lightBg,
      body: _buildBody(dvpw, dvph),
      extendBody: true,
      bottomNavigationBar: Container(
        margin: EdgeInsets.symmetric(horizontal: dvpw * 0.04, vertical: dvph * 0.015),
        decoration: BoxDecoration(
          color: AppColors.primaryDark,
          borderRadius: BorderRadius.circular(dvpw * 0.07),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryDark.withOpacity(0.25),
              blurRadius: 20,
              spreadRadius: 0,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: dvpw * 0.02,
              vertical: dvph * 0.012,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(Icons.home_rounded, 'Home', 0, dvpw, dvph),
                _buildNavItem(Icons.explore_rounded, 'Explore', 1, dvpw, dvph),
                _buildNavItem(Icons.bar_chart_rounded, 'Progress', 2, dvpw, dvph),
                _buildNavItem(Icons.person_rounded, 'Profile', 3, dvpw, dvph),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToProgressTab(int tabIndex) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => ProgressScreen(initialTabIndex: tabIndex),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  void _navigateToTodo(BuildContext context) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const TodoScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    IconData icon,
    Color bgColor,
    Color iconColor,
    double dvpw,
    double dvph, {
    VoidCallback? onTap,
    bool comingSoon = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            width: dvpw * 0.28,
            padding: EdgeInsets.all(dvpw * 0.04),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(dvpw * 0.04),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  icon,
                  size: dvpw * 0.08,
                  color: iconColor,
                ),
                SizedBox(height: dvph * 0.01),
                Text(
                  title,
                  style: GoogleFonts.lato(
                    fontSize: dvpw * 0.035,
                    fontWeight: FontWeight.w600,
                    color: iconColor,
                  ),
                ),
              ],
            ),
          ),
          if (comingSoon)
            Positioned(
              top: dvpw * 0.02,
              right: dvpw * 0.02,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: dvpw * 0.015,
                  vertical: dvpw * 0.008,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryDark,
                  borderRadius: BorderRadius.circular(dvpw * 0.01),
                ),
                child: Text(
                  'Soon',
                  style: GoogleFonts.lato(
                    fontSize: dvpw * 0.022,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index, double dvpw, double dvph) {
    final isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: dvpw * 0.025,
          vertical: dvph * 0.006,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.all(dvpw * 0.022),
              decoration: BoxDecoration(
                color: isActive ? AppColors.primaryLime : Colors.transparent,
                borderRadius: BorderRadius.circular(dvpw * 0.035),
              ),
              child: Icon(
                icon,
                size: dvpw * 0.055,
                color: isActive ? AppColors.primaryDark : AppColors.grayLight,
              ),
            ),
            SizedBox(height: dvph * 0.004),
            Text(
              label,
              style: GoogleFonts.lato(
                fontSize: dvpw * 0.026,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? AppColors.primaryLime : AppColors.grayLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
