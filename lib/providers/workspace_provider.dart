import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/file_node.dart';
import '../core/services/provider_manager.dart';
import 'cli_provider.dart';

class WorkspaceState {
  final Uri? projectUri;
  final String? projectName;
  final List<FileNode> files;
  final FileNode? selectedFile;
  final String? fileContent;
  final String? sessionId;
  final bool isLoading;

  const WorkspaceState({
    this.projectUri,
    this.projectName,
    this.files = const [],
    this.selectedFile,
    this.fileContent,
    this.sessionId,
    this.isLoading = false,
  });

  WorkspaceState copyWith({
    Uri? projectUri,
    String? projectName,
    List<FileNode>? files,
    FileNode? selectedFile,
    String? fileContent,
    String? sessionId,
    bool? isLoading,
  }) {
    return WorkspaceState(
      projectUri: projectUri ?? this.projectUri,
      projectName: projectName ?? this.projectName,
      files: files ?? this.files,
      selectedFile: selectedFile ?? this.selectedFile,
      fileContent: fileContent ?? this.fileContent,
      sessionId: sessionId ?? this.sessionId,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class WorkspaceNotifier extends StateNotifier<WorkspaceState> {
  final ProjectStorageService _storage;
  final OpenCodeApiClient _api;
  final Ref _ref;
  bool _sessionCreated = false;

  WorkspaceNotifier(this._storage, this._api, this._ref) : super(const WorkspaceState());

  Future<void> openProject(Uri uri, String name) async {
    _sessionCreated = false;
    _ref.read(chatMessagesProvider.notifier).clear();
    state = state.copyWith(projectUri: uri, projectName: name, sessionId: null, isLoading: true);
    try {
      final path = uri.toFilePath();
      _api.setDirectory(path);

      final files = await _storage.listProjectFiles(uri);
      state = state.copyWith(files: files, isLoading: false);
      await _ensureSession();
    } catch (e) {
      debugPrint('WorkspaceNotifier.openProject failed: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> _ensureSession() async {
    if (_sessionCreated) return;
    _sessionCreated = true;
    try {
      final sessionId = await _api.createSession();
      if (sessionId != null) {
        state = state.copyWith(sessionId: sessionId);
      }
    } catch (e) {
      debugPrint('WorkspaceNotifier._ensureSession failed: $e');
    }
  }

  Future<void> refreshFiles() async {
    if (state.projectUri == null) return;
    state = state.copyWith(isLoading: true);
    try {
      final files = await _storage.listProjectFiles(state.projectUri!);
      state = state.copyWith(files: files, isLoading: false);
    } catch (e) {
      debugPrint('WorkspaceNotifier.refreshFiles failed: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> selectFile(FileNode file) async {
    if (file.isDirectory) return;
    state = state.copyWith(selectedFile: file, isLoading: true);
    try {
      final content = await _storage.readFileContent(file.contentUri);
      state = state.copyWith(fileContent: content, isLoading: false);
    } catch (e) {
      debugPrint('WorkspaceNotifier.selectFile failed: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> updateFileContent(String newContent) async {
    if (state.selectedFile == null) return;
    final success = await _storage.writeFileContent(
      state.selectedFile!.contentUri,
      newContent,
    );
    if (success) {
      state = state.copyWith(fileContent: newContent);
    }
  }

  void closeProject() {
    _sessionCreated = false;
    state = const WorkspaceState();
  }
}

final workspaceProvider = StateNotifierProvider<WorkspaceNotifier, WorkspaceState>((ref) {
  return WorkspaceNotifier(
    ref.watch(projectStorageServiceProvider),
    ref.watch(openCodeApiClientProvider),
    ref,
  );
});
