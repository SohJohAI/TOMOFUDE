import '../models/novel.dart';

abstract class AIService {
  Future<List<String>> generateContinuations(String content);
  Future<String> expandSuggestion(String content, String suggestion);
  Map<String, dynamic> generateSettings(String content);
  Map<String, dynamic> generatePlotAnalysis(String content);
  Map<String, String> generateReview();
}
