enum FileChangeStatus { unchanged, added, modified, deleted }

class FileNode {
  final String name;
  final String path;
  final bool isDirectory;
  final int? size;
  final DateTime? lastModified;
  final FileChangeStatus status;
  final List<FileNode> children;

  const FileNode({
    required this.name,
    required this.path,
    this.isDirectory = false,
    this.size,
    this.lastModified,
    this.status = FileChangeStatus.unchanged,
    this.children = const [],
  });

  String get extension {
    if (isDirectory) return '';
    final dot = name.lastIndexOf('.');
    return dot == -1 ? '' : name.substring(dot);
  }

  bool get isExpandable => isDirectory && children.isNotEmpty;

  Uri get contentUri => Uri.parse(path);

  FileNode copyWith({FileChangeStatus? status, List<FileNode>? children}) {
    return FileNode(
      name: name,
      path: path,
      isDirectory: isDirectory,
      size: size,
      lastModified: lastModified,
      status: status ?? this.status,
      children: children ?? this.children,
    );
  }
}
