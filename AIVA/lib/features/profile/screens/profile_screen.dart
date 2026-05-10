import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/profile_service.dart';
import '../models/profile_data.dart';
import '../../onboarding/screens/onboarding_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _profileData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final profile = await ProfileService.getProfile();
      if (mounted) {
        setState(() {
          _profileData = profile['student'] as Map<String, dynamic>? ?? profile;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showEditNameDialog(BuildContext context, double dvpw) async {
    final controller = TextEditingController(
      text: _profileData?['name']?.toString() ?? '',
    );
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(dvpw * 0.04)),
        title: Text(
          'Edit Name',
          style: GoogleFonts.lato(fontWeight: FontWeight.w700, color: AppColors.primaryDark),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Your name',
            filled: true,
            fillColor: AppColors.lightBg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(dvpw * 0.03),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.lato(color: AppColors.gray)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryDark,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(dvpw * 0.02)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              if (controller.text.isNotEmpty) {
                try {
                  await ProfileService.updateName(controller.text);
                  if (mounted) {
                    setState(() {
                      _profileData = {
                        ...(_profileData ?? {}),
                        'name': controller.text,
                      };
                    });
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to update name: $e'),
                        backgroundColor: AppColors.red,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              }
            },
            child: Text('Save', style: GoogleFonts.lato(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    await AuthService.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      (route) => false,
    );
  }

  Future<void> _confirmLogout(BuildContext context, double dvpw) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(dvpw * 0.05)),
        title: Text('Sign Out', style: GoogleFonts.lato(fontWeight: FontWeight.w800, fontSize: dvpw * 0.048, color: AppColors.primaryDark)),
        content: Text('Are you sure you want to sign out?', style: GoogleFonts.lato(fontSize: dvpw * 0.036, color: AppColors.gray, height: 1.4)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.lato(color: AppColors.gray, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red,
              foregroundColor: AppColors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(dvpw * 0.025)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Sign Out', style: GoogleFonts.lato(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) _handleLogout(context);
  }

  @override
  Widget build(BuildContext context) {
    final dvpw = MediaQuery.of(context).size.width;
    final dvph = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.lightBg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(dvpw, dvph),
              _buildStreakSection(dvpw, dvph),
              _buildStatsGrid(dvpw, dvph),
              _buildSettingsSection(dvpw, dvph),
              SizedBox(height: dvph * 0.12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(double dvpw, double dvph) {
    return Container(
      padding: EdgeInsets.all(dvpw * 0.05),
      decoration: BoxDecoration(
        gradient: AppColors.darkGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(dvpw * 0.08),
          bottomRight: Radius.circular(dvpw * 0.08),
        ),
      ),
      child: Column(
        children: [
          // Top bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Profile',
                style: GoogleFonts.lato(
                  fontSize: dvpw * 0.06,
                  fontWeight: FontWeight.w800,
                  color: AppColors.white,
                ),
              ),
              GestureDetector(
                onTap: () => _confirmLogout(context, dvpw),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: dvpw * 0.035, vertical: dvpw * 0.022),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(dvpw * 0.03),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.logout_rounded, size: dvpw * 0.045, color: AppColors.white),
                    SizedBox(width: dvpw * 0.015),
                    Text('Sign Out', style: GoogleFonts.lato(fontSize: dvpw * 0.032, fontWeight: FontWeight.w700, color: AppColors.white)),
                  ]),
                ),
              ),
            ],
          ),
          SizedBox(height: dvph * 0.025),
          
          // Profile info
          Row(
            children: [
              // Avatar
              Container(
                width: dvpw * 0.22,
                height: dvpw * 0.22,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(dvpw * 0.055),
                  border: Border.all(
                    color: AppColors.primaryLime,
                    width: 3,
                  ),
                ),
                child: Center(
                  child: Text(
                    '👨‍🎓',
                    style: TextStyle(fontSize: dvpw * 0.1),
                  ),
                ),
              ),
              SizedBox(width: dvpw * 0.04),

              // User info
              Expanded(
                child: _isLoading
                    ? const CircularProgressIndicator(color: AppColors.primaryLime, strokeWidth: 2)
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _profileData?['name']?.toString().isNotEmpty == true
                                      ? _profileData!['name'].toString()
                                      : 'Student',
                                  style: GoogleFonts.lato(
                                    fontSize: dvpw * 0.055,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.white,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => _showEditNameDialog(context, dvpw),
                                child: Container(
                                  padding: EdgeInsets.all(dvpw * 0.018),
                                  decoration: BoxDecoration(
                                    color: AppColors.darkerGray,
                                    borderRadius: BorderRadius.circular(dvpw * 0.02),
                                  ),
                                  child: Icon(Icons.edit_rounded, size: dvpw * 0.04, color: AppColors.primaryLime),
                                ),
                              ),
                            ],
                          ),
                          if (_profileData?['phone'] != null) ...[
                            SizedBox(height: dvph * 0.004),
                            Text(
                              _profileData!['phone'].toString(),
                              style: GoogleFonts.lato(
                                fontSize: dvpw * 0.032,
                                color: AppColors.grayLight,
                              ),
                            ),
                          ],
                          SizedBox(height: dvph * 0.008),
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: dvpw * 0.025,
                                  vertical: dvpw * 0.012,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLime,
                                  borderRadius: BorderRadius.circular(dvpw * 0.02),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.school_rounded,
                                      size: dvpw * 0.04,
                                      color: AppColors.primaryDark,
                                    ),
                                    SizedBox(width: dvpw * 0.01),
                                    Text(
                                      '${_profileData?['enrolled_courses_count'] ?? 0} Courses',
                                      style: GoogleFonts.lato(
                                        fontSize: dvpw * 0.032,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primaryDark,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStreakSection(double dvpw, double dvph) {
    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    
    return Container(
      margin: EdgeInsets.all(dvpw * 0.04),
      padding: EdgeInsets.all(dvpw * 0.045),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(dvpw * 0.05),
        boxShadow: [
          BoxShadow(
            color: AppColors.gray.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Streak header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(dvpw * 0.025),
                    decoration: BoxDecoration(
                      color: AppColors.orange.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(dvpw * 0.03),
                    ),
                    child: Text('🔥', style: TextStyle(fontSize: dvpw * 0.06)),
                  ),
                  SizedBox(width: dvpw * 0.03),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Streak',
                        style: GoogleFonts.lato(
                          fontSize: dvpw * 0.035,
                          color: AppColors.gray,
                        ),
                      ),
                      Text(
                        '${sampleUserStats.currentStreak} Days',
                        style: GoogleFonts.lato(
                          fontSize: dvpw * 0.055,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Longest',
                    style: GoogleFonts.lato(
                      fontSize: dvpw * 0.03,
                      color: AppColors.gray,
                    ),
                  ),
                  Text(
                    '${sampleUserStats.longestStreak} Days',
                    style: GoogleFonts.lato(
                      fontSize: dvpw * 0.04,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: dvph * 0.02),
          
          // Week streak visualization
          Container(
            padding: EdgeInsets.all(dvpw * 0.03),
            decoration: BoxDecoration(
              color: AppColors.lightBg,
              borderRadius: BorderRadius.circular(dvpw * 0.03),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(7, (index) {
                final isActive = weeklyStreak[index];
                final isToday = index == 6;
                return Column(
                  children: [
                    Text(
                      days[index],
                      style: GoogleFonts.lato(
                        fontSize: dvpw * 0.03,
                        fontWeight: FontWeight.w600,
                        color: AppColors.gray,
                      ),
                    ),
                    SizedBox(height: dvph * 0.008),
                    Container(
                      width: dvpw * 0.09,
                      height: dvpw * 0.09,
                      decoration: BoxDecoration(
                        color: isActive ? AppColors.primaryLime : AppColors.grayLight,
                        shape: BoxShape.circle,
                        border: isToday ? Border.all(
                          color: AppColors.primaryDark,
                          width: 2,
                        ) : null,
                      ),
                      child: Center(
                        child: Icon(
                          isActive ? Icons.check_rounded : Icons.close_rounded,
                          size: dvpw * 0.045,
                          color: isActive ? AppColors.primaryDark : AppColors.gray,
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(double dvpw, double dvph) {
    final enrolled = _profileData?['enrolled_courses_count']?.toString() ?? '0';
    final completed = _profileData?['completed_courses_count']?.toString() ?? '0';
    final watchHours = _profileData?['total_watch_hours']?.toString() ?? '0';
    final credits = _profileData?['credits_total']?.toString() ?? '0';

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: dvpw * 0.04),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statistics',
            style: GoogleFonts.lato(
              fontSize: dvpw * 0.045,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryDark,
            ),
          ),
          SizedBox(height: dvph * 0.015),
          Row(
            children: [
              Expanded(child: _buildStatCard('${watchHours}h', 'Watch Hours', Icons.access_time_rounded, AppColors.blue, dvpw, dvph)),
              SizedBox(width: dvpw * 0.03),
              Expanded(child: _buildStatCard(completed, 'Completed', Icons.check_circle_rounded, AppColors.green, dvpw, dvph)),
            ],
          ),
          SizedBox(height: dvpw * 0.03),
          Row(
            children: [
              Expanded(child: _buildStatCard(enrolled, 'Enrolled', Icons.school_rounded, AppColors.purple, dvpw, dvph)),
              SizedBox(width: dvpw * 0.03),
              Expanded(child: _buildStatCard(credits, 'Credits', Icons.star_rounded, AppColors.orange, dvpw, dvph)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon, Color color, double dvpw, double dvph) {
    return Container(
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
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(dvpw * 0.025),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(dvpw * 0.025),
            ),
            child: Icon(icon, size: dvpw * 0.055, color: color),
          ),
          SizedBox(width: dvpw * 0.03),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.lato(
                  fontSize: dvpw * 0.05,
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
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsSection(double dvpw, double dvph) {
    final unlockedAchievements = sampleAchievements.where((a) => a.isUnlocked).toList();
    final lockedAchievements = sampleAchievements.where((a) => !a.isUnlocked).toList();
    
    return Padding(
      padding: EdgeInsets.all(dvpw * 0.04),
      child: Column(
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
                    color: AppColors.green,
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
      ),
    );
  }

  Widget _buildAchievementBadge(Achievement achievement, double dvpw, double dvph, bool isUnlocked) {
    return Container(
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
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: dvpw * 0.04),
      child: Column(
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
      ),
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

  Widget _buildSettingsSection(double dvpw, double dvph) {
    return Padding(
      padding: EdgeInsets.all(dvpw * 0.04),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Settings',
            style: GoogleFonts.lato(
              fontSize: dvpw * 0.045,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryDark,
            ),
          ),
          SizedBox(height: dvph * 0.015),
          Container(
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
              children: [
                _buildSettingItem(Icons.person_outline_rounded, 'Edit Profile', dvpw, dvph, onTap: () => _showEditNameDialog(context, dvpw)),
                _buildDivider(dvpw),
                _buildSettingItem(Icons.notifications_outlined, 'Notifications', dvpw, dvph),
                _buildDivider(dvpw),
                _buildSettingItem(Icons.lock_outline_rounded, 'Privacy', dvpw, dvph),
                _buildDivider(dvpw),
                _buildSettingItem(Icons.help_outline_rounded, 'Help & Support', dvpw, dvph),
                _buildDivider(dvpw),
                _buildSettingItem(Icons.info_outline_rounded, 'About', dvpw, dvph),
                _buildDivider(dvpw),
                _buildSettingItem(Icons.logout_rounded, 'Logout', dvpw, dvph, isDestructive: true, onTap: () => _handleLogout(context)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem(IconData icon, String title, double dvpw, double dvph, {bool isDestructive = false, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap ?? () {},
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: dvpw * 0.04,
          vertical: dvph * 0.018,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: dvpw * 0.055,
              color: isDestructive ? AppColors.red : AppColors.gray,
            ),
            SizedBox(width: dvpw * 0.04),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.lato(
                  fontSize: dvpw * 0.038,
                  fontWeight: FontWeight.w500,
                  color: isDestructive ? AppColors.red : AppColors.primaryDark,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: dvpw * 0.055,
              color: AppColors.grayLight,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(double dvpw) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: dvpw * 0.04),
      child: Divider(color: AppColors.grayLight, height: 1),
    );
  }
}

