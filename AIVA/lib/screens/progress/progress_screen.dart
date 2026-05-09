import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/mock/mock_data.dart';
import '../../widgets/common/stat_card.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text('Your Progress', style: AppTextStyles.headingLarge)
                  .animate()
                  .fadeIn(duration: 400.ms),
              const SizedBox(height: 24),
              _WeeklyChart()
                  .animate()
                  .fadeIn(delay: 100.ms, duration: 400.ms),
              const SizedBox(height: 24),
              Text('Overview', style: AppTextStyles.headingSmall)
                  .animate()
                  .fadeIn(delay: 200.ms, duration: 400.ms),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      value: '128',
                      label: 'Total\nDoubts',
                      icon: Icons.help_outline_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      value: '47',
                      label: 'Lectures\nCompleted',
                      icon: Icons.play_circle_outline_rounded,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 250.ms, duration: 400.ms),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      value: '14🔥',
                      label: 'Day\nStreak',
                      icon: Icons.local_fire_department_rounded,
                      color: AppColors.warning,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      value: '10 PM',
                      label: 'Most Active\nTime',
                      icon: Icons.access_time_rounded,
                      color: AppColors.accentSecondary,
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
              const SizedBox(height: 24),
              Text('Course Progress', style: AppTextStyles.headingSmall)
                  .animate()
                  .fadeIn(delay: 350.ms, duration: 400.ms),
              const SizedBox(height: 12),
              ...MockData.courses
                  .asMap()
                  .entries
                  .map((e) => _CourseProgressCard(course: e.value)
                      .animate()
                      .fadeIn(
                        delay: Duration(milliseconds: 400 + e.key * 80),
                        duration: 400.ms,
                      )),
              const SizedBox(height: 24),
              Text('Concepts Mastered', style: AppTextStyles.headingSmall)
                  .animate()
                  .fadeIn(delay: 550.ms, duration: 400.ms),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: MockData.masteredConcepts
                    .map((c) => _ConceptChip(concept: c))
                    .toList(),
              ).animate().fadeIn(delay: 600.ms, duration: 400.ms),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeeklyChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final data = MockData.weeklyActivity;
    final maxVal = data.map((d) => d['doubts'] as int).reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderColor),
        boxShadow: [
          BoxShadow(color: AppColors.shadow, blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Weekly Activity', style: AppTextStyles.headingSmall),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accentPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('Doubts Asked',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.accentPrimary, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: data.map((d) {
                final val = d['doubts'] as int;
                final ratio = val / maxVal;
                final isToday = d['day'] == 'Sat';
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text('$val',
                        style: AppTextStyles.bodySmall.copyWith(
                            color: isToday
                                ? AppColors.accentPrimary
                                : AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                            fontSize: 10)),
                    const SizedBox(height: 4),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 800),
                      width: 28,
                      height: 80 * ratio,
                      decoration: BoxDecoration(
                        gradient: isToday
                            ? AppColors.primaryGradient
                            : LinearGradient(
                                colors: [
                                  AppColors.borderColor,
                                  AppColors.borderColor,
                                ],
                              ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(d['day'] as String,
                        style: AppTextStyles.bodySmall.copyWith(
                            color: isToday
                                ? AppColors.accentPrimary
                                : AppColors.textSecondary,
                            fontSize: 10)),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _CourseProgressCard extends StatelessWidget {
  final course;
  const _CourseProgressCard({required this.course});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor),
        boxShadow: [
          BoxShadow(color: AppColors.shadow, blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(course.name, style: AppTextStyles.labelLarge),
                  Text(course.instructor, style: AppTextStyles.bodySmall),
                ],
              ),
              Text(
                '${course.completedLectures}/${course.totalLectures}',
                style: AppTextStyles.headingSmall
                    .copyWith(color: AppColors.accentPrimary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: course.progress,
            backgroundColor: AppColors.borderColor,
            valueColor:
                const AlwaysStoppedAnimation(AppColors.accentPrimary),
            borderRadius: BorderRadius.circular(6),
            minHeight: 8,
          ),
          const SizedBox(height: 6),
          Text('${(course.progress * 100).toInt()}% complete',
              style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }
}

class _ConceptChip extends StatelessWidget {
  final String concept;
  const _ConceptChip({required this.concept});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.success.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_rounded,
              color: AppColors.success, size: 12),
          const SizedBox(width: 4),
          Text(concept,
              style: AppTextStyles.labelMedium
                  .copyWith(color: AppColors.success)),
        ],
      ),
    );
  }
}
