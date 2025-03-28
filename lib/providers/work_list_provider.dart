import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/work.dart';
import '../models/chapter.dart';
import '../models/novel.dart';
import '../services/file_system_service.dart';

class WorkListProvider extends ChangeNotifier {
  List<Work> _works = [];
  final FileSystemService _fileSystemService = FileSystemService();

  List<Work> get works => _works;
  FileSystemService get fileSystemService => _fileSystemService;

  WorkListProvider() {
    _loadWorks();
  }

  Future<void> _loadWorks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final worksJson = prefs.getStringList('work_list');

      if (worksJson != null) {
        _works = worksJson.map((jsonString) {
          final Map<String, dynamic> json =
              Map<String, dynamic>.from(Map.castFrom(jsonDecode(jsonString)));
          return Work.fromJson(json);
        }).toList();
        notifyListeners();
      }
    } catch (e) {
      print('作品リストの読み込みエラー: $e');
    }
  }

  Future<void> saveWorks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final worksJson =
          _works.map((work) => jsonEncode(work.toJson())).toList();

      await prefs.setStringList('work_list', worksJson);
    } catch (e) {
      print('作品リストの保存エラー: $e');
    }
  }

  void addWork(Work work) {
    _works.add(work);
    saveWorks();
    notifyListeners();
  }

  void updateWork(Work work) {
    final index = _works.indexWhere((w) => w.id == work.id);
    if (index >= 0) {
      _works[index] = work;
      saveWorks();
      notifyListeners();
    }
  }

  void removeWork(String id) {
    _works.removeWhere((work) => work.id == id);
    saveWorks();
    notifyListeners();
  }

  Work? getWork(String id) {
    try {
      return _works.firstWhere((work) => work.id == id);
    } catch (e) {
      return null;
    }
  }

  // 章の操作メソッド
  void addChapter(String workId, Chapter chapter) {
    final work = getWork(workId);
    if (work != null) {
      work.chapters.add(chapter);
      work.updatedAt = DateTime.now();
      saveWorks();
      notifyListeners();
    }
  }

  void updateChapter(String workId, Chapter chapter) {
    final work = getWork(workId);
    if (work != null) {
      final index = work.chapters.indexWhere((c) => c.id == chapter.id);
      if (index >= 0) {
        work.chapters[index] = chapter;
        work.updatedAt = DateTime.now();
        saveWorks();
        notifyListeners();
      }
    }
  }

  void removeChapter(String workId, String chapterId) {
    final work = getWork(workId);
    if (work != null) {
      work.chapters.removeWhere((chapter) => chapter.id == chapterId);
      work.updatedAt = DateTime.now();
      saveWorks();
      notifyListeners();
    }
  }

  Chapter? getChapter(String workId, String chapterId) {
    final work = getWork(workId);
    if (work != null) {
      try {
        return work.chapters.firstWhere((chapter) => chapter.id == chapterId);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  // 章の順序変更
  void reorderChapters(String workId, int oldIndex, int newIndex) {
    final work = getWork(workId);
    if (work != null) {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final chapter = work.chapters.removeAt(oldIndex);
      work.chapters.insert(newIndex, chapter);
      work.updatedAt = DateTime.now();
      saveWorks();
      notifyListeners();
    }
  }

  // 既存の小説から作品への変換
  void convertNovelToWork(Novel novel) {
    final work = Work.fromNovel(novel);
    addWork(work);
  }

  // ファイルシステム関連のメソッド

  /// 作品をフォルダとして保存
  Future<String> saveWorkToFolder(String workId, {String? customPath}) async {
    try {
      final work = getWork(workId);
      if (work == null) {
        throw Exception('指定されたIDの作品が見つかりません: $workId');
      }

      final String folderPath = await _fileSystemService.saveWorkToFolder(
        work,
        customPath: customPath,
      );

      // 作品のフォルダパスを更新
      work.folderPath = folderPath;
      updateWork(work);

      return folderPath;
    } catch (e) {
      print('作品のフォルダ保存エラー: $e');
      rethrow;
    }
  }

  /// フォルダから作品を読み込み
  Future<Work> loadWorkFromFolder(String folderPath) async {
    try {
      final Work work = await _fileSystemService.loadWorkFromFolder(folderPath);

      // 既存の作品かどうかを確認
      final existingWorkIndex = _works.indexWhere((w) => w.id == work.id);

      if (existingWorkIndex >= 0) {
        // 既存の作品を更新
        _works[existingWorkIndex] = work;
      } else {
        // 新しい作品を追加
        _works.add(work);
      }

      // フォルダパスを設定
      work.folderPath = folderPath;

      saveWorks();
      notifyListeners();

      return work;
    } catch (e) {
      print('作品のフォルダ読み込みエラー: $e');
      rethrow;
    }
  }

  /// 作品フォルダを選択して読み込み
  Future<Work?> pickAndLoadWorkFolder() async {
    try {
      final String? folderPath = await _fileSystemService.pickWorkFolder();
      if (folderPath != null) {
        return await loadWorkFromFolder(folderPath);
      }
      return null;
    } catch (e) {
      print('作品フォルダの選択と読み込みエラー: $e');
      rethrow;
    }
  }

  /// 作品をGitHubにエクスポート
  Future<String> exportWorkToGitHub(String workId) async {
    try {
      final work = getWork(workId);
      if (work == null) {
        throw Exception('指定されたIDの作品が見つかりません: $workId');
      }

      return await _fileSystemService.exportWorkToGitHub(work);
    } catch (e) {
      print('作品のGitHubエクスポートエラー: $e');
      rethrow;
    }
  }

  /// 作品フォルダの一覧を取得
  Future<List<String>> listWorkFolders() async {
    try {
      return await _fileSystemService.listWorkFolders();
    } catch (e) {
      print('作品フォルダ一覧の取得エラー: $e');
      return [];
    }
  }
}
