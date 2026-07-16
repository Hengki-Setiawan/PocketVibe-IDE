import 'package:intl/intl.dart';

enum MessageRole { user, ai, system }

class ChatMessage {
  final String id;
  final MessageRole role;
  final String text;
  final DateTime timestamp;
  final bool isStreaming;

  const ChatMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.timestamp,
    this.isStreaming = false,
  });

  ChatMessage copyWith({String? text, bool? isStreaming}) {
    return ChatMessage(
      id: id,
      role: role,
      text: text ?? this.text,
      timestamp: timestamp,
      isStreaming: isStreaming ?? this.isStreaming,
    );
  }

  String get formattedTime => DateFormat('HH:mm').format(timestamp);

  factory ChatMessage.user(String text, {String? id}) => ChatMessage(
    id: id ?? DateTime.now().millisecondsSinceEpoch.toString(),
    role: MessageRole.user,
    text: text,
    timestamp: DateTime.now(),
  );

  factory ChatMessage.ai(String text, {String? id, bool streaming = false}) => ChatMessage(
    id: id ?? DateTime.now().millisecondsSinceEpoch.toString(),
    role: MessageRole.ai,
    text: text,
    timestamp: DateTime.now(),
    isStreaming: streaming,
  );

  factory ChatMessage.system(String text, {String? id}) => ChatMessage(
    id: id ?? DateTime.now().millisecondsSinceEpoch.toString(),
    role: MessageRole.system,
    text: text,
    timestamp: DateTime.now(),
  );
}
