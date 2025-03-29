import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../widgets/ruby_text_widget.dart';

class PreviewService {
  // 特殊文字をプレビュー用のウィジェットに変換
  static List<Widget> convertTextToPreviewWidgets(String text,
      {bool isDark = false}) {
    final List<Widget> widgets = [];
    final paragraphs = text.split(RegExp(r'\n\s*\n'));

    for (final paragraph in paragraphs) {
      if (paragraph.trim().isEmpty) continue;

      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: _buildParagraphWidget(paragraph, isDark),
        ),
      );
    }

    return widgets;
  }

  // 段落をウィジェットに変換
  static Widget _buildParagraphWidget(String paragraph, bool isDark) {
    final List<InlineSpan> spans = [];
    final RegExp rubyPattern = RegExp(r'｜([^《]+)《([^》]+)》');

    int lastMatchEnd = 0;

    // ルビと傍点のパターンを検出して変換
    for (final match in rubyPattern.allMatches(paragraph)) {
      final baseText = match.group(1)!;
      final rubyText = match.group(2)!;

      // マッチの前のテキストを追加
      if (match.start > lastMatchEnd) {
        final beforeText = paragraph.substring(lastMatchEnd, match.start);
        spans.add(TextSpan(
          text: _replaceSpecialCharacters(beforeText),
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 16.0,
            height: 1.5,
          ),
        ));
      }

      // ルビテキストを追加
      spans.add(WidgetSpan(
        child: RubyTextWidget(
          text: baseText,
          ruby: rubyText,
          textStyle: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 16.0,
          ),
          rubyStyle: TextStyle(
            color: isDark ? Colors.white70 : Colors.black54,
            fontSize: 8.0,
          ),
        ),
      ));

      lastMatchEnd = match.end;
    }

    // 残りのテキストを追加
    if (lastMatchEnd < paragraph.length) {
      final remainingText = paragraph.substring(lastMatchEnd);
      spans.add(TextSpan(
        text: _replaceSpecialCharacters(remainingText),
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black,
          fontSize: 16.0,
          height: 1.5,
        ),
      ));
    }

    return RichText(
      text: TextSpan(children: spans),
      textAlign: TextAlign.justify,
    );
  }

  // 罫線と三点リーダを置換
  static String _replaceSpecialCharacters(String text) {
    // 特殊文字はそのまま表示
    return text;
  }

  // プレビューダイアログを表示
  static void showPreviewDialog(BuildContext context, String text) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;

    showCupertinoModalPopup(
      context: context,
      builder: (context) => _buildPreviewModal(context, text, isDark),
    );
  }

  // プレビューモーダルを構築
  static Widget _buildPreviewModal(
      BuildContext context, String text, bool isDark) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;

    return Container(
      height: isSmallScreen ? screenSize.height * 0.8 : screenSize.height * 0.7,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : CupertinoColors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Column(
        children: [
          // ヘッダー
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDark
                      ? CupertinoColors.systemGrey.darkColor
                      : CupertinoColors.systemGrey4,
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'プレビュー',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: const Text('閉じる'),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // プレビュー内容
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: CupertinoScrollbar(
                thickness: 6.0,
                radius: const Radius.circular(10.0),
                thumbVisibility: true,
                child: SingleChildScrollView(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children:
                          convertTextToPreviewWidgets(text, isDark: isDark),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
