import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../models/setup_step.dart';

class SetupStepTile extends StatelessWidget {
  final SetupStep step;
  final bool isActive;
  final bool isCompleted;
  final bool isFailed;

  const SetupStepTile({
    super.key,
    required this.step,
    this.isActive = false,
    this.isCompleted = false,
    this.isFailed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _icon,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(step.label, style: AppTextStyles.title.copyWith(color: _textColor)),
                if (isActive)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('Sedang berjalan...', style: AppTextStyles.caption),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget get _icon {
    if (isCompleted) {
      return const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 24);
    }
    if (isFailed) {
      return const Icon(Icons.error_rounded, color: AppColors.error, size: 24);
    }
    if (isActive) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.primary),
      );
    }
    return const Icon(Icons.circle_outlined, color: AppColors.textMuted, size: 24);
  }

  Color get _bgColor {
    if (isCompleted) return AppColors.success.withOpacity(0.08);
    if (isFailed) return AppColors.error.withOpacity(0.08);
    if (isActive) return AppColors.primary.withOpacity(0.08);
    return AppColors.card;
  }

  Color get _borderColor {
    if (isCompleted) return AppColors.success.withOpacity(0.3);
    if (isFailed) return AppColors.error.withOpacity(0.3);
    if (isActive) return AppColors.primary.withOpacity(0.3);
    return AppColors.border;
  }

  Color get _textColor {
    if (isCompleted) return AppColors.success;
    if (isFailed) return AppColors.error;
    if (isActive) return AppColors.primary;
    return AppColors.textMuted;
  }
}
