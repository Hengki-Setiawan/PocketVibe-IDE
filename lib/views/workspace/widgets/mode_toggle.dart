import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../workspace_screen.dart';

class ModeToggle extends StatelessWidget {
  final InteractionMode current;
  final ValueChanged<InteractionMode> onChanged;

  const ModeToggle({super.key, required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          _TabButton(
            icon: Icons.chat_rounded,
            label: 'Chat',
            selected: current == InteractionMode.chat,
            onTap: () => onChanged(InteractionMode.chat),
          ),
          const SizedBox(width: 4),
          _TabButton(
            icon: Icons.terminal_rounded,
            label: 'Terminal',
            selected: current == InteractionMode.terminal,
            onTap: () => onChanged(InteractionMode.terminal),
          ),
          const SizedBox(width: 4),
          _TabButton(
            icon: Icons.folder_rounded,
            label: 'Files',
            selected: current == InteractionMode.files,
            onTap: () => onChanged(InteractionMode.files),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary.withValues(alpha: 0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: selected ? AppColors.primary : AppColors.textMuted),
              const SizedBox(width: 6),
              Text(label, style: AppTextStyles.caption.copyWith(
                color: selected ? AppColors.primary : AppColors.textMuted,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              )),
            ],
          ),
        ),
      ),
    );
  }
}
