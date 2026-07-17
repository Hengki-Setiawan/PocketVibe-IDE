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
    addSystemMessage('Sesi dimulai. Ketik /help untuk melihat perintah.');
  }

  String? get sessionId => _sessionId;

  Future<void> sendMessage(String text) async {
    if (_sending) return;
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    if (trimmed.startsWith('/')) {
      await _handleSlashCommand(trimmed);
      return;
    }

    if (_sessionId == null) {
      state = [...state, ChatMessage.system('Sesi belum siap. Harap buka project terlebih dahulu.')];
      return;
    }

    _sending = true;
    state = [..._appendMessage(ChatMessage.user(trimmed))];
    final aiMsg = ChatMessage.ai('', streaming: true);
    state = [...state, aiMsg];

    try {
      final reply = await api.sendMessage(sessionId: _sessionId!, prompt: trimmed);
      if (mounted && state.isNotEmpty) {
        final finalMsg = state.last.copyWith(text: reply, isStreaming: false);
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

  Future<void> _handleSlashCommand(String text) async {
    final parts = text.split(' ');
    final cmd = parts.first.toLowerCase();

    switch (cmd) {
      case '/help':
        _showHelp();
      case '/clear':
      case '/new':
        _startNewSession();
      case '/session':
        await _showSessionInfo();
      case '/sessions':
        await _listSessions();
      case '/undo':
        await _undoLast();
      case '/redo':
        await _redo();
      case '/compact':
      case '/summarize':
        await _compactSession();
      case '/abort':
        await _abortSession();
      case '/model':
        addSystemMessage('Gunakan Settings > Provider AI untuk mengganti model.');
      default:
        addSystemMessage('Perintah tidak dikenal: $cmd. Ketik /help untuk daftar perintah.');
    }
  }

  void _showHelp() {
    final msg = ChatMessage.system(
      '**Perintah yang tersedia:**\n'
      '- `/help` — Tampilkan bantuan ini\n'
      '- `/clear` atau `/new` — Mulai sesi baru\n'
      '- `/session` — Info sesi saat ini\n'
      '- `/sessions` — Daftar semua sesi\n'
      '- `/undo` — Batalkan pesan terakhir\n'
      '- `/redo` — Kembalikan pesan yang dibatalkan\n'
      '- `/compact` atau `/summarize` — Ringkas sesi\n'
      '- `/abort` — Hentikan respons AI yang sedang berjalan\n'
      '- `/model` — Ganti model AI (via Settings)',
    );
    state = _appendMessage(msg);
  }

  void _startNewSession() {
    _sessionId = null;
    _sending = false;
    state = _appendMessage(ChatMessage.system('Sesi dihapus. Buka project untuk memulai sesi baru.'));
  }

  Future<void> _showSessionInfo() async {
    if (_sessionId == null) {
      addSystemMessage('Tidak ada sesi aktif. Buka project untuk membuat sesi.');
      return;
    }

    final session = await api.getSession(_sessionId!);
    if (session != null) {
      final title = session['title'] ?? '-';
      final model = session['model'] is Map ? (session['model'] as Map)['id'] ?? '-' : '-';
      final agent = session['agent'] ?? '-';
      addSystemMessage(
        '**Sesi aktif:**\n'
        'ID: $_sessionId\n'
        'Judul: $title\n'
        'Model: $model\n'
        'Agent: $agent',
      );
    } else {
      addSystemMessage('Gagal mengambil info sesi.');
    }
  }

  Future<void> _listSessions() async {
    addSystemMessage('Mengambil daftar sesi...');
    final sessions = await api.listSessions();
    if (sessions.isEmpty) {
      addSystemMessage('Tidak ada sesi tersimpan.');
      return;
    }

    final buffer = StringBuffer('**Daftar Sesi:**\n');
    for (final s in sessions.take(10)) {
      final id = (s['id'] as String?) ?? '-';
      final title = (s['title'] as String?) ?? '-';
      final model = s['model'] is Map ? (s['model'] as Map)['id'] ?? '-' : '-';
      final isActive = id == _sessionId ? ' ← aktif' : '';
      buffer.writeln('- `$id` $title ($model)$isActive');
    }
    if (sessions.length > 10) {
      buffer.writeln('...dan ${sessions.length - 10} lainnya');
    }
    addSystemMessage(buffer.toString());
  }

  Future<void> _undoLast() async {
    if (_sessionId == null) {
      addSystemMessage('Tidak ada sesi aktif.');
      return;
    }
    final ok = await api.revertMessage(_sessionId!);
    addSystemMessage(ok ? 'Pesan terakhir dibatalkan.' : 'Gagal membatalkan pesan.');
  }

  Future<void> _redo() async {
    if (_sessionId == null) {
      addSystemMessage('Tidak ada sesi aktif.');
      return;
    }
    final ok = await api.unrevertSession(_sessionId!);
    addSystemMessage(ok ? 'Pesan dikembalikan.' : 'Gagal mengembalikan pesan.');
  }

  Future<void> _compactSession() async {
    if (_sessionId == null) {
      addSystemMessage('Tidak ada sesi aktif.');
      return;
    }
    addSystemMessage('Meringkas sesi...');
    final ok = await api.summarizeSession(_sessionId!);
    addSystemMessage(ok ? 'Sesi diringkas.' : 'Gagal meringkas sesi.');
  }

  Future<void> _abortSession() async {
    if (_sessionId == null) {
      addSystemMessage('Tidak ada sesi aktif.');
      return;
    }
    final ok = await api.abortSession(_sessionId!);
    addSystemMessage(ok ? 'Respons AI dihentikan.' : 'Tidak ada respons yang berjalan.');
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
