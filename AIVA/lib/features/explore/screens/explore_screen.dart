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

enum _ExploreFilter { all, continueLearning, newCourses }

class _ExploreScreenState extends State<ExploreScreen> {
  _ExploreFilter _selectedFilter = _ExploreFilter.all;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  String _searchQuery = '';
  List<Course> _courses = [];
  List<TodayLecture> _todayLectures = [];
  List<Map<String, dynamic>> _lectureCards = [];
  bool _isLoading = true;
  bool _isSearchFocused = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchFocus.addListener(() {
      setState(() => _isSearchFocused = _searchFocus.hasFocus);
    });
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

  List<Map<String, dynamic>> get _displayCards {
    List<Map<String, dynamic>> cards;
    if (_lectureCards.isNotEmpty) {
      cards = _lectureCards;
    } else {
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

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      cards = cards.where((c) =>
        (c['title']?.toString() ?? '').toLowerCase().contains(q) ||
        (c['course_title']?.toString() ?? '').toLowerCase().contains(q) ||
        (c['instructor']?.toString() ?? '').toLowerCase().contains(q)
      ).toList();
    }

    final todayIds = {for (final t in _todayLectures) t.lectureId};
    if (_selectedFilter == _ExploreFilter.continueLearning) {
      cards = cards.where((c) =>
        todayIds.contains(c['id']?.toString()) || c['is_enrolled'] == true
      ).toList();
    } else if (_selectedFilter == _ExploreFilter.newCourses) {
      cards = cards.where((c) => c['is_enrolled'] != true).toList();
    }

    return cards;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
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
      Navigator.of(context).pushNamed('/video', arguments: {
        'lecture_id': lectureId,
        'title': card['title']?.toString() ?? 'Lecture',
        'course_id': courseId,
      });
    } else {
      final course = _courses.firstWhere(
        (c) => c.id == courseId,
        orElse: () => Course(id: courseId, title: card['course_title']?.toString() ?? card['title']?.toString() ?? ''),
      );
      Navigator.push(context, MaterialPageRoute(builder: (_) => CourseDetailScreen(course: course)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.lightBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(w, h),
            _buildFilterChips(w, h),
            Expanded(
              child: _isLoading
                  ? _buildLoadingState(w)
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      color: AppColors.primaryLime,
                      backgroundColor: AppColors.primaryDark,
                      child: CustomScrollView(
                        slivers: [
                          if (_todayLectures.isNotEmpty && _searchQuery.isEmpty)
                            SliverToBoxAdapter(child: _buildContinueTodaySection(w, h)),
                          if (_displayCards.isEmpty)
                            SliverFillRemaining(child: _buildEmptyState(w, h))
                          else ...[
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: EdgeInsets.fromLTRB(w * 0.04, h * 0.018, w * 0.04, h * 0.01),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _selectedFilter == _ExploreFilter.continueLearning
                                          ? 'Enrolled'
                                          : _selectedFilter == _ExploreFilter.newCourses
                                              ? 'New Courses'
                                              : 'All Content',
                                      style: GoogleFonts.lato(
                                        fontSize: w * 0.042,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.primaryDark,
                                      ),
                                    ),
                                    Text(
                                      '${_displayCards.length} ${_displayCards.length == 1 ? 'item' : 'items'}',
                                      style: GoogleFonts.lato(fontSize: w * 0.032, color: AppColors.gray),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SliverPadding(
                              padding: EdgeInsets.fromLTRB(w * 0.04, 0, w * 0.04, h * 0.03),
                              sliver: SliverGrid(
                                delegate: SliverChildBuilderDelegate(
                                  (_, i) => GestureDetector(
                                    onTap: () => _onLectureTap(_displayCards[i]),
                                    child: _buildGridCard(_displayCards[i], w, h),
                                  ),
                                  childCount: _displayCards.length,
                                ),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: w * 0.03,
                                  mainAxisSpacing: w * 0.03,
                                  childAspectRatio: 0.78,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(double w) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const CircularProgressIndicator(color: AppColors.primaryDark, strokeWidth: 2),
        SizedBox(height: w * 0.04),
        Text('Loading courses...', style: GoogleFonts.lato(fontSize: w * 0.035, color: AppColors.gray)),
      ]),
    );
  }

  // ─── Header ───────────────────────────────────────────────────────────────

  Widget _buildHeader(double w, double h) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [BoxShadow(color: AppColors.grayLight.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(w * 0.04, h * 0.018, w * 0.04, h * 0.008),
            child: Row(
              children: [
                // Logo mark
                Container(
                  width: w * 0.09,
                  height: w * 0.09,
                  decoration: BoxDecoration(
                    color: AppColors.primaryDark,
                    borderRadius: BorderRadius.circular(w * 0.022),
                  ),
                  child: Center(
                    child: Text(
                      'A',
                      style: GoogleFonts.lato(
                        fontSize: w * 0.045,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primaryLime,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: w * 0.03),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Explore',
                        style: GoogleFonts.lato(
                          fontSize: w * 0.055,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primaryDark,
                          height: 1.1,
                        ),
                      ),
                      Text(
                        'Discover & learn something new',
                        style: GoogleFonts.lato(fontSize: w * 0.03, color: AppColors.gray),
                      ),
                    ],
                  ),
                ),
                // Notification button
                Container(
                  padding: EdgeInsets.all(w * 0.025),
                  decoration: BoxDecoration(
                    color: AppColors.lightBg,
                    borderRadius: BorderRadius.circular(w * 0.025),
                  ),
                  child: Icon(Icons.notifications_none_rounded, size: w * 0.055, color: AppColors.primaryDark),
                ),
              ],
            ),
          ),

          // Search bar
          Padding(
            padding: EdgeInsets.fromLTRB(w * 0.04, 0, w * 0.04, h * 0.015),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: w * 0.12,
              decoration: BoxDecoration(
                color: AppColors.lightBg,
                borderRadius: BorderRadius.circular(w * 0.06),
                border: Border.all(
                  color: _isSearchFocused ? AppColors.primaryDark : AppColors.grayLight,
                  width: _isSearchFocused ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Padding(
                    padding: EdgeInsets.only(left: w * 0.04),
                    child: Icon(Icons.search_rounded, size: w * 0.055, color: AppColors.gray),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocus,
                      onChanged: (v) => setState(() => _searchQuery = v),
                      textAlignVertical: TextAlignVertical.center,
                      style: GoogleFonts.lato(fontSize: w * 0.038, color: AppColors.primaryDark),
                      decoration: InputDecoration(
                        hintText: 'Search courses, topics...',
                        hintStyle: GoogleFonts.lato(fontSize: w * 0.038, color: AppColors.gray),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: w * 0.03),
                        isCollapsed: true,
                      ),
                    ),
                  ),
                  if (_searchQuery.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                        _searchFocus.unfocus();
                      },
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: w * 0.025),
                        child: Icon(Icons.close_rounded, size: w * 0.05, color: AppColors.gray),
                      ),
                    ),
                  // Mic button
                  ClipRRect(
                    borderRadius: BorderRadius.horizontal(right: Radius.circular(w * 0.058)),
                    child: Container(
                      height: w * 0.12,
                      width: w * 0.12,
                      color: AppColors.primaryDark,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {},
                          child: Icon(Icons.mic_rounded, size: w * 0.055, color: AppColors.primaryLime),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Filter Chips ─────────────────────────────────────────────────────────

  Widget _buildFilterChips(double w, double h) {
    final filters = [
      (_ExploreFilter.all, 'All', Icons.apps_rounded),
      (_ExploreFilter.continueLearning, 'My Learning', Icons.play_circle_outline_rounded),
      (_ExploreFilter.newCourses, 'Discover', Icons.explore_rounded),
    ];

    return Container(
      color: AppColors.white,
      padding: EdgeInsets.only(bottom: h * 0.012),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: w * 0.04),
        child: Row(
          children: filters.map((entry) {
            final filter = entry.$1;
            final label = entry.$2;
            final icon = entry.$3;
            final isSelected = _selectedFilter == filter;
            return Padding(
              padding: EdgeInsets.only(right: w * 0.025),
              child: GestureDetector(
                onTap: () => setState(() => _selectedFilter = filter),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: h * 0.009),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primaryDark : Colors.transparent,
                    borderRadius: BorderRadius.circular(w * 0.06),
                    border: Border.all(
                      color: isSelected ? AppColors.primaryDark : AppColors.grayLight,
                      width: 1.5,
                    ),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(
                      icon,
                      size: w * 0.038,
                      color: isSelected ? AppColors.primaryLime : AppColors.gray,
                    ),
                    SizedBox(width: w * 0.015),
                    Text(
                      label,
                      style: GoogleFonts.lato(
                        fontSize: w * 0.033,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? AppColors.white : AppColors.gray,
                      ),
                    ),
                  ]),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ─── Continue Today Section ───────────────────────────────────────────────

  Widget _buildContinueTodaySection(double w, double h) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(w * 0.04, h * 0.018, w * 0.04, h * 0.012),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(w * 0.012),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLime.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(w * 0.018),
                    ),
                    child: Icon(Icons.bolt_rounded, size: w * 0.04, color: AppColors.primaryDark),
                  ),
                  SizedBox(width: w * 0.025),
                  Text(
                    'Continue Today',
                    style: GoogleFonts.lato(fontSize: w * 0.042, fontWeight: FontWeight.w800, color: AppColors.primaryDark),
                  ),
                ],
              ),
              Text(
                '${_todayLectures.length} due',
                style: GoogleFonts.lato(fontSize: w * 0.03, color: AppColors.gray),
              ),
            ],
          ),
        ),
        SizedBox(
          height: w * 0.42,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.fromLTRB(w * 0.04, 0, w * 0.04, h * 0.01),
            itemCount: _todayLectures.length,
            itemBuilder: (_, i) => _buildTodayCard(_todayLectures[i], w, h),
          ),
        ),
        Divider(height: 1, color: AppColors.grayLight),
      ],
    );
  }

  Widget _buildTodayCard(TodayLecture lec, double w, double h) {
    final Color accentColor = lec.priority == 'high'
        ? AppColors.primaryLime
        : lec.priority == 'medium'
            ? AppColors.orange
            : AppColors.blue;

    final Color accentDark = lec.priority == 'high'
        ? AppColors.primaryDark
        : lec.priority == 'medium'
            ? const Color(0xFFC47300)
            : AppColors.blue;

    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed('/video', arguments: {
        'lecture_id': lec.lectureId,
        'title': lec.title,
        'course_id': lec.courseId,
      }),
      child: Container(
        width: w * 0.62,
        margin: EdgeInsets.only(right: w * 0.03),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(w * 0.04),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 12, offset: const Offset(0, 3))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail area
            Container(
              height: w * 0.24,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primaryDark, const Color(0xFF2D3A42)],
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(w * 0.04)),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Text(
                      lec.title.isNotEmpty ? lec.title[0].toUpperCase() : 'L',
                      style: GoogleFonts.lato(
                        fontSize: w * 0.18,
                        fontWeight: FontWeight.w900,
                        color: Colors.white.withOpacity(0.06),
                      ),
                    ),
                  ),
                  Center(
                    child: Container(
                      padding: EdgeInsets.all(w * 0.03),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.play_arrow_rounded, color: Colors.white, size: w * 0.07),
                    ),
                  ),
                  Positioned(
                    top: w * 0.025,
                    left: w * 0.025,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: w * 0.02, vertical: w * 0.008),
                      decoration: BoxDecoration(
                        color: accentColor,
                        borderRadius: BorderRadius.circular(w * 0.015),
                      ),
                      child: Text(
                        lec.priority.toUpperCase(),
                        style: GoogleFonts.lato(fontSize: w * 0.024, fontWeight: FontWeight.w800, color: accentDark),
                      ),
                    ),
                  ),
                  if (lec.isCompleted)
                    Positioned(
                      top: w * 0.025,
                      right: w * 0.025,
                      child: Container(
                        padding: EdgeInsets.all(w * 0.012),
                        decoration: const BoxDecoration(color: AppColors.green, shape: BoxShape.circle),
                        child: Icon(Icons.check_rounded, color: Colors.white, size: w * 0.03),
                      ),
                    ),
                ],
              ),
            ),
            // Info area
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(w * 0.03, w * 0.025, w * 0.03, w * 0.025),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lec.title,
                      style: GoogleFonts.lato(fontSize: w * 0.034, fontWeight: FontWeight.w700, color: AppColors.primaryDark, height: 1.3),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(children: [
                      Icon(Icons.schedule_rounded, size: w * 0.032, color: AppColors.gray),
                      SizedBox(width: w * 0.01),
                      Text(
                        '${lec.estimatedMinutes}min · ${lec.courseTitle}',
                        style: GoogleFonts.lato(fontSize: w * 0.027, color: AppColors.gray),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Grid Card ────────────────────────────────────────────────────────────

  Widget _buildGridCard(Map<String, dynamic> card, double w, double h) {
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

    final todayIds = {for (final t in _todayLectures) t.lectureId};
    final lectureId = card['id']?.toString() ?? '';
    final isToday = todayIds.contains(lectureId);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(w * 0.035),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail
          Container(
            height: w * 0.28,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color, color.withOpacity(0.6)],
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(w * 0.035)),
            ),
            child: Stack(
              children: [
                Center(
                  child: Text(
                    title.isNotEmpty ? title[0].toUpperCase() : 'L',
                    style: GoogleFonts.lato(
                      fontSize: w * 0.22,
                      fontWeight: FontWeight.w900,
                      color: Colors.white.withOpacity(0.07),
                    ),
                  ),
                ),
                Center(
                  child: Container(
                    padding: EdgeInsets.all(w * 0.025),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isEnrolled || isToday ? Icons.play_arrow_rounded : Icons.lock_outline_rounded,
                      color: Colors.white,
                      size: w * 0.055,
                    ),
                  ),
                ),
                if (durationStr != null)
                  Positioned(
                    bottom: w * 0.02,
                    right: w * 0.02,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: w * 0.018, vertical: w * 0.007),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.65),
                        borderRadius: BorderRadius.circular(w * 0.015),
                      ),
                      child: Text(durationStr, style: GoogleFonts.lato(fontSize: w * 0.024, fontWeight: FontWeight.w700, color: Colors.white)),
                    ),
                  ),
                if (isEnrolled)
                  Positioned(
                    top: w * 0.02,
                    left: w * 0.02,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: w * 0.018, vertical: w * 0.007),
                      decoration: BoxDecoration(
                        color: AppColors.green,
                        borderRadius: BorderRadius.circular(w * 0.015),
                      ),
                      child: Text('Enrolled', style: GoogleFonts.lato(fontSize: w * 0.023, fontWeight: FontWeight.w700, color: Colors.white)),
                    ),
                  ),
                if (!isEnrolled && isToday)
                  Positioned(
                    top: w * 0.02,
                    left: w * 0.02,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: w * 0.018, vertical: w * 0.007),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLime,
                        borderRadius: BorderRadius.circular(w * 0.015),
                      ),
                      child: Text('Due Today', style: GoogleFonts.lato(fontSize: w * 0.023, fontWeight: FontWeight.w700, color: AppColors.primaryDark)),
                    ),
                  ),
              ],
            ),
          ),

          // Info
          Expanded(
            child: Padding(
              padding: EdgeInsets.fromLTRB(w * 0.03, w * 0.025, w * 0.03, w * 0.025),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.lato(
                      fontSize: w * 0.034,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDark,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  if (courseTitle.isNotEmpty && courseTitle != title) ...[
                    Text(
                      courseTitle,
                      style: GoogleFonts.lato(fontSize: w * 0.027, color: AppColors.gray),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: w * 0.008),
                  ],
                  Text(
                    instructor,
                    style: GoogleFonts.lato(fontSize: w * 0.027, color: AppColors.gray, fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Empty State ──────────────────────────────────────────────────────────

  Widget _buildEmptyState(double w, double h) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          padding: EdgeInsets.all(w * 0.06),
          decoration: BoxDecoration(
            color: AppColors.lightBg,
            shape: BoxShape.circle,
          ),
          child: Icon(
            _searchQuery.isNotEmpty ? Icons.search_off_rounded : Icons.school_outlined,
            size: w * 0.14,
            color: AppColors.gray,
          ),
        ),
        SizedBox(height: h * 0.02),
        Text(
          _searchQuery.isNotEmpty ? 'No results for "$_searchQuery"' : 'No courses yet',
          style: GoogleFonts.lato(fontSize: w * 0.042, fontWeight: FontWeight.w700, color: AppColors.primaryDark),
        ),
        SizedBox(height: h * 0.008),
        Text(
          _searchQuery.isNotEmpty ? 'Try different keywords' : 'Content will appear here',
          style: GoogleFonts.lato(fontSize: w * 0.034, color: AppColors.gray),
        ),
      ]),
    );
  }
}
