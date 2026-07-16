class Project {
  final String id;
  final String name;
  final String uri;
  final String? language;
  final DateTime lastOpened;

  const Project({
    required this.id,
    required this.name,
    required this.uri,
    this.language,
    required this.lastOpened,
  });

  String get displayLanguage => language ?? 'Unknown';

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: (json['id'] as String?) ?? '',
      name: (json['name'] as String?) ?? 'Unknown',
      uri: (json['uri'] as String?) ?? '',
      language: json['language'] as String?,
      lastOpened: json['lastOpened'] != null
          ? (DateTime.tryParse(json['lastOpened'] as String) ?? DateTime.now())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'uri': uri,
    'language': language,
    'lastOpened': lastOpened.toIso8601String(),
  };
}
