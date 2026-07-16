import 'dart:async';
import 'package:flutter/material.dart';
import 'package:re_editor/re_editor.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../models/file_node.dart';

class CodeEditorWidget extends StatefulWidget {
  final FileNode file;
  final String content;
  final ValueChanged<String> onChanged;

  const CodeEditorWidget({
    super.key,
    required this.file,
    required this.content,
    required this.onChanged,
  });

  @override
  State<CodeEditorWidget> createState() => _CodeEditorWidgetState();
}

class _CodeEditorWidgetState extends State<CodeEditorWidget> {
  late CodeLineEditingController _controller;
  bool _internalChange = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _controller = CodeLineEditingController.fromText(widget.content);
    _controller.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(CodeEditorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.content != oldWidget.content && widget.file.path != oldWidget.file.path) {
      _internalChange = true;
      final offset = _controller.selection.baseOffset;
      _controller.removeListener(_onControllerChanged);
      _controller.text = widget.content;
      _controller.addListener(_onControllerChanged);
      if (offset <= widget.content.length) {
        _controller.selection = CodeLineSelection.collapsed(index: 0, offset: offset);
      }
      _internalChange = false;
    }
  }

  void _onControllerChanged() {
    if (_internalChange) return;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      widget.onChanged(_controller.text);
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: const BoxDecoration(
            color: AppColors.surfaceLight,
            border: Border(bottom: BorderSide(color: AppColors.divider)),
          ),
          child: Row(
            children: [
              Icon(_iconForFile(widget.file.name), size: 16, color: AppColors.textMuted),
              const SizedBox(width: 8),
              Expanded(child: Text(widget.file.name, style: AppTextStyles.codeSmall)),
              Text('${widget.file.size ?? 0} B', style: AppTextStyles.caption),
            ],
          ),
        ),
        Expanded(
          child: CodeEditor(
            controller: _controller,
            style: CodeEditorStyle(
              fontSize: 13,
              fontFamily: 'JetBrainsMono',
              textColor: AppColors.textPrimary,
              backgroundColor: AppColors.background,
              selectionColor: AppColors.primary.withOpacity(0.25),
              cursorColor: AppColors.primary,
            ),
            padding: const EdgeInsets.all(12),
          ),
        ),
      ],
    );
  }

  IconData _iconForFile(String name) {
    if (name.isEmpty || !name.contains('.')) return Icons.description_outlined;
    final ext = name.split('.').last.toLowerCase();
    switch (ext) {
      case 'dart': return Icons.flutter_dash;
      case 'kt': case 'java': return Icons.coffee_rounded;
      case 'py': return Icons.code_rounded;
      case 'js': case 'ts': case 'jsx': case 'tsx': return Icons.javascript_rounded;
      case 'html': return Icons.web_rounded;
      case 'css': return Icons.css_rounded;
      case 'json': case 'yaml': case 'yml': return Icons.article_rounded;
      case 'md': return Icons.article_rounded;
      case 'sh': return Icons.terminal_rounded;
      default: return Icons.description_outlined;
    }
  }
}
