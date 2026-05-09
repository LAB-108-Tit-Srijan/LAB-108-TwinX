import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../controllers/explore_controller.dart';
import '../../data/mock/mock_data.dart';
import '../../widgets/common/lecture_card.dart';
import '../../widgets/common/shimmer_loader.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<ExploreController>();
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Explore Lectures', style: AppTextStyles.headingLarge)
                      .animate()
                      .fadeIn(duration: 400.ms),
                  const SizedBox(height: 16),
                  TextField(
                    onChanged: ctrl.search,
                    decoration: InputDecoration(
                      hintText: 'Search lectures...',
                      prefixIcon: const Icon(Icons.search_rounded,
                          color: AppColors.textHint, size: 20),
                      hintStyle: AppTextStyles.hint,
                      filled: true,
                      fillColor: AppColors.backgroundSecondary,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide:
                            const BorderSide(color: AppColors.borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                            color: AppColors.accentPrimary, width: 2),
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            SizedBox(
              height: 40,
              child: Obx(() => ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: MockData.filterTopics.length,
                    itemBuilder: (_, i) {
                      final topic = MockData.filterTopics[i];
                      final selected =
                          ctrl.selectedFilter.value == topic;
                      return GestureDetector(
                        onTap: () => ctrl.filterBy(topic),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.accentPrimary
                                : AppColors.backgroundCard,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: selected
                                  ? AppColors.accentPrimary
                                  : AppColors.borderColor,
                            ),
                          ),
                          child: Text(
                            topic,
                            style: AppTextStyles.labelMedium.copyWith(
                              color: selected
                                  ? Colors.white
                                  : AppColors.textSecondary,
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                      );
                    },
                  )).animate().fadeIn(delay: 200.ms, duration: 400.ms),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Obx(() {
                if (ctrl.isLoading.value) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const ShimmerLectureList(count: 4),
                  );
                }
                if (ctrl.filteredLectures.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off_rounded,
                            size: 64,
                            color: AppColors.textHint.withOpacity(0.5)),
                        const SizedBox(height: 16),
                        Text('No lectures found',
                            style: AppTextStyles.headingSmall
                                .copyWith(color: AppColors.textSecondary)),
                        const SizedBox(height: 8),
                        Text('Try a different search or filter',
                            style: AppTextStyles.bodyMedium),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: ctrl.filteredLectures.length,
                  itemBuilder: (_, i) => LectureCard(
                    lecture: ctrl.filteredLectures[i],
                    onTap: () => Get.toNamed('/video',
                        arguments: ctrl.filteredLectures[i]),
                  ).animate().fadeIn(
                        delay: Duration(milliseconds: i * 60),
                        duration: 300.ms,
                      ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
