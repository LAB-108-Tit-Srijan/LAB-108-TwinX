import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../controllers/doubt_controller.dart';
import '../../widgets/common/doubt_card.dart';

class DoubtHistoryScreen extends StatelessWidget {
  const DoubtHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<DoubtController>();
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
                  Text('My Doubts', style: AppTextStyles.headingLarge)
                      .animate()
                      .fadeIn(duration: 400.ms),
                  const SizedBox(height: 16),
                  TextField(
                    onChanged: ctrl.setSearch,
                    decoration: InputDecoration(
                      hintText: 'Search doubts...',
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
                  const SizedBox(height: 12),
                  Obx(() => Row(
                        children: ['All', 'This Week', 'By Lecture']
                            .map((f) {
                          final selected = ctrl.selectedFilter.value == f;
                          return GestureDetector(
                            onTap: () => ctrl.setFilter(f),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(
                                color: selected
                                    ? AppColors.accentPrimary
                                    : AppColors.backgroundSecondary,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: selected
                                      ? AppColors.accentPrimary
                                      : AppColors.borderColor,
                                ),
                              ),
                              child: Text(f,
                                  style: AppTextStyles.labelMedium.copyWith(
                                    color: selected
                                        ? Colors.white
                                        : AppColors.textSecondary,
                                  )),
                            ),
                          );
                        }).toList(),
                      )).animate().fadeIn(delay: 200.ms, duration: 400.ms),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Obx(() {
                final grouped = ctrl.groupedDoubts;
                if (grouped.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.help_outline_rounded,
                            size: 64,
                            color: AppColors.textHint.withOpacity(0.4)),
                        const SizedBox(height: 16),
                        Text('No doubts yet',
                            style: AppTextStyles.headingSmall
                                .copyWith(color: AppColors.textSecondary)),
                        const SizedBox(height: 8),
                        Text('Ask your first doubt while watching a lecture',
                            style: AppTextStyles.bodyMedium,
                            textAlign: TextAlign.center),
                      ],
                    ),
                  );
                }
                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: grouped.entries.map((entry) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(bottom: 10, top: 4),
                          child: Row(
                            children: [
                              Container(
                                width: 4,
                                height: 16,
                                decoration: BoxDecoration(
                                  gradient: AppColors.primaryGradient,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(entry.key,
                                  style: AppTextStyles.headingSmall.copyWith(
                                      fontSize: 14)),
                            ],
                          ),
                        ),
                        ...entry.value
                            .map((d) => DoubtCard(doubt: d)
                                .animate()
                                .fadeIn(duration: 300.ms)),
                        const SizedBox(height: 8),
                      ],
                    );
                  }).toList(),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
