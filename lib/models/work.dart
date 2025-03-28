import 'package:uuid/uuid.dart';
import 'chapter.dart';
import 'novel.dart';

class Work {
  final String id;
  String title;
  String author;
  String description;
  final DateTime createdAt;
  DateTime updatedAt;
  List<Chapter> chapters;
  String? folderPath; // 作品のフォルダパス
  String? githubRepoUrl; // GitHubリポジトリURL

  Work({
    String? id,
    this.title = '',
    this.author = '',
    this.description = '',
    List<Chapter>? chapters,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.folderPath,
    this.githubRepoUrl,
  })  : this.id = id ?? const Uuid().v4(),
        this.chapters = chapters ?? [],
        this.createdAt = createdAt ?? DateTime.now(),
        this.updatedAt = updatedAt ?? DateTime.now();

  // 統計情報取得メソッド
  int getTotalWordCount() {
    return chapters.fold(0, (sum, chapter) => sum + chapter.wordCount);
  }

  int getChapterCount() {
    return chapters.length;
  }

  // JSON変換メソッド
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'chapters': chapters.map((chapter) => chapter.toJson()).toList(),
      'folderPath': folderPath,
      'githubRepoUrl': githubRepoUrl,
    };
  }

  factory Work.fromJson(Map<String, dynamic> json) {
    return Work(
      id: json['id'],
      title: json['title'] ?? '',
      author: json['author'] ?? '',
      description: json['description'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      chapters: (json['chapters'] as List?)
              ?.map((chapterJson) => Chapter.fromJson(chapterJson))
              .toList() ??
          [],
      folderPath: json['folderPath'],
      githubRepoUrl: json['githubRepoUrl'],
    );
  }

  // 既存のNovelから変換するファクトリメソッド
  factory Work.fromNovel(Novel novel) {
    final chapter = Chapter.fromNovel(novel);
    return Work(
      title: novel.title,
      chapters: [chapter],
      createdAt: novel.createdAt,
      updatedAt: novel.updatedAt,
    );
  }
}
