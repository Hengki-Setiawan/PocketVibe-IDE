import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import '../../models/file_node.dart';
import '../constants/termux_config.dart';

class ProjectStorageService {
  String? _projectPath;

  Future<String?> pickOrCreateProjectFolder() async {
    try {
      final result = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Pilih folder project',
      );
      if (result != null) {
        _projectPath = result;
        debugPrint('ProjectStorageService project path: $result');
        return result;
      }
      return null;
    } catch (e) {
      debugPrint('ProjectStorageService picker error: $e');
      return await _fallbackPickFolder();
    }
  }

  String? get projectPath => _projectPath;

  Future<bool> hasStorageAccess() async {
    try {
      final path = _projectPath ?? '/storage/emulated/0';
      final dir = Directory(path);
      return await dir.exists();
    } catch (e) {
      debugPrint('ProjectStorageService.hasStorageAccess failed: $e');
      return false;
    }
  }

  Future<String?> _fallbackPickFolder() async {
    try {
      final projectsDir = Directory('/storage/emulated/0/${TermuxConfig.projectsDir}');
      if (!await projectsDir.exists()) {
        await projectsDir.create(recursive: true);
      }
      _projectPath = projectsDir.path;
      return _projectPath;
    } catch (e) {
      debugPrint('ProjectStorageService fallback error: $e');
      return null;
    }
  }

  Future<List<FileNode>> listProjectFiles(Uri projectUri) async {
    final nodes = <FileNode>[];
    try {
      final dir = Directory.fromUri(projectUri);
      if (!await dir.exists()) return [];
      await for (final entity in dir.list()) {
        try {
          final stat = await entity.stat();
          final node = FileNode(
            name: entity.uri.pathSegments.last,
            path: entity.path,
            isDirectory: entity is Directory,
            size: stat.size,
            lastModified: stat.modified,
          );
          if (entity is Directory) {
            final children = await listProjectFiles(entity.uri);
            nodes.add(node.copyWith(children: children));
          } else {
            nodes.add(node);
          }
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('ProjectStorageService.listProjectFiles error: $e');
    }
    nodes.sort((a, b) {
      if (a.isDirectory && !b.isDirectory) return -1;
      if (!a.isDirectory && b.isDirectory) return 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return nodes;
  }

  Future<String?> readFileContent(Uri fileUri) async {
    try {
      final file = File.fromUri(fileUri);
      return await file.readAsString(encoding: utf8);
    } catch (e) {
      debugPrint('ProjectStorageService.readFileContent error: $e');
      return null;
    }
  }

  Future<bool> writeFileContent(Uri fileUri, String content) async {
    try {
      final file = File.fromUri(fileUri);
      await file.writeAsString(content, encoding: utf8);
      return true;
    } catch (e) {
      debugPrint('ProjectStorageService.writeFileContent failed: $e');
      return false;
    }
  }

  Future<bool> createFile(Uri parentUri, String name) async {
    try {
      final fileUri = parentUri.resolve(name);
      final file = File.fromUri(fileUri);
      await file.create();
      return true;
    } catch (e) {
      debugPrint('ProjectStorageService.createFile failed: $e');
      return false;
    }
  }

  Future<bool> createDirectory(Uri parentUri, String name) async {
    try {
      final dirUri = parentUri.resolve(name);
      final subDir = Directory.fromUri(dirUri);
      await subDir.create();
      return true;
    } catch (e) {
      debugPrint('ProjectStorageService.createDirectory failed: $e');
      return false;
    }
  }

  Future<bool> deleteEntity(Uri entityUri) async {
    try {
      final entity = File.fromUri(entityUri);
      if (await entity.exists()) {
        await entity.delete();
        return true;
      }
      final dir = Directory.fromUri(entityUri);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('ProjectStorageService.deleteEntity failed: $e');
      return false;
    }
  }

}
