import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

class _CliEntry {
  final String name;
  final String label;
  final bool active;
  final IconData icon;

  const _CliEntry({required this.name, required this.label, required this.active, required this.icon});
}

const _clis = [
  _CliEntry(name: 'opencode', label: 'OpenCode', active: true, icon: Icons.code_rounded),
  _CliEntry(name: 'aider', label: 'Aider', active: false, icon: Icons.auto_awesome_rounded),
  _CliEntry(name: 'claude', label: 'Claude Code', active: false, icon: Icons.psychology_rounded),
  _CliEntry(name: 'gemini', label: 'Gemini CLI', active: false, icon: Icons.auto_awesome_mosaic_rounded),
];

class IconGrid extends StatelessWidget {
  const IconGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: _clis.length,
      itemBuilder: (_, i) => _CliCard(entry: _clis[i]),
    );
  }
}

class _CliCard extends StatelessWidget {
  final _CliEntry entry;
  const _CliCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: entry.active ? AppColors.card : AppColors.card.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: entry.active ? AppColors.primary.withValues(alpha: 0.2) : AppColors.border,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: entry.active
              ? null
              : () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${entry.label} akan tersedia segera'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  entry.icon,
                  size: 32,
                  color: entry.active ? AppColors.primary : AppColors.textMuted,
                ),
                const SizedBox(height: 6),
                Text(entry.name, style: AppTextStyles.caption.copyWith(
                  color: entry.active ? AppColors.textPrimary : AppColors.textMuted,
                )),
                if (!entry.active)
                  Text('Segera', style: AppTextStyles.caption.copyWith(
                    fontSize: 9, color: AppColors.textMuted,
                  )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
