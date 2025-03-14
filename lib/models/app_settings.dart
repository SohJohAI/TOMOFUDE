class AppSettings {
  bool isDarkMode;
  String fontFamily;
  double fontSize;

  AppSettings({
    this.isDarkMode = false,
    this.fontFamily = 'Hiragino Sans',
    this.fontSize = 16.0,
  });

  Map<String, dynamic> toJson() {
    return {
      'isDarkMode': isDarkMode,
      'fontFamily': fontFamily,
      'fontSize': fontSize,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      isDarkMode: json['isDarkMode'] ?? false,
      fontFamily: json['fontFamily'] ?? 'Hiragino Sans',
      fontSize: json['fontSize'] ?? 16.0,
    );
  }
}
