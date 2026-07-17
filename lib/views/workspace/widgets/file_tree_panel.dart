import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../models/file_node.dart';

class FileTreePanel extends StatelessWidget {
  final List<FileNode> files;
  final FileNode? selectedFile;
  final ValueChanged<FileNode> onSelect;

  const FileTreePanel({
    super.key,
    required this.files,
    this.selectedFile,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Text('File Explorer', style: AppTextStyles.title),
          ),
          const Divider(height: 0),
          Expanded(
            child: files.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text('Folder kosong', style: AppTextStyles.subtitle),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: files.length,
                    itemBuilder: (_, i) => _FileTile(
                      node: files[i],
                      isSelected: selectedFile?.path == files[i].path,
                      onTap: () => onSelect(files[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _FileTile extends StatelessWidget {
  final FileNode node;
  final bool isSelected;
  final VoidCallback onTap;

  const _FileTile({required this.node, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
      child: ListTile(
        dense: true,
        leading: Icon(
          node.isDirectory ? Icons.folder_rounded : _fileIcon,
          size: 20,
          color: node.isDirectory ? AppColors.warning : _fileColor,
        ),
        title: Text(node.name, style: AppTextStyles.bodySmall.copyWith(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
        )),
        trailing: node.status != FileChangeStatus.unchanged
            ? Container(
                width: 8, height: 8,
                decoration: BoxDecoration(
                  color: _statusColor,
                  shape: BoxShape.circle,
                ),
              )
            : null,
        onTap: onTap,
      ),
    );
  }

  IconData get _fileIcon {
    switch (node.extension) {
      case '.dart': return Icons.flutter_dash;
      case '.kt': case '.kts': return Icons.coffee_rounded;
      case '.py': return Icons.code_rounded;
      case '.md': return Icons.article_rounded;
      default: return Icons.description_outlined;
    }
  }

  Color get _fileColor {
    switch (node.extension) {
      case '.dart': return AppColors.info;
      case '.kt': case '.kts': return AppColors.accent;
      case '.py': return AppColors.warning;
      default: return AppColors.textMuted;
    }
  }

  Color get _statusColor {
    switch (node.status) {
      case FileChangeStatus.added: return AppColors.success;
      case FileChangeStatus.modified: return AppColors.warning;
      case FileChangeStatus.deleted: return AppColors.error;
      case FileChangeStatus.unchanged: return Colors.transparent;
    }
  }
}
