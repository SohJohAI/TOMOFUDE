import '../models/novel.dart';

abstract class AIService {
  Future<List<String>> generateContinuations(String content,
      {String? aiDocs, String? newContent, String? settingInfo});
  Future<String> expandSuggestion(String content, String suggestion,
      {String? aiDocs, String? recentContent});
  Future<Map<String, dynamic>> generateSettings(String content,
      {String? aiDocs, String? contentType});
  Future<Map<String, dynamic>> generatePlotAnalysis(String content,
      {String? aiDocs, String? newContent});
  Future<Map<String, String>> generateReview(String analysisContent);

  // 新規追加メソッド
  Future<Map<String, dynamic>> analyzeEmotion(String content, {String? aiDocs});
  Future<String> generateAIDocs(String content,
      {String? settingInfo, String? plotInfo, String? emotionInfo});
}
