class OpenCodeSession {
  final String id;
  final String projectPath;
  final DateTime createdAt;
  final DateTime lastActiveAt;

  const OpenCodeSession({
    required this.id,
    required this.projectPath,
    required this.createdAt,
    required this.lastActiveAt,
  });

  factory OpenCodeSession.fromJson(Map<String, dynamic> json) {
    return OpenCodeSession(
      id: (json['id'] as String?) ?? '',
      projectPath: (json['path'] as String?) ?? (json['projectPath'] as String?) ?? '',
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : DateTime.now(),
      lastActiveAt: json['lastActiveAt'] != null ? DateTime.parse(json['lastActiveAt'] as String) : DateTime.now(),
    );
  }
}
