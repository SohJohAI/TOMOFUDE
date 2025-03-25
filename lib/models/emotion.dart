class EmotionSegment {
  final String name;
  final String dominantEmotion;
  final String emotionCode;
  final int emotionValue;
  final int excitement;
  final String description;

  EmotionSegment({
    required this.name,
    required this.dominantEmotion,
    required this.emotionCode,
    required this.emotionValue,
    required this.excitement,
    required this.description,
  });

  factory EmotionSegment.fromJson(Map<String, dynamic> json) {
    return EmotionSegment(
      name: json['name'] ?? '',
      dominantEmotion: json['dominantEmotion'] ?? '',
      emotionCode: json['emotionCode'] ?? '#808080',
      emotionValue: json['emotionValue'] ?? 50,
      excitement: json['excitement'] ?? 50,
      description: json['description'] ?? '',
    );
  }
}

class EmotionAnalysis {
  final List<EmotionSegment> segments;
  final String summary;

  EmotionAnalysis({
    required this.segments,
    required this.summary,
  });

  factory EmotionAnalysis.fromJson(Map<String, dynamic> json) {
    final segmentsJson = json['segments'] as List<dynamic>? ?? [];
    final segments = segmentsJson
        .map((segmentJson) => EmotionSegment.fromJson(segmentJson))
        .toList();

    return EmotionAnalysis(
      segments: segments,
      summary: json['summary'] ?? '',
    );
  }
}
