import 'package:flutter/material.dart';
import '../models/app_settings.dart';

class NovelAppState extends ChangeNotifier {
  String currentNovelContent = '';
  bool isDarkMode = false;
  AppSettings settings = AppSettings();

  void toggleTheme() {
    isDarkMode = !isDarkMode;
    settings.isDarkMode = isDarkMode;
    notifyListeners();
  }

  void updateNovelContent(String content) {
    currentNovelContent = content;
    notifyListeners();
  }

  void updateFontSize(double size) {
    settings.fontSize = size;
    notifyListeners();
  }

  void updateFontFamily(String fontFamily) {
    settings.fontFamily = fontFamily;
    notifyListeners();
  }
}
