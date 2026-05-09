import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/lecture_model.dart';

class LectureCard extends StatelessWidget {
  final LectureModel lecture;
  final VoidCallback onTap;
  final bool isCompact;

  const LectureCard({
    super.key,
    required this.lecture,
    required this.onTap,
    this.isCompact = false,
  });

  List<Color> get _gradientColors {
    switch (lecture.thumbnailGradient) {
      case 'cyan':
        return [const Color(0xFF00D4FF), const Color(0xFF0096C7)];
      case 'purple':
        return [const Color(0xFF8B5CF6), const Color(0xFF7C3AED)];
      case 'pink':
        return [const Color(0xFFEC4899), const Color(0xFFBE185D)];
      case 'orange':
        return [const Color(0xFFF59E0B), const Color(0xFFD97706)];
      default:
        return [AppColors.accentPrimary, const Color(0xFF8B5CF6)];
    }
  }

  Color get _levelColor {
    switch (lecture.level) {
      case 'Beginner':
        return AppColors.success;
      case 'Advanced':
        return AppColors.error;
      default:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    return isCompact ? _buildCompact() : _buildFull();
  }

  Widget _buildCompact() {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 220,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderColor),
          boxShadow: [
            BoxShadow(
                color: AppColors.shadow, blurRadius: 12, offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 110,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                        colors: _gradientColors,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight),
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: Center(
                    child: Icon(Icons.play_circle_filled,
                        color: Colors.white.withOpacity(0.9), size: 44),
                  ),
                ),
                if (lecture.isNew)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.accentSecondary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('NEW',
                          style: AppTextStyles.bodySmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 10)),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.accentPrimary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(lecture.courseName,
                        style: AppTextStyles.labelMedium.copyWith(
                            color: AppColors.accentPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 10)),
                  ),
                  const SizedBox(height: 6),
                  Text(lecture.title,
                      style: AppTextStyles.labelLarge,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text('· ${lecture.duration}',
                      style: AppTextStyles.bodySmall),
                  if (lecture.progress > 0 && lecture.progress < 1) ...[
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: lecture.progress,
                      backgroundColor: AppColors.borderColor,
                      valueColor: const AlwaysStoppedAnimation(
                          AppColors.accentPrimary),
                      borderRadius: BorderRadius.circular(4),
                      minHeight: 4,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${(lecture.progress * 100).toInt()}%',
                            style: AppTextStyles.bodySmall),
                        Text('Continue →',
                            style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.accentPrimary,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFull() {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderColor),
          boxShadow: [
            BoxShadow(
                color: AppColors.shadow, blurRadius: 8, offset: const Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                        colors: _gradientColors,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight),
                    borderRadius:
                        const BorderRadius.horizontal(left: Radius.circular(16)),
                  ),
                  child: Center(
                    child: Icon(Icons.play_circle_filled,
                        color: Colors.white.withOpacity(0.9), size: 36),
                  ),
                ),
                if (lecture.isNew)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.accentSecondary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('NEW',
                          style: AppTextStyles.bodySmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 9)),
                    ),
                  ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(lecture.title,
                        style: AppTextStyles.labelLarge,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 3),
                    Text('By ${lecture.instructorName}',
                        style: AppTextStyles.bodySmall),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _chip(lecture.duration, Icons.timer_outlined),
                        _levelChip(),
                        _chip('${lecture.views} views',
                            Icons.visibility_outlined),
                      ],
                    ),
                    if (lecture.progress > 0 && lecture.progress < 1) ...[
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: lecture.progress,
                        backgroundColor: AppColors.borderColor,
                        valueColor: const AlwaysStoppedAnimation(
                            AppColors.accentPrimary),
                        borderRadius: BorderRadius.circular(4),
                        minHeight: 3,
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

  Widget _chip(String text, IconData icon) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.backgroundSecondary,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 10, color: AppColors.textSecondary),
            const SizedBox(width: 3),
            Text(text,
                style: AppTextStyles.bodySmall.copyWith(fontSize: 10)),
          ],
        ),
      );

  Widget _levelChip() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: _levelColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(lecture.level,
            style: AppTextStyles.bodySmall.copyWith(
                color: _levelColor, fontWeight: FontWeight.w600, fontSize: 10)),
      );
}
