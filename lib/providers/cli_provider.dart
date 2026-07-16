import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/provider_manager.dart';
import '../models/chat_message.dart';

class ChatController extends StateNotifier<List<ChatMessage>> {
  final OpenCodeApiClient api;
  String? _sessionId;
  bool _sending = false;
  static const int _maxMessages = 200;

  ChatController(this.api) : super([]);

  void setSession(String sessionId) {
    _sessionId = sessionId;
    addSystemMessage('Sesi dimulai. Silakan kirim pesan.');
  }

  String? get sessionId => _sessionId;

  Future<void> sendMessage(String text) async {
    if (_sending) return;
    if (_sessionId == null) {
      state = [...state, ChatMessage.system('Sesi belum siap. Harap buka project terlebih dahulu.')];
      return;
    }

    _sending = true;
    state = [..._appendMessage(ChatMessage.user(text.trim()))];
    final aiMsg = ChatMessage.ai('', streaming: true);
    state = [...state, aiMsg];

    try {
      await for (final chunk in api.sendMessage(sessionId: _sessionId!, prompt: text.trim())) {
        if (!mounted || state.isEmpty) break;
        final updated = state.last.copyWith(text: state.last.text + chunk);
        state = [...state.sublist(0, state.length - 1), updated];
      }
      if (mounted && state.isNotEmpty) {
        final finalMsg = state.last.copyWith(isStreaming: false);
        state = [...state.sublist(0, state.length - 1), finalMsg];
      }
    } catch (e) {
      if (mounted) {
        final errorMsg = ChatMessage.system('Error: $e');
        state = [...state.sublist(0, state.length - 1), errorMsg];
      }
    } finally {
      _sending = false;
    }
  }

  List<ChatMessage> _appendMessage(ChatMessage msg) {
    final updated = [...state, msg];
    if (updated.length > _maxMessages) {
      return updated.sublist(updated.length - _maxMessages);
    }
    return updated;
  }

  void addSystemMessage(String text) {
    state = _appendMessage(ChatMessage.system(text));
  }

  void clear() {
    _sessionId = null;
    _sending = false;
    state = [];
  }
}

final chatMessagesProvider = StateNotifierProvider<ChatController, List<ChatMessage>>((ref) {
  return ChatController(ref.watch(openCodeApiClientProvider));
});
