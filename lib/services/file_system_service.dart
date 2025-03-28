import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:github/github.dart';
import '../models/work.dart';
import '../models/chapter.dart';

/// フォルダ構造による小説管理システムのためのファイルシステムサービス
class FileSystemService {
  /// 作品をフォルダとして保存する
  ///
  /// 作品の各章を個別のMarkdownファイルとして保存し、
  /// メタデータをJSONファイルとして保存します。
  Future<String> saveWorkToFolder(Work work, {String? customPath}) async {
    try {
      // 保存先フォルダの取得または作成
      final Directory workDir = await _getWorkDirectory(work, customPath);

      // メタデータJSONの作成
      final Map<String, dynamic> metadata = work.toJson();

      // 章のファイルパス情報を追加
      final List<Map<String, dynamic>> chaptersWithFilePaths = [];
      for (int i = 0; i < work.chapters.length; i++) {
        final chapter = work.chapters[i];
        final chapterFileName = _sanitizeFileName(
            '${i + 1}_${chapter.title.isEmpty ? "無題の章" : chapter.title}.md');

        chaptersWithFilePaths.add({
          ...chapter.toJson(),
          'file': chapterFileName,
        });
      }
      metadata['chapters'] = chaptersWithFilePaths;

      // メタデータファイルの保存
      final File metadataFile = File('${workDir.path}/metadata.json');
      await metadataFile.writeAsString(jsonEncode(metadata), flush: true);

      // 各章のファイル保存
      for (int i = 0; i < work.chapters.length; i++) {
        final chapter = work.chapters[i];
        final chapterFileName = _sanitizeFileName(
            '${i + 1}_${chapter.title.isEmpty ? "無題の章" : chapter.title}.md');
        final File chapterFile = File('${workDir.path}/$chapterFileName');
        await chapterFile.writeAsString(chapter.content, flush: true);
      }

      return workDir.path;
    } catch (e) {
      debugPrint('作品のフォルダ保存エラー: $e');
      rethrow;
    }
  }

  /// フォルダから作品を読み込む
  Future<Work> loadWorkFromFolder(String folderPath) async {
    try {
      final Directory workDir = Directory(folderPath);
      if (!await workDir.exists()) {
        throw Exception('指定されたフォルダが存在しません: $folderPath');
      }

      // メタデータファイルの読み込み
      final File metadataFile = File('${workDir.path}/metadata.json');
      if (!await metadataFile.exists()) {
        throw Exception('メタデータファイルが見つかりません: ${metadataFile.path}');
      }

      final String metadataContent = await metadataFile.readAsString();
      final Map<String, dynamic> metadata = jsonDecode(metadataContent);

      // 章のファイル情報を取得
      final List<dynamic> chaptersData = metadata['chapters'];
      final List<Chapter> chapters = [];

      for (final chapterData in chaptersData) {
        final String chapterFileName = chapterData['file'];
        final File chapterFile = File('${workDir.path}/$chapterFileName');

        if (await chapterFile.exists()) {
          final String chapterContent = await chapterFile.readAsString();

          // 章のデータを作成
          final chapter = Chapter(
            id: chapterData['id'],
            title: chapterData['title'],
            content: chapterContent, // ファイルから読み込んだ内容
            wordCount:
                chapterContent.replaceAll(RegExp(r'\s+'), '').length, // 再計算
            createdAt: DateTime.parse(chapterData['createdAt']),
            updatedAt: DateTime.parse(chapterData['updatedAt']),
          );

          chapters.add(chapter);
        }
      }

      // 作品オブジェクトの作成
      final work = Work(
        id: metadata['id'],
        title: metadata['title'],
        author: metadata['author'],
        description: metadata['description'],
        createdAt: DateTime.parse(metadata['createdAt']),
        updatedAt: DateTime.parse(metadata['updatedAt']),
        chapters: chapters,
      );

      return work;
    } catch (e) {
      debugPrint('作品のフォルダ読み込みエラー: $e');
      rethrow;
    }
  }

  /// 作品フォルダの一覧を取得
  Future<List<String>> listWorkFolders() async {
    try {
      final Directory baseDir = await _getBaseDirectory();
      final List<FileSystemEntity> entities = await baseDir.list().toList();

      final List<String> workFolders = [];

      for (final entity in entities) {
        if (entity is Directory) {
          final File metadataFile = File('${entity.path}/metadata.json');
          if (await metadataFile.exists()) {
            workFolders.add(entity.path);
          }
        }
      }

      return workFolders;
    } catch (e) {
      debugPrint('作品フォルダ一覧の取得エラー: $e');
      return [];
    }
  }

  /// 作品フォルダを選択するダイアログを表示
  Future<String?> pickWorkFolder() async {
    try {
      final String? selectedDirectory =
          await FilePicker.platform.getDirectoryPath();
      if (selectedDirectory != null) {
        final File metadataFile = File('$selectedDirectory/metadata.json');
        if (await metadataFile.exists()) {
          return selectedDirectory;
        } else {
          throw Exception('選択されたフォルダには作品のメタデータが含まれていません');
        }
      }
      return null;
    } catch (e) {
      debugPrint('フォルダ選択エラー: $e');
      rethrow;
    }
  }

  /// 保存先フォルダを選択するダイアログを表示
  Future<String?> pickSaveFolder() async {
    try {
      final String? selectedDirectory =
          await FilePicker.platform.getDirectoryPath();
      return selectedDirectory;
    } catch (e) {
      debugPrint('保存先フォルダ選択エラー: $e');
      rethrow;
    }
  }

  /// GitHubリポジトリに作品をエクスポート
  ///
  /// 注意: この機能は現在簡易実装です。実際のGitHub連携には
  /// 追加の設定や認証が必要になる場合があります。
  Future<String> exportWorkToGitHub(Work work) async {
    try {
      // 作品フォルダの一時保存（実際のGitHub連携の代わりに）
      final String workDirPath = await saveWorkToFolder(work);

      // 実際のGitHub連携は今後実装
      // 現在はフォルダエクスポートのみ実装

      return '作品「${work.title}」をフォルダにエクスポートしました: $workDirPath\n'
          'GitHub連携機能は今後のアップデートで実装予定です。';
    } catch (e) {
      debugPrint('GitHub連携エラー: $e');
      rethrow;
    }
  }

  /// 作品の保存先ディレクトリを取得または作成
  Future<Directory> _getWorkDirectory(Work work, [String? customPath]) async {
    final String dirName =
        _sanitizeFileName(work.title.isEmpty ? '無題の作品' : work.title);

    Directory workDir;
    if (customPath != null) {
      workDir = Directory('$customPath/$dirName');
    } else {
      final Directory baseDir = await _getBaseDirectory();
      workDir = Directory('${baseDir.path}/$dirName');
    }

    if (!await workDir.exists()) {
      await workDir.create(recursive: true);
    }

    return workDir;
  }

  /// ベースディレクトリを取得
  Future<Directory> _getBaseDirectory() async {
    final Directory appDocDir = await getApplicationDocumentsDirectory();
    final Directory baseDir = Directory('${appDocDir.path}/tomofude_works');

    if (!await baseDir.exists()) {
      await baseDir.create(recursive: true);
    }

    return baseDir;
  }

  /// ファイル名に使用できない文字を置換
  String _sanitizeFileName(String fileName) {
    return fileName
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(RegExp(r'\s+'), '_');
  }
}
