import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../models/novel.dart';

class NovelEditor extends StatelessWidget {
  final TextEditingController contentController;
  final Function onContentChanged;

  const NovelEditor({
    Key? key,
    required this.contentController,
    required this.onContentChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252525) : CupertinoColors.white,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: isDark
              ? CupertinoColors.systemGrey.darkColor
              : CupertinoColors.systemGrey.color,
          width: 0.5,
        ),
      ),
      child: CupertinoTextField(
        controller: contentController,
        maxLines: null,
        minLines: 20,
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(8.0),
        ),
        placeholder: 'ここに小説を書いてください...',
        placeholderStyle: TextStyle(
          color: isDark
              ? CupertinoColors.systemGrey.darkColor
              : CupertinoColors.systemGrey.color,
        ),
        style: TextStyle(
          color: isDark ? CupertinoColors.white : CupertinoColors.black,
          fontSize: 16.0,
          height: 1.5, // 行間を調整して読みやすく
        ),
        onChanged: (value) {
          onContentChanged(value);
        },
        cursorColor: CupertinoTheme.of(context).primaryColor,
        // 高解像度ディスプレイ向けの最適化
        strutStyle: const StrutStyle(
          forceStrutHeight: true,
          height: 1.2,
          leading: 0.5,
        ),
        // 画面端のスワイプジェスチャーとの干渉を防ぐ
        keyboardAppearance: isDark ? Brightness.dark : Brightness.light,
      ),
    );
  }
}
