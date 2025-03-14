import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/novel.dart';

class NovelListProvider extends ChangeNotifier {
  List<Novel> _novels = [];

  List<Novel> get novels => _novels;

  NovelListProvider() {
    _loadNovels();
  }

  Future<void> _loadNovels() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final novelsJson = prefs.getStringList('novel_list');

      if (novelsJson != null) {
        _novels = novelsJson.map((jsonString) {
          final Map<String, dynamic> json =
              Map<String, dynamic>.from(Map.castFrom(jsonDecode(jsonString)));
          return Novel.fromJson(json);
        }).toList();
        notifyListeners();
      }
    } catch (e) {
      print('小説リストの読み込みエラー: $e');
    }
  }

  Future<void> saveNovels() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final novelsJson =
          _novels.map((novel) => jsonEncode(novel.toJson())).toList();

      await prefs.setStringList('novel_list', novelsJson);
    } catch (e) {
      print('小説リストの保存エラー: $e');
    }
  }

  void addNovel(Novel novel) {
    _novels.add(novel);
    saveNovels();
    notifyListeners();
  }

  void updateNovel(Novel novel) {
    final index = _novels.indexWhere((n) => n.id == novel.id);
    if (index >= 0) {
      _novels[index] = novel;
      saveNovels();
      notifyListeners();
    }
  }

  void removeNovel(String id) {
    _novels.removeWhere((novel) => novel.id == id);
    saveNovels();
    notifyListeners();
  }

  Novel? getNovel(String id) {
    try {
      return _novels.firstWhere((novel) => novel.id == id);
    } catch (e) {
      return null;
    }
  }
}
