import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifDoubts = true;
  bool _notifProgress = true;
  bool _notifUpdates = false;
  bool _isHindi = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: Get.back,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Language', style: AppTextStyles.headingSmall)
                .animate()
                .fadeIn(duration: 400.ms),
            const SizedBox(height: 12),
            _SectionCard(
              children: [
                _ToggleItem(
                  icon: Icons.translate_rounded,
                  color: AppColors.accentPrimary,
                  title: 'Hindi Responses',
                  subtitle: 'Get AIVA answers in Hindi',
                  value: _isHindi,
                  onChanged: (v) => setState(() => _isHindi = v),
                ),
              ],
            ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
            const SizedBox(height: 24),
            Text('Notifications', style: AppTextStyles.headingSmall)
                .animate()
                .fadeIn(delay: 150.ms, duration: 400.ms),
            const SizedBox(height: 12),
            _SectionCard(
              children: [
                _ToggleItem(
                  icon: Icons.help_outline_rounded,
                  color: AppColors.accentPrimary,
                  title: 'Doubt Answers',
                  subtitle: 'Notify when AIVA answers your doubt',
                  value: _notifDoubts,
                  onChanged: (v) => setState(() => _notifDoubts = v),
                ),
                const Divider(color: AppColors.borderColor, height: 1),
                _ToggleItem(
                  icon: Icons.bar_chart_rounded,
                  color: AppColors.success,
                  title: 'Progress Updates',
                  subtitle: 'Daily learning progress summary',
                  value: _notifProgress,
                  onChanged: (v) => setState(() => _notifProgress = v),
                ),
                const Divider(color: AppColors.borderColor, height: 1),
                _ToggleItem(
                  icon: Icons.campaign_rounded,
                  color: AppColors.warning,
                  title: 'New Lectures',
                  subtitle: 'When new lectures are uploaded',
                  value: _notifUpdates,
                  onChanged: (v) => setState(() => _notifUpdates = v),
                ),
              ],
            ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
            const SizedBox(height: 24),
            Text('Account', style: AppTextStyles.headingSmall)
                .animate()
                .fadeIn(delay: 250.ms, duration: 400.ms),
            const SizedBox(height: 12),
            _SectionCard(
              children: [
                _InfoItem(label: 'Name', value: 'Arjun Sharma'),
                const Divider(color: AppColors.borderColor, height: 1),
                _InfoItem(label: 'Phone', value: '+91 98765 43210'),
                const Divider(color: AppColors.borderColor, height: 1),
                _InfoItem(label: 'Institute', value: 'IIT Delhi'),
                const Divider(color: AppColors.borderColor, height: 1),
                _InfoItem(label: 'Plan', value: 'Pro · Active'),
              ],
            ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
            const SizedBox(height: 24),
            _SectionCard(
              children: [
                _InfoItem(label: 'App Version', value: '1.0.0 (Build 1)'),
                const Divider(color: AppColors.borderColor, height: 1),
                _InfoItem(label: 'Made by', value: 'Team TwinX'),
              ],
            ).animate().fadeIn(delay: 350.ms, duration: 400.ms),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final List<Widget> children;
  const _SectionCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor),
        boxShadow: [
          BoxShadow(
              color: AppColors.shadow, blurRadius: 8, offset: const Offset(0, 2))
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _ToggleItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                Text(title, style: AppTextStyles.labelLarge),
                Text(subtitle, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.accentPrimary,
          ),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;
  const _InfoItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodyMedium),
          Text(value,
              style: AppTextStyles.labelLarge.copyWith(fontSize: 13)),
        ],
      ),
    );
  }
}
