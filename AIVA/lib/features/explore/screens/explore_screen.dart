import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../models/video_content.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  VideoCategory _selectedCategory = VideoCategory.all;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  List<VideoContent> get filteredVideos {
    List<VideoContent> videos = recommendedVideos;

    // Filter by category
    if (_selectedCategory != VideoCategory.all) {
      videos = videos
          .where((v) => v.categories.contains(_selectedCategory))
          .toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      videos = videos
          .where((v) =>
              v.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              v.channelName.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    // Sort by priority
    videos.sort((a, b) {
      final priorityOrder = {
        VideoPriority.high: 0,
        VideoPriority.medium: 1,
        VideoPriority.normal: 2,
      };
      return priorityOrder[a.priority]!.compareTo(priorityOrder[b.priority]!);
    });

    return videos;
  }

  @override
  void dispose() {
    _searchController.dispose();
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
            // Header with search
            _buildHeader(dvpw, dvph),

            // Category chips
            _buildCategoryChips(dvpw, dvph),

            // Video list
            Expanded(
              child: filteredVideos.isEmpty
                  ? _buildEmptyState(dvpw, dvph)
                  : ListView.builder(
                      padding: EdgeInsets.symmetric(
                        horizontal: dvpw * 0.04,
                        vertical: dvph * 0.01,
                      ),
                      itemCount: filteredVideos.length,
                      itemBuilder: (context, index) {
                        return _buildVideoCard(
                          filteredVideos[index],
                          dvpw,
                          dvph,
                        );
                      },
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

  Widget _buildCategoryChips(double dvpw, double dvph) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: dvph * 0.012),
      color: AppColors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: dvpw * 0.04),
        child: Row(
          children: VideoCategory.values.map((category) {
            final isSelected = _selectedCategory == category;
            return Padding(
              padding: EdgeInsets.only(right: dvpw * 0.025),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedCategory = category;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.symmetric(
                    horizontal: dvpw * 0.04,
                    vertical: dvph * 0.01,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primaryDark
                        : AppColors.white,
                    borderRadius: BorderRadius.circular(dvpw * 0.06),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primaryDark
                          : AppColors.grayLight,
                      width: 1.5,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.primaryDark.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        categoryEmojis[category] ?? '📌',
                        style: TextStyle(fontSize: dvpw * 0.04),
                      ),
                      SizedBox(width: dvpw * 0.015),
                      Text(
                        categoryNames[category] ?? '',
                        style: GoogleFonts.lato(
                          fontSize: dvpw * 0.035,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? AppColors.white
                              : AppColors.primaryDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildVideoCard(VideoContent video, double dvpw, double dvph) {
    return Container(
      margin: EdgeInsets.only(bottom: dvph * 0.02),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(dvpw * 0.04),
        boxShadow: [
          BoxShadow(
            color: AppColors.grayLight.withOpacity(0.5),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(dvpw * 0.04),
                ),
                child: CachedNetworkImage(
                  imageUrl: video.thumbnailUrl,
                  height: dvph * 0.22,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    height: dvph * 0.22,
                    color: AppColors.grayLight,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryLime,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: dvph * 0.22,
                    color: AppColors.grayLight,
                    child: Icon(
                      Icons.error_outline_rounded,
                      color: AppColors.gray,
                      size: dvpw * 0.1,
                    ),
                  ),
                ),
              ),

              // Duration badge
              Positioned(
                right: dvpw * 0.025,
                bottom: dvpw * 0.025,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: dvpw * 0.02,
                    vertical: dvpw * 0.01,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryDark.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(dvpw * 0.01),
                  ),
                  child: Text(
                    video.duration,
                    style: GoogleFonts.lato(
                      fontSize: dvpw * 0.03,
                      fontWeight: FontWeight.w600,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),

              // Live badge
              if (video.isLive)
                Positioned(
                  left: dvpw * 0.025,
                  top: dvpw * 0.025,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: dvpw * 0.025,
                      vertical: dvpw * 0.012,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.red,
                      borderRadius: BorderRadius.circular(dvpw * 0.01),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.circle,
                          size: dvpw * 0.02,
                          color: AppColors.white,
                        ),
                        SizedBox(width: dvpw * 0.01),
                        Text(
                          'LIVE',
                          style: GoogleFonts.lato(
                            fontSize: dvpw * 0.028,
                            fontWeight: FontWeight.w700,
                            color: AppColors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Priority badge
              Positioned(
                right: dvpw * 0.025,
                top: dvpw * 0.025,
                child: _buildPriorityBadge(video.priority, dvpw),
              ),
            ],
          ),

          // Video info
          Padding(
            padding: EdgeInsets.all(dvpw * 0.035),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Channel avatar
                CachedNetworkImage(
                  imageUrl: video.channelAvatar,
                  imageBuilder: (context, imageProvider) => Container(
                    width: dvpw * 0.1,
                    height: dvpw * 0.1,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(
                        image: imageProvider,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  placeholder: (context, url) => Container(
                    width: dvpw * 0.1,
                    height: dvpw * 0.1,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.grayLight,
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: dvpw * 0.1,
                    height: dvpw * 0.1,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primaryLime,
                    ),
                    child: Icon(
                      Icons.person_rounded,
                      size: dvpw * 0.06,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),

                SizedBox(width: dvpw * 0.03),

                // Title and info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        video.title,
                        style: GoogleFonts.lato(
                          fontSize: dvpw * 0.038,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryDark,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: dvpw * 0.015),
                      Text(
                        '${video.channelName} • ${video.views} • ${video.uploadedTime}',
                        style: GoogleFonts.lato(
                          fontSize: dvpw * 0.032,
                          color: AppColors.gray,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: dvpw * 0.02),

                      // Category tags
                      Wrap(
                        spacing: dvpw * 0.015,
                        runSpacing: dvpw * 0.015,
                        children: video.categories.map((category) {
                          return _buildCategoryTag(category, dvpw);
                        }).toList(),
                      ),
                    ],
                  ),
                ),

                // More options
                GestureDetector(
                  onTap: () {
                    _showVideoOptions(context, video);
                  },
                  child: Icon(
                    Icons.more_vert_rounded,
                    size: dvpw * 0.055,
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

  Widget _buildPriorityBadge(VideoPriority priority, double dvpw) {
    Color bgColor;
    Color textColor;
    String label;
    IconData icon;

    switch (priority) {
      case VideoPriority.high:
        bgColor = AppColors.red;
        textColor = AppColors.white;
        label = 'High Priority';
        icon = Icons.local_fire_department_rounded;
        break;
      case VideoPriority.medium:
        bgColor = AppColors.orange;
        textColor = AppColors.white;
        label = 'Medium';
        icon = Icons.star_rounded;
        break;
      case VideoPriority.normal:
        bgColor = AppColors.grayLight;
        textColor = AppColors.grayDark;
        label = 'Normal';
        icon = Icons.bookmark_outline_rounded;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dvpw * 0.025,
        vertical: dvpw * 0.012,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(dvpw * 0.015),
        boxShadow: [
          BoxShadow(
            color: bgColor.withOpacity(0.4),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: dvpw * 0.035,
            color: textColor,
          ),
          SizedBox(width: dvpw * 0.01),
          Text(
            label,
            style: GoogleFonts.lato(
              fontSize: dvpw * 0.028,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTag(VideoCategory category, double dvpw) {
    Color tagColor;
    switch (category) {
      case VideoCategory.coding:
        tagColor = AppColors.primaryLime;
        break;
      case VideoCategory.study:
        tagColor = AppColors.blue;
        break;
      case VideoCategory.entertainment:
        tagColor = AppColors.purple;
        break;
      case VideoCategory.science:
        tagColor = AppColors.teal;
        break;
      case VideoCategory.math:
        tagColor = AppColors.red;
        break;
      case VideoCategory.language:
        tagColor = AppColors.orange;
        break;
      case VideoCategory.motivation:
        tagColor = AppColors.green;
        break;
      case VideoCategory.technology:
        tagColor = AppColors.lightBlue;
        break;
      default:
        tagColor = AppColors.gray;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dvpw * 0.025,
        vertical: dvpw * 0.01,
      ),
      decoration: BoxDecoration(
        color: tagColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(dvpw * 0.02),
        border: Border.all(
          color: tagColor.withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Text(
        categoryNames[category] ?? '',
        style: GoogleFonts.lato(
          fontSize: dvpw * 0.028,
          fontWeight: FontWeight.w600,
          color: tagColor == AppColors.primaryLime
              ? AppColors.primaryDark
              : tagColor,
        ),
      ),
    );
  }

  Widget _buildEmptyState(double dvpw, double dvph) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: dvpw * 0.2,
            color: AppColors.grayLight,
          ),
          SizedBox(height: dvph * 0.02),
          Text(
            'No videos found',
            style: GoogleFonts.lato(
              fontSize: dvpw * 0.05,
              fontWeight: FontWeight.w700,
              color: AppColors.gray,
            ),
          ),
          SizedBox(height: dvph * 0.01),
          Text(
            'Try different keywords or categories',
            style: GoogleFonts.lato(
              fontSize: dvpw * 0.035,
              color: AppColors.gray,
            ),
          ),
        ],
      ),
    );
  }

  void _showVideoOptions(BuildContext context, VideoContent video) {
    final dvpw = MediaQuery.of(context).size.width;
    final dvph = MediaQuery.of(context).size.height;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(dvpw * 0.06),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(dvpw * 0.05),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: dvpw * 0.1,
                  height: dvph * 0.005,
                  decoration: BoxDecoration(
                    color: AppColors.grayLight,
                    borderRadius: BorderRadius.circular(dvpw * 0.01),
                  ),
                ),
                SizedBox(height: dvph * 0.02),

                // Video title
                Text(
                  video.title,
                  style: GoogleFonts.lato(
                    fontSize: dvpw * 0.04,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: dvph * 0.025),

                // Options
                _buildOptionItem(
                  Icons.watch_later_outlined,
                  'Watch Later',
                  dvpw,
                  dvph,
                ),
                _buildOptionItem(
                  Icons.playlist_add,
                  'Add to Playlist',
                  dvpw,
                  dvph,
                ),
                _buildOptionItem(
                  Icons.download_outlined,
                  'Download',
                  dvpw,
                  dvph,
                ),
                _buildOptionItem(
                  Icons.share_outlined,
                  'Share',
                  dvpw,
                  dvph,
                ),
                _buildOptionItem(
                  Icons.not_interested_outlined,
                  'Not Interested',
                  dvpw,
                  dvph,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOptionItem(
      IconData icon, String label, double dvpw, double dvph) {
    return InkWell(
      onTap: () => Navigator.pop(context),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: dvph * 0.015),
        child: Row(
          children: [
            Icon(
              icon,
              size: dvpw * 0.06,
              color: AppColors.primaryDark,
            ),
            SizedBox(width: dvpw * 0.04),
            Text(
              label,
              style: GoogleFonts.lato(
                fontSize: dvpw * 0.04,
                fontWeight: FontWeight.w500,
                color: AppColors.primaryDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

