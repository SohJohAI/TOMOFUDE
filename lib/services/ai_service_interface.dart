import '../models/novel.dart';

abstract class AIService {
  Future<List<String>> generateContinuations(String content);
  Future<String> expandSuggestion(String content, String suggestion);
  Map<String, dynamic> generateSettings(String content);
  Map<String, dynamic> generatePlotAnalysis(String content);
  Map<String, String> generateReview();

  // 新規追加メソッド
  Future<Map<String, dynamic>> analyzeEmotion(String content, {String? aiDocs});
  Future<String> generateAIDocs(String content,
      {String? settingInfo, String? plotInfo, String? emotionInfo});
}
