import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../providers/cli_provider.dart';
import '../../../providers/workspace_provider.dart';
import '../../../models/chat_message.dart';

class ChatPanel extends ConsumerStatefulWidget {
  const ChatPanel({super.key});

  @override
  ConsumerState<ChatPanel> createState() => _ChatPanelState();
}

class _ChatPanelState extends ConsumerState<ChatPanel> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _initialSessionSet = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final sessionId = ref.read(workspaceProvider).sessionId;
      if (sessionId != null) {
        _initialSessionSet = true;
        ref.read(chatMessagesProvider.notifier).setSession(sessionId);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatMessagesProvider);
    final isStreaming = messages.isNotEmpty && messages.last.isStreaming;

    ref.listen(workspaceProvider, (WorkspaceState? prev, WorkspaceState next) {
      if (prev != null && prev.sessionId != null && next.sessionId == null) {
        _initialSessionSet = false;
      }
      if (!_initialSessionSet && next.sessionId != null) {
        _initialSessionSet = true;
        ref.read(chatMessagesProvider.notifier).setSession(next.sessionId!);
      }
    });

    ref.listen<List<ChatMessage>>(chatMessagesProvider, (_, next) {
      if (next.isNotEmpty) {
        _scrollToBottom();
      }
    });

    return Column(
      children: [
        Expanded(
          child: messages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.chat_bubble_outline_rounded, size: 40, color: AppColors.textMuted),
                      const SizedBox(height: 8),
                      Text('Mulai chat dengan AI', style: AppTextStyles.subtitle),
                      const SizedBox(height: 4),
                      Text('Tulis kode, tanya, atau minta bantuan', style: AppTextStyles.bodySmall),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(12),
                  itemCount: messages.length,
                  itemBuilder: (_, i) => _MessageBubble(key: ValueKey(messages[i].id), message: messages[i]),
                ),
        ),
        if (isStreaming)
          Container(
            color: AppColors.warning.withValues(alpha: 0.1),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                const SizedBox(
                  width: 12, height: 12,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.warning),
                ),
                const SizedBox(width: 8),
                Text('AI sedang menulis...', style: AppTextStyles.caption),
              ],
            ),
          ),
        Container(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
          decoration: const BoxDecoration(
            color: AppColors.background,
            border: Border(top: BorderSide(color: AppColors.divider)),
          ),
          child: Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              _ActionChip(
                icon: Icons.refresh_rounded,
                label: 'Baru',
                onTap: () => ref.read(chatMessagesProvider.notifier).sendMessage('/clear'),
              ),
              _ActionChip(
                icon: Icons.help_outline_rounded,
                label: 'Bantuan',
                onTap: () => ref.read(chatMessagesProvider.notifier).sendMessage('/help'),
              ),
              _ActionChip(
                icon: Icons.info_outline_rounded,
                label: 'Sesi',
                onTap: () => ref.read(chatMessagesProvider.notifier).sendMessage('/session'),
              ),
              _ActionChip(
                icon: Icons.undo_rounded,
                label: 'Undo',
                onTap: () => ref.read(chatMessagesProvider.notifier).sendMessage('/undo'),
              ),
              _ActionChip(
                icon: Icons.compress_rounded,
                label: 'Ringkas',
                onTap: () => ref.read(chatMessagesProvider.notifier).sendMessage('/compact'),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
          decoration: const BoxDecoration(
            color: AppColors.background,
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: AppTextStyles.body,
                    decoration: const InputDecoration(
                      hintText: 'Ketik pesan atau /command...',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    onSubmitted: _sendMessage,
                    textInputAction: TextInputAction.send,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: isStreaming ? null : () => _sendMessage(_controller.text),
                  icon: const Icon(Icons.send_rounded, size: 20),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;
    ref.read(chatMessagesProvider.notifier).sendMessage(text);
    _controller.clear();
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  const _MessageBubble({super.key, required this.message});

  Widget _buildMessageContent(String text) {
    if (text.contains('```')) {
      final parts = <Widget>[];
      final regex = RegExp(r'```(\w*)\n([\s\S]*?)```');
      var lastEnd = 0;
      for (final match in regex.allMatches(text)) {
        if (match.start > lastEnd) {
          parts.add(_buildRichText(text.substring(lastEnd, match.start)));
        }
        final lang = match.group(1) ?? '';
        final code = match.group(2) ?? '';
        parts.add(_CodeBlock(language: lang, code: code));
        lastEnd = match.end;
      }
      if (lastEnd < text.length) {
        parts.add(_buildRichText(text.substring(lastEnd)));
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: parts,
      );
    }
    return _buildRichText(text);
  }

  Widget _buildRichText(String text) {
    final spans = <TextSpan>[];
    final boldRegex = RegExp(r'\*\*(.*?)\*\*');
    final codeRegex = RegExp(r'`([^`]+)`');
    var lastEnd = 0;

    final combined = <_TextSegment>[];
    for (final m in boldRegex.allMatches(text)) {
      combined.add(_TextSegment(m.start, m.end, 'bold', m.group(1)!));
    }
    for (final m in codeRegex.allMatches(text)) {
      combined.add(_TextSegment(m.start, m.end, 'code', m.group(1)!));
    }
    combined.sort((a, b) => a.start.compareTo(b.start));

    for (final seg in combined) {
      if (seg.start > lastEnd) {
        spans.add(TextSpan(text: text.substring(lastEnd, seg.start)));
      }
      if (seg.type == 'bold') {
        spans.add(TextSpan(
          text: seg.content,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ));
      } else if (seg.type == 'code') {
        spans.add(TextSpan(
          text: seg.content,
          style: const TextStyle(
            fontFamily: 'monospace',
            backgroundColor: AppColors.surfaceLight,
            color: AppColors.accent,
          ),
        ));
      }
      lastEnd = seg.end;
    }
    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd)));
    }

    return SelectableText.rich(
      TextSpan(children: spans, style: AppTextStyles.body),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == MessageRole.user;
    final isSystem = message.role == MessageRole.system;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: isSystem ? AppColors.warning.withValues(alpha: 0.2) : AppColors.accent.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isSystem ? Icons.info_rounded : Icons.auto_awesome_rounded,
                size: 16,
                color: isSystem ? AppColors.warning : AppColors.accent,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? AppColors.primary.withValues(alpha: 0.15)
                     : isSystem ? AppColors.warning.withValues(alpha: 0.1)
                     : AppColors.surfaceLight,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(14),
                  topRight: const Radius.circular(14),
                  bottomLeft: Radius.circular(isUser ? 14 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 14),
                ),
              ),
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMessageContent(message.text),
                  const SizedBox(height: 4),
                  Text(message.formattedTime, style: AppTextStyles.caption),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.person_rounded, size: 16, color: AppColors.primary),
            ),
          ],
        ],
      ),
    );
  }
}

class _TextSegment {
  final int start;
  final int end;
  final String type;
  final String content;
  _TextSegment(this.start, this.end, this.type, this.content);
}

class _CodeBlock extends StatelessWidget {
  final String language;
  final String code;
  const _CodeBlock({required this.language, required this.code});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (language.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(language, style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
            ),
          SelectableText(
            code,
            style: AppTextStyles.code.copyWith(fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionChip({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceLight,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
            ],
          ),
        ),
      ),
    );
  }
}
