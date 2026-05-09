import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../controllers/home_controller.dart';
import '../../data/mock/mock_data.dart';
import '../../widgets/common/lecture_card.dart';
import '../../widgets/common/doubt_card.dart';
import '../../widgets/common/stat_card.dart';
import '../explore/explore_screen.dart';
import '../doubts/doubt_history_screen.dart';
import '../progress/progress_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<HomeController>();
    return Obx(() => Scaffold(
          backgroundColor: AppColors.backgroundSecondary,
          body: IndexedStack(
            index: ctrl.currentNavIndex.value,
            children: const [
              _HomeTab(),
              ExploreScreen(),
              DoubtHistoryScreen(),
              ProgressScreen(),
              ProfileScreen(),
            ],
          ),
          bottomNavigationBar: _BottomNav(
            currentIndex: ctrl.currentNavIndex.value,
            onTap: ctrl.changeNavIndex,
          ),
        ));
  }
}

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const _BottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.home_rounded, Icons.home_outlined, 'Home'),
      (Icons.explore_rounded, Icons.explore_outlined, 'Explore'),
      (Icons.help_rounded, Icons.help_outline_rounded, 'Doubts'),
      (Icons.bar_chart_rounded, Icons.bar_chart_outlined, 'Progress'),
      (Icons.person_rounded, Icons.person_outline_rounded, 'Profile'),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.backgroundCard,
        border: Border(top: BorderSide(color: AppColors.borderColor)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(items.length, (i) {
              final selected = i == currentIndex;
              final (activeIcon, inactiveIcon, label) = items[i];
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.accentPrimary.withOpacity(0.12)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          selected ? activeIcon : inactiveIcon,
                          color: selected
                              ? AppColors.accentPrimary
                              : AppColors.textHint,
                          size: 22,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        label,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: selected
                              ? AppColors.accentPrimary
                              : AppColors.textHint,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w400,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<HomeController>();
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Obx(() => Text(
                                    '${ctrl.greeting.value} 👋',
                                    style: AppTextStyles.bodyMedium,
                                  )),
                              const SizedBox(height: 2),
                              Text(MockData.currentStudent.name,
                                  style: AppTextStyles.headingLarge),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed: () {},
                              icon: Stack(
                                children: [
                                  const Icon(Icons.notifications_outlined,
                                      color: AppColors.textPrimary, size: 26),
                                  Positioned(
                                    right: 0,
                                    top: 0,
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: AppColors.error,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                gradient: AppColors.primaryGradient,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  MockData.currentStudent.avatarInitials,
                                  style: AppTextStyles.labelLarge
                                      .copyWith(color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ).animate().fadeIn(duration: 400.ms),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundSecondary,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.borderColor),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.search_rounded,
                              color: AppColors.textHint, size: 20),
                          const SizedBox(width: 12),
                          Text(
                            'Search lectures, concepts, doubts...',
                            style: AppTextStyles.hint,
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
                    const SizedBox(height: 24),
                    Obx(() => Row(
                          children: [
                            Expanded(
                              child: StatCard(
                                value:
                                    '${ctrl.lecturesWatchedToday.value}',
                                label: 'Lectures\nToday',
                                icon: Icons.play_circle_outline_rounded,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: StatCard(
                                value: '${ctrl.doubtsSolvedToday.value}',
                                label: 'Doubts\nSolved',
                                icon: Icons.check_circle_outline_rounded,
                                color: AppColors.success,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: StatCard(
                                value: '${ctrl.streakDays.value}🔥',
                                label: 'Day\nStreak',
                                icon: Icons.local_fire_department_rounded,
                                color: AppColors.warning,
                              ),
                            ),
                          ],
                        )).animate().fadeIn(delay: 200.ms, duration: 400.ms),
                    const SizedBox(height: 28),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Continue Watching',
                            style: AppTextStyles.headingSmall),
                        TextButton(
                          onPressed: () =>
                              Get.find<HomeController>().changeNavIndex(1),
                          child: Text('See all',
                              style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.accentPrimary,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 220,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                  itemCount: MockData.lectures
                      .where((l) => l.progress > 0 && l.progress < 1)
                      .length,
                  itemBuilder: (_, i) {
                    final inProgress = MockData.lectures
                        .where((l) => l.progress > 0 && l.progress < 1)
                        .toList();
                    return LectureCard(
                      lecture: inProgress[i],
                      onTap: () =>
                          Get.toNamed('/video', arguments: inProgress[i]),
                      isCompact: true,
                    );
                  },
                ),
              ).animate().fadeIn(delay: 350.ms, duration: 400.ms),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Recent Doubts', style: AppTextStyles.headingSmall)
                        .animate()
                        .fadeIn(delay: 400.ms, duration: 400.ms),
                    const SizedBox(height: 12),
                    ...MockData.doubts
                        .where((d) => !d.isAi)
                        .take(3)
                        .map((d) => DoubtCard(doubt: d)
                            .animate()
                            .fadeIn(delay: 450.ms, duration: 400.ms)),
                    const SizedBox(height: 16),
                    Text('Topics You\'re Studying',
                            style: AppTextStyles.headingSmall)
                        .animate()
                        .fadeIn(delay: 500.ms, duration: 400.ms),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: MockData.studyingTopics
                          .map((t) => _TopicChip(topic: t))
                          .toList(),
                    ).animate().fadeIn(delay: 550.ms, duration: 400.ms),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopicChip extends StatelessWidget {
  final String topic;
  const _TopicChip({required this.topic});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.accentPrimary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.accentPrimary.withOpacity(0.2)),
      ),
      child: Text(
        topic,
        style: AppTextStyles.labelMedium.copyWith(color: AppColors.accentPrimary),
      ),
    );
  }
}
