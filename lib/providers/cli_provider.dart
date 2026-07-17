import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/provider_manager.dart';
import '../models/chat_message.dart';

class ChatController extends StateNotifier<List<ChatMessage>> {
  final OpenCodeApiClient api;
  String? _sessionId;
  bool _sending = false;
  StreamSubscription<String>? _subscription;
  Completer<void>? _pendingCompleter;
  bool _cancelled = false;
  static const int _maxMessages = 200;

  ChatController(this.api) : super([]);

  void setSession(String sessionId) {
    _sessionId = sessionId;
    addSystemMessage('Sesi dimulai. Silakan kirim pesan.');
  }

  String? get sessionId => _sessionId;

  void cancelStream() {
    _cancelled = true;
    _subscription?.cancel();
    _subscription = null;
    if (_pendingCompleter != null && !_pendingCompleter!.isCompleted) {
      _pendingCompleter!.complete();
    }
  }

  Future<void> sendMessage(String text) async {
    if (_sending) return;
    if (_sessionId == null) {
      state = [...state, ChatMessage.system('Sesi belum siap. Harap buka project terlebih dahulu.')];
      return;
    }

    _sending = true;
    _cancelled = false;
    state = [..._appendMessage(ChatMessage.user(text.trim()))];
    final aiMsg = ChatMessage.ai('', streaming: true);
    state = [...state, aiMsg];

    final completer = Completer<void>();
    _pendingCompleter = completer;
    try {
      final stream = api.sendMessage(sessionId: _sessionId!, prompt: text.trim());
      _subscription = stream.listen(
        (chunk) {
          if (!mounted || state.isEmpty || _cancelled) return;
          final updated = state.last.copyWith(text: state.last.text + chunk);
          state = [...state.sublist(0, state.length - 1), updated];
        },
        onDone: () {
          if (mounted && state.isNotEmpty && !_cancelled) {
            final finalMsg = state.last.copyWith(isStreaming: false);
            state = [...state.sublist(0, state.length - 1), finalMsg];
          }
          if (!completer.isCompleted) completer.complete();
        },
        onError: (e) {
          if (mounted) {
            final errorMsg = ChatMessage.system('Error: $e');
            state = [...state.sublist(0, state.length - 1), errorMsg];
          }
          if (!completer.isCompleted) completer.complete();
        },
        cancelOnError: false,
      );
      await completer.future;
    } finally {
      _pendingCompleter = null;
      _subscription = null;
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
    _cancelled = false;
    _subscription?.cancel();
    _subscription = null;
    state = [];
  }
}

final chatMessagesProvider = StateNotifierProvider<ChatController, List<ChatMessage>>((ref) {
  return ChatController(ref.watch(openCodeApiClientProvider));
});
