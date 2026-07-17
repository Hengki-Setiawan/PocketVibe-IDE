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
    final workspace = ref.watch(workspaceProvider);
    final isStreaming = messages.isNotEmpty && messages.last.isStreaming;

    if (!_initialSessionSet && workspace.sessionId != null) {
      _initialSessionSet = true;
      ref.read(chatMessagesProvider.notifier).setSession(workspace.sessionId!);
    }

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
                  itemBuilder: (_, i) => _MessageBubble(message: messages[i]),
                ),
        ),
        if (isStreaming)
          Container(
            color: AppColors.error.withValues(alpha: 0.1),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                const SizedBox(
                  width: 12, height: 12,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.error),
                ),
                const SizedBox(width: 8),
                Text('AI sedang menulis...', style: AppTextStyles.caption),
                const Spacer(),
                SizedBox(
                  height: 28,
                  child: TextButton.icon(
                    onPressed: () => ref.read(chatMessagesProvider.notifier).cancelStream(),
                    icon: const Icon(Icons.stop_rounded, size: 16),
                    label: const Text('Stop', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.error,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            color: AppColors.background,
            border: Border(top: BorderSide(color: AppColors.divider)),
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
                      hintText: 'Ketik pesan...',
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
  const _MessageBubble({required this.message});

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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(message.text, style: AppTextStyles.body),
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
