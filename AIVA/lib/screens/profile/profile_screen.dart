import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/mock/mock_data.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final student = MockData.currentStudent;
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                ),
                child: Column(
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white.withOpacity(0.4), width: 3),
                      ),
                      child: Center(
                        child: Text(
                          student.avatarInitials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 28,
                          ),
                        ),
                      ),
                    ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),
                    const SizedBox(height: 16),
                    Text(student.name,
                        style: AppTextStyles.headingLarge
                            .copyWith(color: Colors.white))
                        .animate()
                        .fadeIn(delay: 100.ms, duration: 400.ms),
                    const SizedBox(height: 4),
                    Text(student.phone,
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: Colors.white.withOpacity(0.8)))
                        .animate()
                        .fadeIn(delay: 150.ms, duration: 400.ms),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.3)),
                      ),
                      child: Text(student.institute,
                          style: AppTextStyles.labelMedium
                              .copyWith(color: Colors.white))
                          .animate()
                          .fadeIn(delay: 200.ms, duration: 400.ms),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatBadge(
                            value: '${student.lecturesWatched}',
                            label: 'Lectures'),
                        Container(
                            width: 1, height: 32, color: Colors.white.withOpacity(0.3)),
                        _StatBadge(
                            value: '${student.doubtsAsked}',
                            label: 'Doubts'),
                        Container(
                            width: 1, height: 32, color: Colors.white.withOpacity(0.3)),
                        _StatBadge(
                            value: '${student.streakDays}🔥',
                            label: 'Streak'),
                      ],
                    ).animate().fadeIn(delay: 250.ms, duration: 400.ms),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Account', style: AppTextStyles.headingSmall)
                        .animate()
                        .fadeIn(delay: 300.ms, duration: 400.ms),
                    const SizedBox(height: 12),
                    _MenuItem(
                      icon: Icons.workspace_premium_rounded,
                      label: 'My Subscription',
                      subtitle: 'Pro Plan · Active',
                      color: AppColors.warning,
                      onTap: () {},
                    ),
                    _MenuItem(
                      icon: Icons.translate_rounded,
                      label: 'Language Preference',
                      subtitle: 'English + Hindi',
                      color: AppColors.accentPrimary,
                      onTap: () => Get.toNamed('/settings'),
                    ),
                    _MenuItem(
                      icon: Icons.notifications_outlined,
                      label: 'Notification Settings',
                      color: AppColors.accentSecondary,
                      onTap: () => Get.toNamed('/settings'),
                    ),
                    const SizedBox(height: 20),
                    Text('Support', style: AppTextStyles.headingSmall)
                        .animate()
                        .fadeIn(delay: 400.ms, duration: 400.ms),
                    const SizedBox(height: 12),
                    _MenuItem(
                      icon: Icons.help_outline_rounded,
                      label: 'Help & Support',
                      color: AppColors.success,
                      onTap: () {},
                    ),
                    _MenuItem(
                      icon: Icons.privacy_tip_outlined,
                      label: 'Privacy Policy',
                      color: AppColors.textSecondary,
                      onTap: () {},
                    ),
                    _MenuItem(
                      icon: Icons.description_outlined,
                      label: 'Terms of Service',
                      color: AppColors.textSecondary,
                      onTap: () {},
                    ),
                    const SizedBox(height: 12),
                    _MenuItem(
                      icon: Icons.logout_rounded,
                      label: 'Logout',
                      color: AppColors.error,
                      labelColor: AppColors.error,
                      onTap: () {
                        Get.dialog(
                          AlertDialog(
                            title: const Text('Logout'),
                            content: const Text('Are you sure you want to logout?'),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            actions: [
                              TextButton(
                                  onPressed: Get.back,
                                  child: const Text('Cancel')),
                              TextButton(
                                onPressed: () => Get.offAllNamed('/login'),
                                child: Text('Logout',
                                    style: TextStyle(color: AppColors.error)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Text('AIVA v1.0.0 · By Team TwinX',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.textHint)),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String value;
  final String label;
  const _StatBadge({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20)),
        const SizedBox(height: 2),
        Text(label,
            style: TextStyle(
                color: Colors.white.withOpacity(0.7), fontSize: 12)),
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final Color color;
  final Color? labelColor;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.color,
    this.labelColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderColor),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: AppTextStyles.labelLarge.copyWith(
                          color: labelColor ?? AppColors.textPrimary)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!, style: AppTextStyles.bodySmall),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: AppColors.textHint, size: 20),
          ],
        ),
      ),
    );
  }
}
