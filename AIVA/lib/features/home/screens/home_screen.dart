import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/login_api_service.dart';
import '../../explore/screens/explore_screen.dart';
import '../../ai_chat/screens/ai_chat_screen.dart';
import '../../progress/screens/progress_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../roadmap/screens/roadmap_screen.dart';
import '../../todo/screens/todo_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Final retry attempt for stats if previous attempts failed
    LoginApiService.retryIfPending();
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
                          'Hello, Student! 👋',
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
                
                // Search bar
                GestureDetector(
                  onTap: () => setState(() => _currentIndex = 2), // Navigate to AI
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
                      SizedBox(width: dvpw * 0.03),
                      _buildActionCard(
                        context,
                        'Roadmap',
                        Icons.route_rounded,
                        AppColors.teal,
                        AppColors.white,
                        dvpw,
                        dvph,
                        onTap: () => _showRoadmapPopup(context, dvpw, dvph),
                      ),
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
                      SizedBox(width: dvpw * 0.03),
                      _buildActionCard(
                        context,
                        'Flashcards',
                        Icons.style_rounded,
                        AppColors.blue,
                        AppColors.white,
                        dvpw,
                        dvph,
                        comingSoon: true,
                        onTap: () => _showComingSoonDialog(context, 'Flashcards'),
                      ),
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
                        onPressed: () => setState(() => _currentIndex = 2), // AI tab
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
                
                // Recent activity
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Activity',
                      style: GoogleFonts.lato(
                        fontSize: dvpw * 0.045,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    Text(
                      'See all',
                      style: GoogleFonts.lato(
                        fontSize: dvpw * 0.035,
                        fontWeight: FontWeight.w600,
                        color: AppColors.gray,
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: dvph * 0.015),
                
                // Activity items
                _buildActivityItem(
                  context,
                  'Physics - Chapter 5',
                  '2 hours ago',
                  Icons.science_rounded,
                  AppColors.blue,
                  dvpw,
                  dvph,
                ),
                SizedBox(height: dvph * 0.012),
                _buildActivityItem(
                  context,
                  'Math Quiz Completed',
                  'Yesterday',
                  Icons.check_circle_rounded,
                  AppColors.green,
                  dvpw,
                  dvph,
                ),
                SizedBox(height: dvph * 0.012),
                _buildActivityItem(
                  context,
                  'Chemistry Notes',
                  '2 days ago',
                  Icons.note_rounded,
                  AppColors.orange,
                  dvpw,
                  dvph,
                ),
                
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
        return const AiChatScreen();
      case 3:
        return const ProgressScreen();
      case 4:
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
                _buildNavItem(Icons.auto_awesome_rounded, 'AI', 2, dvpw, dvph),
                _buildNavItem(Icons.bar_chart_rounded, 'Progress', 3, dvpw, dvph),
                _buildNavItem(Icons.person_rounded, 'Profile', 4, dvpw, dvph),
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

  void _showComingSoonDialog(BuildContext context, String feature) {
    final dvpw = MediaQuery.of(context).size.width;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(dvpw * 0.05),
        ),
        backgroundColor: AppColors.white,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(dvpw * 0.04),
              decoration: BoxDecoration(
                color: AppColors.primaryLime.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.rocket_launch_rounded,
                size: dvpw * 0.12,
                color: AppColors.primaryDark,
              ),
            ),
            SizedBox(height: dvpw * 0.04),
            Text(
              'Coming Soon!',
              style: GoogleFonts.lato(
                fontSize: dvpw * 0.055,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryDark,
              ),
            ),
            SizedBox(height: dvpw * 0.02),
            Text(
              '$feature will be available in a future update. Stay tuned!',
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(
                fontSize: dvpw * 0.038,
                color: AppColors.gray,
              ),
            ),
            SizedBox(height: dvpw * 0.05),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDark,
                  foregroundColor: AppColors.white,
                  padding: EdgeInsets.symmetric(vertical: dvpw * 0.035),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(dvpw * 0.03),
                  ),
                ),
                child: Text(
                  'Got it!',
                  style: GoogleFonts.lato(
                    fontSize: dvpw * 0.04,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRoadmapPopup(BuildContext context, double dvpw, double dvph) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: dvph * 0.7,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(dvpw * 0.06)),
        ),
        child: Column(
          children: [
            Container(
              margin: EdgeInsets.only(top: dvph * 0.015),
              width: dvpw * 0.12,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.grayLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(dvpw * 0.05),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(dvpw * 0.03),
                    decoration: BoxDecoration(
                      color: AppColors.teal.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(dvpw * 0.03),
                    ),
                    child: Icon(
                      Icons.route_rounded,
                      size: dvpw * 0.06,
                      color: AppColors.teal,
                    ),
                  ),
                  SizedBox(width: dvpw * 0.03),
                  Text(
                    'Learning Roadmaps',
                    style: GoogleFonts.lato(
                      fontSize: dvpw * 0.05,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: dvpw * 0.05),
                children: [
                  _buildRoadmapItem(context, 'Physics', '🔬', 'Mechanics → Waves → Thermodynamics', 0.65, 'physics', dvpw, dvph),
                  _buildRoadmapItem(context, 'Mathematics', '📐', 'Algebra → Calculus → Statistics', 0.45, 'math', dvpw, dvph),
                  _buildRoadmapItem(context, 'Chemistry', '⚗️', 'Organic → Inorganic → Physical', 0.30, 'chemistry', dvpw, dvph),
                  _buildRoadmapItem(context, 'Biology', '🧬', 'Cell Biology → Genetics → Ecology', 0.55, 'biology', dvpw, dvph),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoadmapItem(BuildContext context, String title, String emoji, String path, double progress, String subjectId, double dvpw, double dvph) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context); // Close popup
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => RoadmapScreen(initialSubjectId: subjectId),
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
      },
      child: Container(
        margin: EdgeInsets.only(bottom: dvph * 0.015),
        padding: EdgeInsets.all(dvpw * 0.04),
        decoration: BoxDecoration(
          color: AppColors.lightBg,
          borderRadius: BorderRadius.circular(dvpw * 0.04),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(emoji, style: TextStyle(fontSize: dvpw * 0.06)),
                SizedBox(width: dvpw * 0.03),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.lato(
                      fontSize: dvpw * 0.042,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
                Text(
                  '${(progress * 100).toInt()}%',
                  style: GoogleFonts.lato(
                    fontSize: dvpw * 0.04,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark,
                  ),
                ),
              ],
            ),
            SizedBox(height: dvph * 0.008),
            Text(
              path,
              style: GoogleFonts.lato(
                fontSize: dvpw * 0.032,
                color: AppColors.gray,
              ),
            ),
            SizedBox(height: dvph * 0.01),
            ClipRRect(
              borderRadius: BorderRadius.circular(dvpw * 0.01),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: AppColors.grayLight,
                valueColor: AlwaysStoppedAnimation(AppColors.teal),
                minHeight: dvph * 0.008,
              ),
            ),
          ],
        ),
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

  Widget _buildActivityItem(
    BuildContext context,
    String title,
    String time,
    IconData icon,
    Color iconColor,
    double dvpw,
    double dvph,
  ) {
    return Container(
      padding: EdgeInsets.all(dvpw * 0.04),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(dvpw * 0.035),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(dvpw * 0.025),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(dvpw * 0.025),
            ),
            child: Icon(
              icon,
              size: dvpw * 0.055,
              color: iconColor,
            ),
          ),
          SizedBox(width: dvpw * 0.035),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.lato(
                    fontSize: dvpw * 0.038,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryDark,
                  ),
                ),
                Text(
                  time,
                  style: GoogleFonts.lato(
                    fontSize: dvpw * 0.032,
                    color: AppColors.gray,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            size: dvpw * 0.06,
            color: AppColors.gray,
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

