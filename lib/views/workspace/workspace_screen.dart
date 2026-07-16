import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../providers/workspace_provider.dart';
import 'widgets/chat_panel.dart';
import 'widgets/file_tree_panel.dart';
import 'widgets/code_editor_widget.dart';
import 'widgets/mode_toggle.dart';

enum InteractionMode { chat, terminal, files }

class WorkspaceScreen extends ConsumerStatefulWidget {
  final String projectId;
  const WorkspaceScreen({super.key, required this.projectId});

  @override
  ConsumerState<WorkspaceScreen> createState() => _WorkspaceScreenState();
}

class _WorkspaceScreenState extends ConsumerState<WorkspaceScreen> {
  InteractionMode _mode = InteractionMode.chat;

  @override
  Widget build(BuildContext context) {
    final workspace = ref.watch(workspaceProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/dashboard'),
        ),
        title: Text(workspace.projectName ?? 'Workspace', style: AppTextStyles.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(workspaceProvider.notifier).refreshFiles(),
            tooltip: 'Refresh files',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: workspace.isLoading
                ? const Center(child: CircularProgressIndicator())
                : workspace.selectedFile != null
                    ? CodeEditorWidget(
                        file: workspace.selectedFile!,
                        content: workspace.fileContent ?? '',
                        onChanged: (c) => ref.read(workspaceProvider.notifier).updateFileContent(c),
                      )
                    : _EmptyEditor(onPickFile: () => ref.read(workspaceProvider.notifier).refreshFiles()),
          ),
          Container(
            height: 1,
            color: AppColors.divider,
          ),
          Expanded(
            flex: 2,
            child: Column(
              children: [
                ModeToggle(
                  current: _mode,
                  onChanged: (m) => setState(() => _mode = m),
                ),
                Expanded(child: _buildInteractionPanel()),
              ],
            ),
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: AppColors.surface,
        child: FileTreePanel(
          files: workspace.files,
          selectedFile: workspace.selectedFile,
          onSelect: (f) async {
            await ref.read(workspaceProvider.notifier).selectFile(f);
            if (context.mounted) Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  Widget _buildInteractionPanel() {
    switch (_mode) {
      case InteractionMode.chat: return const ChatPanel();
      case InteractionMode.terminal: return const _TerminalPlaceholder();
      case InteractionMode.files: return FileTreePanel(
        files: ref.watch(workspaceProvider).files,
        selectedFile: ref.watch(workspaceProvider).selectedFile,
        onSelect: (f) async {
          await ref.read(workspaceProvider.notifier).selectFile(f);
        },
      );
    }
  }
}

class _EmptyEditor extends StatelessWidget {
  final VoidCallback onPickFile;
  const _EmptyEditor({required this.onPickFile});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.description_outlined, size: 48, color: AppColors.textMuted),
          const SizedBox(height: 12),
          Text('Pilih file dari drawer kiri', style: AppTextStyles.subtitle),
          const SizedBox(height: 8),
          TextButton(onPressed: onPickFile, child: const Text('Refresh')),
        ],
      ),
    );
  }
}

class _TerminalPlaceholder extends StatelessWidget {
  const _TerminalPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.terminal_rounded, size: 40, color: AppColors.textMuted),
            const SizedBox(height: 8),
            Text('Terminal (coming soon)', style: AppTextStyles.subtitle),
          ],
        ),
      ),
    );
  }
}
