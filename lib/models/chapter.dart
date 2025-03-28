import 'package:uuid/uuid.dart';
import 'novel.dart';

class Chapter {
  final String id;
  String title;
  String content;
  int wordCount;
  final DateTime createdAt;
  DateTime updatedAt;

  Chapter({
    String? id,
    this.title = '',
    this.content = '',
    int? wordCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : this.id = id ?? const Uuid().v4(),
        this.wordCount = wordCount ?? _calculateWordCount(content),
        this.createdAt = createdAt ?? DateTime.now(),
        this.updatedAt = updatedAt ?? DateTime.now();

  // 文字数計算
  static int _calculateWordCount(String text) {
    return text.replaceAll(RegExp(r'\s+'), '').length;
  }

  // 文字数を更新
  void updateWordCount() {
    wordCount = _calculateWordCount(content);
  }

  // JSON変換メソッド
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'wordCount': wordCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Chapter.fromJson(Map<String, dynamic> json) {
    return Chapter(
      id: json['id'],
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      wordCount: json['wordCount'] ?? 0,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  // 既存のNovelから変換するファクトリメソッド
  factory Chapter.fromNovel(Novel novel) {
    return Chapter(
      title: novel.title,
      content: novel.content,
      wordCount: _calculateWordCount(novel.content),
      createdAt: novel.createdAt,
      updatedAt: novel.updatedAt,
    );
  }
}
