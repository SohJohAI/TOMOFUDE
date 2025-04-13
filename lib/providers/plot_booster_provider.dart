import 'package:flutter/foundation.dart';
import '../models/plot_booster.dart';

class PlotBoosterProvider extends ChangeNotifier {
  PlotBooster _plotBooster = PlotBooster();
  bool _isAIAssistEnabled = true;

  PlotBooster get plotBooster => _plotBooster;
  bool get isAIAssistEnabled => _isAIAssistEnabled;

  void setAIAssistEnabled(bool enabled) {
    _isAIAssistEnabled = enabled;
    notifyListeners();
  }

  // ジャンルと作風の更新
  void updateGenre(String genre) {
    _plotBooster.genre = genre;
    notifyListeners();
  }

  void updateStyle(String style) {
    _plotBooster.style = style;
    notifyListeners();
  }

  // ログラインの更新
  void updateLogline(String logline) {
    _plotBooster.logline = logline;
    notifyListeners();
  }

  // テーマの更新
  void updateThemes(List<String> themes) {
    _plotBooster.themes = themes;
    notifyListeners();
  }

  // 世界観の更新
  void updateWorldSetting(String worldSetting) {
    _plotBooster.worldSetting = worldSetting;
    notifyListeners();
  }

  // キー設定の更新
  void addKeySettings(KeySetting setting) {
    _plotBooster.keySettings.add(setting);
    notifyListeners();
  }

  void updateKeySettings(int index, KeySetting setting) {
    if (index >= 0 && index < _plotBooster.keySettings.length) {
      _plotBooster.keySettings[index] = setting;
      notifyListeners();
    }
  }

  void removeKeySettings(int index) {
    if (index >= 0 && index < _plotBooster.keySettings.length) {
      _plotBooster.keySettings.removeAt(index);
      notifyListeners();
    }
  }

  // キャラクターの更新
  void updateProtagonist(Character character) {
    _plotBooster.protagonist = character;
    notifyListeners();
  }

  void updateAntagonist(Character character) {
    _plotBooster.antagonist = character;
    notifyListeners();
  }

  // 章構成の更新
  void addChapterOutline(ChapterOutline outline) {
    _plotBooster.chapterOutlines.add(outline);
    notifyListeners();
  }

  void updateChapterOutline(int index, ChapterOutline outline) {
    if (index >= 0 && index < _plotBooster.chapterOutlines.length) {
      _plotBooster.chapterOutlines[index] = outline;
      notifyListeners();
    }
  }

  void removeChapterOutline(int index) {
    if (index >= 0 && index < _plotBooster.chapterOutlines.length) {
      _plotBooster.chapterOutlines.removeAt(index);
      notifyListeners();
    }
  }

  void reorderChapterOutlines(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final ChapterOutline item = _plotBooster.chapterOutlines.removeAt(oldIndex);
    _plotBooster.chapterOutlines.insert(newIndex, item);
    notifyListeners();
  }

  // AI支援資料の更新
  void updateAISupportMaterial(String material) {
    _plotBooster.aiSupportMaterial = material;
    notifyListeners();
  }

  // プロットブースターのリセット
  void reset() {
    _plotBooster = PlotBooster();
    notifyListeners();
  }
}
