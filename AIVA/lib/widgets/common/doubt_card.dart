import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/doubt_model.dart';
import '../../core/utils/extensions.dart';

class DoubtCard extends StatefulWidget {
  final DoubtModel doubt;
  const DoubtCard({super.key, required this.doubt});

  @override
  State<DoubtCard> createState() => _DoubtCardState();
}

class _DoubtCardState extends State<DoubtCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _expanded
                ? AppColors.accentPrimary.withOpacity(0.3)
                : AppColors.borderColor,
          ),
          boxShadow: [
            BoxShadow(
                color: AppColors.shadow, blurRadius: 8, offset: const Offset(0, 2))
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.accentPrimary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(Icons.help_outline_rounded,
                          color: AppColors.accentPrimary, size: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.doubt.question,
                          style: AppTextStyles.labelLarge,
                          maxLines: _expanded ? null : 2,
                          overflow:
                              _expanded ? null : TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.doubt.lectureName,
                          style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.accentPrimary, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(widget.doubt.askedAt.timeAgo,
                          style: AppTextStyles.bodySmall),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundSecondary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('📍 ${widget.doubt.timestamp}',
                            style:
                                AppTextStyles.bodySmall.copyWith(fontSize: 10)),
                      ),
                    ],
                  ),
                ],
              ),
              if (!_expanded) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.accentPrimary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('View Answer',
                        style: AppTextStyles.labelMedium.copyWith(
                            color: AppColors.accentPrimary)),
                  ),
                ),
              ],
              if (_expanded) ...[
                const SizedBox(height: 16),
                const Divider(color: AppColors.borderColor),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundSecondary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.doubt.answer,
                    style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textPrimary, height: 1.7),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
