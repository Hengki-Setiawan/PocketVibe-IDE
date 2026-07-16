import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../providers/connection_status_provider.dart';
import '../../models/connection_status.dart';
import '../../providers/project_list_provider.dart';
import '../../models/project.dart';
import 'widgets/connection_badge.dart';
import 'widgets/icon_grid.dart';
import 'widgets/project_picker_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionStatus = ref.watch(connectionStatusProvider);
    final projects = ref.watch(projectListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.bolt_rounded, color: AppColors.primary, size: 24),
            const SizedBox(width: 8),
            Text('PocketVibe', style: AppTextStyles.title),
          ],
        ),
        actions: [
          ConnectionBadge(status: connectionStatus.valueOrNull ?? ConnectionStatus.disconnected),
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            onPressed: () => context.go('/settings'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ProjectPickerCard(),
            const SizedBox(height: 28),
            Text('AI Tools', style: AppTextStyles.headline),
            const SizedBox(height: 12),
            const IconGrid(),
            if (projects.isNotEmpty) ...[
              const SizedBox(height: 28),
              Text('Project Terbaru', style: AppTextStyles.headline),
              const SizedBox(height: 12),
              ...projects.map((p) => _RecentProjectTile(project: p)),
            ],
          ],
        ),
      ),
    );
  }
}

class _RecentProjectTile extends ConsumerWidget {
  final Project project;
  const _RecentProjectTile({required this.project});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        dense: true,
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              project.displayLanguage.substring(0, 2).toUpperCase(),
              style: AppTextStyles.codeSmall.copyWith(color: AppColors.primary),
            ),
          ),
        ),
        title: Text(project.name, style: AppTextStyles.title),
        subtitle: Text(project.uri, style: AppTextStyles.caption),
        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        onTap: () => context.go('/workspace/${project.id}'),
      ),
    );
  }
}
