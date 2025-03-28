import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/work.dart';
import '../models/chapter.dart';
import '../models/novel.dart';

class WorkListProvider extends ChangeNotifier {
  List<Work> _works = [];

  List<Work> get works => _works;

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
}
