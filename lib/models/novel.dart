class Novel {
  final String id;
  String title;
  String content;
  final DateTime createdAt;
  DateTime updatedAt;

  Novel({
    required this.id,
    this.title = '',
    this.content = '',
    required this.createdAt,
    required this.updatedAt,
  });

  Novel copyWith({
    String? title,
    String? content,
    DateTime? updatedAt,
  }) {
    return Novel(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Novel.fromJson(Map<String, dynamic> json) {
    return Novel(
      id: json['id'],
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}
