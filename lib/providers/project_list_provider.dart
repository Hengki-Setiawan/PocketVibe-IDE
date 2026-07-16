import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/project.dart';

class ProjectListNotifier extends StateNotifier<List<Project>> {
  ProjectListNotifier() : super([]) {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getStringList('recent_projects') ?? [];
      state = data.map((e) {
        try {
          return Project.fromJson(jsonDecode(e) as Map<String, dynamic>);
        } catch (e) {
          debugPrint('ProjectListNotifier._load fromJson error: $e');
          return null;
        }
      }).whereType<Project>().toList();
    } catch (e) {
      debugPrint('ProjectListNotifier._load prefs error: $e');
    }
  }

  Future<void> addProject(Project project) async {
    final existing = state.indexWhere((p) => p.uri == project.uri);
    if (existing != -1) {
      state = [
        Project(id: project.id, name: project.name, uri: project.uri, language: project.language, lastOpened: DateTime.now()),
        ...state.where((p) => p.uri != project.uri),
      ];
    } else {
      state = [project, ...state].take(20).toList();
    }
    await _save();
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = state.map((e) => jsonEncode(e.toJson())).toList();
      await prefs.setStringList('recent_projects', data);
    } catch (e) {
      debugPrint('ProjectListNotifier._save failed: $e');
    }
  }

  Future<void> removeProject(String uri) async {
    state = state.where((p) => p.uri != uri).toList();
    await _save();
  }
}

final projectListProvider = StateNotifierProvider<ProjectListNotifier, List<Project>>((_) => ProjectListNotifier());
