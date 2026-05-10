import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/course.dart';
import '../services/explore_service.dart';
import '../../courses/screens/course_detail_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

// Simple filter options to replace VideoCategory enum
enum _ExploreFilter { all, continueLearning, newCourses }

class _ExploreScreenState extends State<ExploreScreen> {
  _ExploreFilter _selectedFilter = _ExploreFilter.all;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<Course> _courses = [];
  List<TodayLecture> _todayLectures = [];
  List<Map<String, dynamic>> _lectureCards = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      ExploreService.fetchCourses(),
      ExploreService.fetchTodayLectures(),
      ExploreService.fetchLectureCards(),
    ]);
    if (!mounted) return;
    setState(() {
      _courses = results[0] as List<Course>;
      _todayLectures = results[1] as List<TodayLecture>;
      _lectureCards = results[2] as List<Map<String, dynamic>>;
      _isLoading = false;
    });
  }

  // Build lecture cards from API or fall back to course-based cards
  List<Map<String, dynamic>> get _displayCards {
    // Use lecture cards if available, otherwise build from courses
    List<Map<String, dynamic>> cards;
    if (_lectureCards.isNotEmpty) {
      cards = _lectureCards;
    } else {
      // Build simple lecture-like cards from courses
      cards = _courses.map((c) => {
        'id': c.id,
        'title': c.title,
        'course_title': c.title,
        'course_id': c.id,
        'instructor': c.instructor ?? 'AIVA',
        'thumbnail_color': c.thumbnailColor,
        'is_enrolled': false,
        'duration_minutes': (c.estimatedHours * 60).toInt(),
      }).toList();
    }

    // Filter by search
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      cards = cards.where((c) =>
        (c['title']?.toString() ?? '').toLowerCase().contains(q) ||
        (c['course_title']?.toString() ?? '').toLowerCase().contains(q) ||
        (c['instructor']?.toString() ?? '').toLowerCase().contains(q)
      ).toList();
    }

    // Filter by tab
    final todayIds = {for (final t in _todayLectures) t.lectureId};
    if (_selectedFilter == _ExploreFilter.continueLearning) {
      cards = cards.where((c) =>
        todayIds.contains(c['id']?.toString()) ||
        c['is_enrolled'] == true
      ).toList();
    } else if (_selectedFilter == _ExploreFilter.newCourses) {
      cards = cards.where((c) => c['is_enrolled'] != true).toList();
    }

    return cards;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _parseColor(String? hex) {
    try {
      final h = (hex ?? '#6C63FF').replaceAll('#', '');
      return Color(int.parse('FF$h', radix: 16));
    } catch (_) {
      return AppColors.purple;
    }
  }

  void _onLectureTap(Map<String, dynamic> card) {
    final lectureId = card['id']?.toString() ?? '';
    final courseId = card['course_id']?.toString() ?? '';
    final isEnrolled = card['is_enrolled'] == true;
    final todayIds = {for (final t in _todayLectures) t.lectureId};

    if (isEnrolled || todayIds.contains(lectureId)) {
      // Go directly to video player
      Navigator.of(context).pushNamed('/video', arguments: {
        'lecture_id': lectureId,
        'title': card['title']?.toString() ?? 'Lecture',
        'course_id': courseId,
      });
    } else {
      // Go to course detail
      final course = _courses.firstWhere(
        (c) => c.id == courseId,
        orElse: () => Course(id: courseId, title: card['course_title']?.toString() ?? card['title']?.toString() ?? ''),
      );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => CourseDetailScreen(course: course)),
      );
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
            _buildFilterChips(dvpw, dvph),
            // Today's lectures section
            if (!_isLoading && _todayLectures.isNotEmpty)
              _buildTodaySection(dvpw, dvph),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primaryLime))
                  : _displayCards.isEmpty
                      ? _buildEmptyState(dvpw, dvph)
                      : RefreshIndicator(
                          onRefresh: _loadData,
                          color: AppColors.primaryLime,
                          child: ListView.builder(
                            padding: EdgeInsets.symmetric(
                              horizontal: dvpw * 0.04,
                              vertical: dvph * 0.01,
                            ),
                            itemCount: _displayCards.length,
                            itemBuilder: (context, index) => GestureDetector(
                              onTap: () => _onLectureTap(_displayCards[index]),
                              child: _buildLectureCard(_displayCards[index], dvpw, dvph),
                            ),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodaySection(double dvpw, double dvph) {
    return Container(
      padding: EdgeInsets.fromLTRB(dvpw * 0.04, dvph * 0.015, dvpw * 0.04, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Continue Today',
            style: GoogleFonts.lato(
              fontSize: dvpw * 0.04,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryDark,
            ),
          ),
          SizedBox(height: dvph * 0.01),
          SizedBox(
            height: dvpw * 0.28,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _todayLectures.length,
              itemBuilder: (_, i) => _buildTodayCard(_todayLectures[i], dvpw, dvph),
            ),
          ),
          SizedBox(height: dvph * 0.015),
        ],
      ),
    );
  }

  Widget _buildTodayCard(TodayLecture lec, double dvpw, double dvph) {
    final Color borderColor = lec.priority == 'high'
        ? AppColors.primaryLime
        : lec.priority == 'medium'
            ? AppColors.orange
            : AppColors.grayLight;
    final Color pillColor = lec.priority == 'high'
        ? AppColors.primaryLime
        : lec.priority == 'medium'
            ? AppColors.orange
            : AppColors.gray;

    return GestureDetector(
      onTap: () {
        // Navigate to video player directly
        Navigator.of(context).pushNamed('/video', arguments: {
          'lecture_id': lec.lectureId,
          'title': lec.title,
          'course_id': lec.courseId,
        });
      },
      child: Container(
        width: dvpw * 0.55,
        margin: EdgeInsets.only(right: dvpw * 0.03),
        padding: EdgeInsets.all(dvpw * 0.035),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(dvpw * 0.035),
          border: Border(left: BorderSide(color: borderColor, width: 3)),
          boxShadow: [BoxShadow(color: AppColors.grayLight.withOpacity(0.5), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: dvpw * 0.02, vertical: dvpw * 0.008),
              decoration: BoxDecoration(
                color: pillColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(dvpw * 0.02),
              ),
              child: Text(
                lec.priority.toUpperCase(),
                style: GoogleFonts.lato(fontSize: dvpw * 0.025, fontWeight: FontWeight.w700, color: pillColor == AppColors.primaryLime ? AppColors.primaryDark : pillColor),
              ),
            ),
            SizedBox(height: dvpw * 0.02),
            Expanded(
              child: Text(
                lec.title,
                style: GoogleFonts.lato(fontSize: dvpw * 0.035, fontWeight: FontWeight.w600, color: AppColors.primaryDark),
                maxLines: 2, overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(height: dvpw * 0.015),
            Text(
              '${lec.courseTitle} • ${lec.estimatedMinutes}min',
              style: GoogleFonts.lato(fontSize: dvpw * 0.028, color: AppColors.gray),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
            if (lec.isCompleted)
              Container(
                margin: EdgeInsets.only(top: dvpw * 0.015),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, size: dvpw * 0.04, color: AppColors.green),
                    SizedBox(width: dvpw * 0.01),
                    Text('Completed', style: GoogleFonts.lato(fontSize: dvpw * 0.028, color: AppColors.green, fontWeight: FontWeight.w600)),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(dvpw * 0.02),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLime,
                      borderRadius: BorderRadius.circular(dvpw * 0.025),
                    ),
                    child: Icon(
                      Icons.explore_rounded,
                      size: dvpw * 0.055,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  SizedBox(width: dvpw * 0.03),
                  Text(
                    'Explore',
                    style: GoogleFonts.lato(
                      fontSize: dvpw * 0.06,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  _buildIconButton(Icons.cast_rounded, dvpw),
                  SizedBox(width: dvpw * 0.02),
                  _buildIconButton(Icons.notifications_none_rounded, dvpw),
                ],
              ),
            ],
          ),

          SizedBox(height: dvph * 0.018),

          // Search bar - Clean aligned design
          Container(
            height: dvpw * 0.12,
            decoration: BoxDecoration(
              color: AppColors.lightBg,
              borderRadius: BorderRadius.circular(dvpw * 0.06),
              border: Border.all(
                color: AppColors.grayLight,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // Search icon
                Padding(
                  padding: EdgeInsets.only(left: dvpw * 0.04),
                  child: Icon(
                    Icons.search_rounded,
                    size: dvpw * 0.06,
                    color: AppColors.gray,
                  ),
                ),
                
                // Text field
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    textAlignVertical: TextAlignVertical.center,
                    style: GoogleFonts.lato(
                      fontSize: dvpw * 0.04,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primaryDark,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search videos, channels...',
                      hintStyle: GoogleFonts.lato(
                        fontSize: dvpw * 0.04,
                        fontWeight: FontWeight.w400,
                        color: AppColors.gray,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: dvpw * 0.03,
                      ),
                      isCollapsed: true,
                    ),
                  ),
                ),
                
                // Clear button (when searching)
                if (_searchQuery.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                      });
                      FocusScope.of(context).unfocus();
                    },
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: dvpw * 0.03),
                      child: Icon(
                        Icons.close_rounded,
                        size: dvpw * 0.055,
                        color: AppColors.gray,
                      ),
                    ),
                  ),
                
                // Mic button
                Container(
                  height: dvpw * 0.12,
                  width: dvpw * 0.12,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLime,
                    borderRadius: BorderRadius.horizontal(
                      right: Radius.circular(dvpw * 0.058),
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        // Voice search action
                      },
                      borderRadius: BorderRadius.horizontal(
                        right: Radius.circular(dvpw * 0.058),
                      ),
                      child: Icon(
                        Icons.mic_rounded,
                        size: dvpw * 0.06,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton(IconData icon, double dvpw) {
    return Container(
      padding: EdgeInsets.all(dvpw * 0.025),
      decoration: BoxDecoration(
        color: AppColors.lightBg,
        borderRadius: BorderRadius.circular(dvpw * 0.025),
      ),
      child: Icon(
        icon,
        size: dvpw * 0.055,
        color: AppColors.primaryDark,
      ),
    );
  }

  Widget _buildFilterChips(double dvpw, double dvph) {
    final filters = [
      (_ExploreFilter.all, 'All'),
      (_ExploreFilter.continueLearning, 'Continue Learning'),
      (_ExploreFilter.newCourses, 'New'),
    ];
    return Container(
      padding: EdgeInsets.symmetric(vertical: dvph * 0.012),
      color: AppColors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: dvpw * 0.04),
        child: Row(
          children: filters.map((entry) {
            final filter = entry.$1;
            final label = entry.$2;
            final isSelected = _selectedFilter == filter;
            return Padding(
              padding: EdgeInsets.only(right: dvpw * 0.025),
              child: GestureDetector(
                onTap: () => setState(() => _selectedFilter = filter),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.symmetric(
                    horizontal: dvpw * 0.04,
                    vertical: dvph * 0.01,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primaryDark : AppColors.white,
                    borderRadius: BorderRadius.circular(dvpw * 0.06),
                    border: Border.all(
                      color: isSelected ? AppColors.primaryDark : AppColors.grayLight,
                      width: 1.5,
                    ),
                    boxShadow: isSelected
                        ? [BoxShadow(color: AppColors.primaryDark.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 2))]
                        : null,
                  ),
                  child: Text(
                    label,
                    style: GoogleFonts.lato(
                      fontSize: dvpw * 0.035,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? AppColors.white : AppColors.primaryDark,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildLectureCard(Map<String, dynamic> card, double dvpw, double dvph) {
    final title = card['title']?.toString() ?? 'Lecture';
    final courseTitle = card['course_title']?.toString() ?? '';
    final instructor = card['instructor']?.toString() ?? 'AIVA';
    final color = _parseColor(card['thumbnail_color']?.toString());
    final isEnrolled = card['is_enrolled'] == true;
    final durationMin = (card['duration_minutes'] as num?)?.toInt();
    final durationStr = durationMin != null
        ? durationMin >= 60
            ? '${durationMin ~/ 60}h ${durationMin % 60}m'
            : '${durationMin}m'
        : null;

    return Container(
      margin: EdgeInsets.only(bottom: dvph * 0.015),
      padding: EdgeInsets.all(dvpw * 0.04),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(dvpw * 0.04),
        boxShadow: [
          BoxShadow(color: AppColors.grayLight.withOpacity(0.5), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          // Left colored rectangle with first letter
          Container(
            width: dvpw * 0.14,
            height: dvpw * 0.14,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(dvpw * 0.03),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Center(
              child: Text(
                title.isNotEmpty ? title[0].toUpperCase() : 'L',
                style: GoogleFonts.lato(
                  fontSize: dvpw * 0.06,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
            ),
          ),
          SizedBox(width: dvpw * 0.04),
          // Right side info
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
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (courseTitle.isNotEmpty && courseTitle != title) ...[
                  SizedBox(height: dvpw * 0.01),
                  Text(
                    courseTitle,
                    style: GoogleFonts.lato(fontSize: dvpw * 0.032, color: AppColors.gray),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                SizedBox(height: dvpw * 0.01),
                Row(
                  children: [
                    Text(
                      instructor,
                      style: GoogleFonts.lato(fontSize: dvpw * 0.03, color: AppColors.gray),
                    ),
                    if (durationStr != null) ...[
                      Text(' · ', style: GoogleFonts.lato(fontSize: dvpw * 0.03, color: AppColors.gray)),
                      Text(durationStr, style: GoogleFonts.lato(fontSize: dvpw * 0.03, color: AppColors.gray)),
                    ],
                  ],
                ),
                if (isEnrolled) ...[
                  SizedBox(height: dvpw * 0.015),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: dvpw * 0.02, vertical: dvpw * 0.008),
                    decoration: BoxDecoration(
                      color: AppColors.green.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(dvpw * 0.02),
                    ),
                    child: Text(
                      'Enrolled',
                      style: GoogleFonts.lato(fontSize: dvpw * 0.028, fontWeight: FontWeight.w600, color: AppColors.green),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, size: dvpw * 0.055, color: AppColors.gray),
        ],
      ),
    );
  }

  Widget _buildEmptyState(double dvpw, double dvph) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: dvpw * 0.2, color: AppColors.grayLight),
          SizedBox(height: dvph * 0.02),
          Text(
            'No lectures found',
            style: GoogleFonts.lato(fontSize: dvpw * 0.05, fontWeight: FontWeight.w700, color: AppColors.gray),
          ),
          SizedBox(height: dvph * 0.01),
          Text(
            'Try different keywords or filters',
            style: GoogleFonts.lato(fontSize: dvpw * 0.035, color: AppColors.gray),
          ),
        ],
      ),
    );
  }
}

