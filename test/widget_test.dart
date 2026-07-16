import 'package:flutter_test/flutter_test.dart';
import 'package:pocketvibe_ide/models/chat_message.dart';
import 'package:pocketvibe_ide/models/file_node.dart';
import 'package:pocketvibe_ide/models/setup_step.dart';

void main() {
  group('ChatMessage', () {
    test('user message factory creates correct role', () {
      final msg = ChatMessage.user('Hello');
      expect(msg.role, MessageRole.user);
      expect(msg.text, 'Hello');
      expect(msg.isStreaming, false);
    });

    test('ai message factory creates correct role', () {
      final msg = ChatMessage.ai('Response');
      expect(msg.role, MessageRole.ai);
      expect(msg.text, 'Response');
    });

    test('system message factory creates correct role', () {
      final msg = ChatMessage.system('Error occurred');
      expect(msg.role, MessageRole.system);
    });

    test('copyWith updates text correctly', () {
      final msg = ChatMessage.ai('Hello');
      final updated = msg.copyWith(text: 'Hello World');
      expect(updated.text, 'Hello World');
    });
  });

  group('FileNode', () {
    test('extension returns correct file type', () {
      const node = FileNode(name: 'main.dart', path: '/main.dart');
      expect(node.extension, '.dart');
    });

    test('directory has no extension', () {
      const node = FileNode(name: 'src', path: '/src', isDirectory: true);
      expect(node.extension, '');
    });
  });

  group('SetupStep', () {
    test('isTerminal returns true for done', () {
      expect(SetupStep.done.isTerminal, true);
    });

    test('isTerminal returns true for failed', () {
      expect(SetupStep.failed.isTerminal, true);
    });

    test('isTerminal returns false for notStarted', () {
      expect(SetupStep.notStarted.isTerminal, false);
    });
  });
}
