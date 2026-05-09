import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4, 
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
          
          // Subject Progress
          Text(
            'Subject Progress',
            style: GoogleFonts.lato(
              fontSize: dvpw * 0.045,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryDark,
            ),
          ),
          SizedBox(height: dvph * 0.015),
          ...sampleSubjects.map((s) => _buildSubjectProgressCard(s, dvpw, dvph)),
          
          SizedBox(height: dvph * 0.025),
          
          // Recent Activity
          _buildRecentActivity(dvpw, dvph),
        ],
      ),
    );
  }

  Widget _buildOverallStats(double dvpw, double dvph) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Hours',
            '48.5',
            Icons.access_time_rounded,
            AppColors.blue,
            dvpw,
            dvph,
          ),
        ),
        SizedBox(width: dvpw * 0.03),
        Expanded(
          child: _buildStatCard(
            'Topics Done',
            '127',
            Icons.check_circle_rounded,
            AppColors.green,
            dvpw,
            dvph,
          ),
        ),
        SizedBox(width: dvpw * 0.03),
        Expanded(
          child: _buildStatCard(
            'Quiz Score',
            '85%',
            Icons.quiz_rounded,
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
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final progress = [0.6, 0.8, 0.4, 0.9, 0.7, 0.3, 0.5];
    
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'This Week',
                style: GoogleFonts.lato(
                  fontSize: dvpw * 0.042,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDark,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: dvpw * 0.03,
                  vertical: dvpw * 0.015,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryLime.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(dvpw * 0.02),
                ),
                child: Text(
                  '+12% vs last week',
                  style: GoogleFonts.lato(
                    fontSize: dvpw * 0.028,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: dvph * 0.02),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              return Column(
                children: [
                  Container(
                    width: dvpw * 0.08,
                    height: dvph * 0.1,
                    decoration: BoxDecoration(
                      color: AppColors.grayLight,
                      borderRadius: BorderRadius.circular(dvpw * 0.02),
                    ),
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        width: dvpw * 0.08,
                        height: dvph * 0.1 * progress[index],
                        decoration: BoxDecoration(
                          color: index == 3 ? AppColors.primaryLime : AppColors.primaryDark,
                          borderRadius: BorderRadius.circular(dvpw * 0.02),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: dvph * 0.008),
                  Text(
                    days[index],
                    style: GoogleFonts.lato(
                      fontSize: dvpw * 0.028,
                      color: AppColors.gray,
                      fontWeight: index == 3 ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                ],
              );
            }),
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
    return Column(
      children: [
        // Breadcrumb navigation
        _buildBreadcrumb(dvpw, dvph),
        Expanded(
          child: _currentView == 'subjects'
              ? _buildSubjectsList(dvpw, dvph)
              : _currentView == 'chapters'
                  ? _buildChaptersList(dvpw, dvph)
                  : _currentView == 'topics'
                      ? _buildTopicsList(dvpw, dvph)
                      : _buildFilesList(dvpw, dvph),
        ),
      ],
    );
  }

  Widget _buildBreadcrumb(double dvpw, double dvph) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: dvpw * 0.04, vertical: dvph * 0.015),
      color: AppColors.white,
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                _currentView = 'subjects';
                _selectedSubject = null;
                _selectedChapter = null;
              });
            },
            child: Text(
              '📚 Notes',
              style: GoogleFonts.lato(
                fontSize: dvpw * 0.035,
                fontWeight: FontWeight.w600,
                color: _currentView == 'Notes' ? AppColors.primaryDark : AppColors.gray,
              ),
            ),
          ),
          if (_selectedSubject != null) ...[
            Icon(Icons.chevron_right, size: dvpw * 0.05, color: AppColors.gray),
            GestureDetector(
              onTap: () {
                setState(() {
                  _currentView = 'chapters';
                  _selectedChapter = null;
                });
              },
              child: Text(
                _selectedSubject!.name,
                style: GoogleFonts.lato(
                  fontSize: dvpw * 0.035,
                  fontWeight: FontWeight.w600,
                  color: _currentView == 'chapters' ? AppColors.primaryDark : AppColors.gray,
                ),
              ),
            ),
          ],
          if (_selectedChapter != null) ...[
            Icon(Icons.chevron_right, size: dvpw * 0.05, color: AppColors.gray),
            Expanded(
              child: Text(
                _selectedChapter!.name,
                style: GoogleFonts.lato(
                  fontSize: dvpw * 0.035,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryDark,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubjectsList(double dvpw, double dvph) {
    return ListView.builder(
      padding: EdgeInsets.all(dvpw * 0.04),
      itemCount: sampleSubjects.length,
      itemBuilder: (context, index) {
        final subject = sampleSubjects[index];
        return _buildFolderCard(
          subject.icon,
          subject.name,
          '${subject.totalChapters} chapters',
          () {
            setState(() {
              _selectedSubject = subject;
              _currentView = 'chapters';
            });
          },
          dvpw,
          dvph,
        );
      },
    );
  }

  Widget _buildChaptersList(double dvpw, double dvph) {
    if (_selectedSubject == null || _selectedSubject!.chapters.isEmpty) {
      return _buildEmptyState('No chapters yet', 'Add chapters to organize your notes', dvpw, dvph);
    }
    return ListView.builder(
      padding: EdgeInsets.all(dvpw * 0.04),
      itemCount: _selectedSubject!.chapters.length,
      itemBuilder: (context, index) {
        final chapter = _selectedSubject!.chapters[index];
        return _buildFolderCard(
          '📁',
          chapter.name,
          '${chapter.totalTopics} topics • ${(chapter.progress * 100).toInt()}% done',
          () {
            setState(() {
              _selectedChapter = chapter;
              _currentView = 'topics';
            });
          },
          dvpw,
          dvph,
          progress: chapter.progress,
        );
      },
    );
  }

  Widget _buildTopicsList(double dvpw, double dvph) {
    if (_selectedChapter == null || _selectedChapter!.topics.isEmpty) {
      return _buildEmptyState('No topics yet', 'Add topics to organize content', dvpw, dvph);
    }
    return ListView.builder(
      padding: EdgeInsets.all(dvpw * 0.04),
      itemCount: _selectedChapter!.topics.length,
      itemBuilder: (context, index) {
        final topic = _selectedChapter!.topics[index];
        return _buildTopicCard(topic, dvpw, dvph);
      },
    );
  }

  Widget _buildFilesList(double dvpw, double dvph) {
    return _buildEmptyState('No files', 'Upload notes and documents', dvpw, dvph);
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
    return SingleChildScrollView(
      padding: EdgeInsets.all(dvpw * 0.04),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quiz Stats
          _buildQuizStats(dvpw, dvph),
          SizedBox(height: dvph * 0.025),
          
          Text(
            'Quizzes by Subject',
            style: GoogleFonts.lato(
              fontSize: dvpw * 0.045,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryDark,
            ),
          ),
          SizedBox(height: dvph * 0.015),
          
          ...sampleSubjects.map((subject) => _buildSubjectQuizCard(subject, dvpw, dvph)),
        ],
      ),
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
    return SingleChildScrollView(
      padding: EdgeInsets.all(dvpw * 0.04),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // XP Overview Card
          _buildXpOverview(dvpw, dvph),
          SizedBox(height: dvph * 0.025),
          
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

  Widget _buildXpOverview(double dvpw, double dvph) {
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
                      'Level ${sampleUserStats.level}',
                      style: GoogleFonts.lato(
                        fontSize: dvpw * 0.055,
                        fontWeight: FontWeight.w800,
                        color: AppColors.white,
                      ),
                    ),
                    Text(
                      '${sampleUserStats.totalXP} XP earned',
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
            '420 XP to Level ${sampleUserStats.level + 1}',
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

