import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/services/provider_manager.dart';
import '../../../models/project.dart';
import '../../../providers/project_list_provider.dart';
import '../../../providers/workspace_provider.dart';

class ProjectPickerCard extends ConsumerWidget {
  const ProjectPickerCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      color: AppColors.card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: AppColors.primary.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
          onTap: () async {
            final storage = ref.read(projectStorageServiceProvider);
            final result = await storage.pickOrCreateProjectFolder();
            if (result != null) {
              final segments = result.replaceAll('\\', '/').split('/').where((s) => s.isNotEmpty);
              final name = segments.isNotEmpty ? segments.last : 'Untitled';

              final project = Project(
                id: const Uuid().v4(),
                name: name,
                uri: result,
                lastOpened: DateTime.now(),
              );
              await ref.read(projectListProvider.notifier).addProject(project);
              await ref.read(workspaceProvider.notifier).openProject(Uri.file(result), name);
              if (context.mounted) {
                context.go('/workspace/${project.id}');
              }
            }
          },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
          child: Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.folder_open_rounded, color: AppColors.primary, size: 24),
              ),
              const SizedBox(height: 12),
              Text('Pilih atau Buat Project', style: AppTextStyles.title),
              const SizedBox(height: 4),
              Text('Folder akan disimpan di penyimpanan bersama', style: AppTextStyles.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
