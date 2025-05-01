import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/novel.dart';
import '../models/app_settings.dart';
import '../models/work.dart';

class StorageService {
  static const String novelListKey = 'novel_list';
  static const String workListKey = 'work_list';
  static const String settingsKey = 'app_settings';

  // 小説関連のメソッド
  Future<List<Novel>> loadNovels() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final novelsJson = prefs.getStringList(novelListKey);

      if (novelsJson != null) {
        return novelsJson.map((jsonString) {
          final Map<String, dynamic> json =
              Map<String, dynamic>.from(Map.castFrom(jsonDecode(jsonString)));
          return Novel.fromJson(json);
        }).toList();
      }
    } catch (e) {
      print('小説リストの読み込みエラー: $e');
    }
    return [];
  }

  Future<void> saveNovels(List<Novel> novels) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final novelsJson =
          novels.map((novel) => jsonEncode(novel.toJson())).toList();

      await prefs.setStringList(novelListKey, novelsJson);
    } catch (e) {
      print('小説リストの保存エラー: $e');
    }
  }

  // 作品関連のメソッド
  Future<List<Work>> loadWorks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final worksJson = prefs.getStringList(workListKey);

      if (worksJson != null) {
        return worksJson.map((jsonString) {
          final Map<String, dynamic> json =
              Map<String, dynamic>.from(Map.castFrom(jsonDecode(jsonString)));
          return Work.fromJson(json);
        }).toList();
      }
    } catch (e) {
      print('作品リストの読み込みエラー: $e');
    }
    return [];
  }

  Future<void> saveWorks(List<Work> works) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final worksJson = works.map((work) => jsonEncode(work.toJson())).toList();

      await prefs.setStringList(workListKey, worksJson);
    } catch (e) {
      print('作品リストの保存エラー: $e');
    }
  }

  // 設定関連のメソッド
  Future<AppSettings> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString(settingsKey);

      if (settingsJson != null) {
        final Map<String, dynamic> json =
            Map<String, dynamic>.from(Map.castFrom(jsonDecode(settingsJson)));
        return AppSettings.fromJson(json);
      }
    } catch (e) {
      print('設定の読み込みエラー: $e');
    }
    return AppSettings();
  }

  Future<void> saveSettings(AppSettings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = jsonEncode(settings.toJson());

      await prefs.setString(settingsKey, settingsJson);
    } catch (e) {
      print('設定の保存エラー: $e');
    }
  }

  // 小説から作品への変換
  Future<Work> convertNovelToWork(Novel novel) async {
    final work = Work.fromNovel(novel);
    return work;
  }

  // 既存の小説リストから作品リストへの変換
  Future<List<Work>> convertNovelsToWorks(List<Novel> novels) async {
    return novels.map((novel) => Work.fromNovel(novel)).toList();
  }
}
