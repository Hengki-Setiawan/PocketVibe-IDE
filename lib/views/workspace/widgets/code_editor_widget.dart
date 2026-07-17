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
  late CodeFindController _findController;
  late FocusNode _focusNode;
  bool _internalChange = false;
  Timer? _debounceTimer;
  bool _showFind = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _controller = CodeLineEditingController.fromText(widget.content);
    _findController = CodeFindController(_controller);
    _controller.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(CodeEditorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.file.path != oldWidget.file.path || widget.content != oldWidget.content) {
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

  void _saveNow() {
    _debounceTimer?.cancel();
    widget.onChanged(_controller.text);
  }

  void _toggleFind() {
    setState(() => _showFind = !_showFind);
    if (_showFind) {
      _findController.findMode();
    } else {
      _findController.close();
      _focusNode.requestFocus();
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    _findController.dispose();
    _focusNode.dispose();
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
            focusNode: _focusNode,
            findController: _findController,
            findBuilder: _showFind ? _buildFindBar : null,
            style: CodeEditorStyle(
              fontSize: 13,
              fontFamily: 'JetBrainsMono',
              textColor: AppColors.textPrimary,
              backgroundColor: AppColors.background,
              selectionColor: AppColors.primary.withValues(alpha: 0.25),
              cursorColor: AppColors.primary,
            ),
            padding: const EdgeInsets.all(12),
          ),
        ),
        _buildMobileToolbar(),
      ],
    );
  }

  PreferredSizeWidget _buildFindBar(BuildContext context, CodeFindController controller, bool readOnly) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(44),
      child: Container(
        color: AppColors.surfaceLight,
        child: Row(
          children: [
            const SizedBox(width: 8),
            const Icon(Icons.search_rounded, size: 16, color: AppColors.textMuted),
            const SizedBox(width: 4),
            Expanded(
              child: TextField(
                controller: controller.findInputController,
                focusNode: controller.findInputFocusNode,
                style: AppTextStyles.body,
                decoration: const InputDecoration(
                  hintText: 'Cari...',
                  isDense: true,
                  border: InputBorder.none,
                ),
              ),
            ),
              IconButton(
              icon: const Icon(Icons.keyboard_arrow_up, size: 18),
              onPressed: () => controller.previousMatch(),
              color: AppColors.textSecondary,
              tooltip: 'Sebelumnya',
            ),
            IconButton(
              icon: const Icon(Icons.keyboard_arrow_down, size: 18),
              onPressed: () => controller.nextMatch(),
              color: AppColors.textSecondary,
              tooltip: 'Berikutnya',
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: _toggleFind,
              color: AppColors.textMuted,
              tooltip: 'Tutup',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileToolbar() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceLight,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _ToolbarButton(
              icon: Icons.undo_rounded,
              tooltip: 'Undo',
              onPressed: () => _controller.undo(),
            ),
            _ToolbarButton(
              icon: Icons.redo_rounded,
              tooltip: 'Redo',
              onPressed: () => _controller.redo(),
            ),
            _ToolbarButton(
              icon: Icons.search_rounded,
              tooltip: 'Cari',
              isActive: _showFind,
              onPressed: _toggleFind,
            ),
            _ToolbarButton(
              icon: Icons.save_rounded,
              tooltip: 'Simpan',
              onPressed: _saveNow,
            ),
            _ToolbarButton(
              icon: Icons.keyboard_hide_rounded,
              tooltip: 'Tutup keyboard',
              onPressed: () => _focusNode.unfocus(),
            ),
          ],
        ),
      ),
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

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool isActive;

  const _ToolbarButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: IconButton(
        icon: Icon(icon, size: 20),
        tooltip: tooltip,
        color: isActive ? AppColors.primary : AppColors.textSecondary,
        onPressed: onPressed,
        splashRadius: 20,
      ),
    );
  }
}