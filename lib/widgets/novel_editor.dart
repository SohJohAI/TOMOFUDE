import 'package:flutter/material.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
        ),
      ),
      child: TextField(
        controller: contentController,
        maxLines: null,
        expands: true,
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.all(16.0),
          border: InputBorder.none,
          hintText: 'ここに小説を書いてください...',
          hintStyle: TextStyle(
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black87,
          fontSize: 16.0,
        ),
        onChanged: (value) {
          onContentChanged(value);
        },
      ),
    );
  }
}
