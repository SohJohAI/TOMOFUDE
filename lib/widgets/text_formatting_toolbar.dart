import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class TextFormattingToolbar extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onPreviewPressed;

  const TextFormattingToolbar({
    Key? key,
    required this.controller,
    required this.onPreviewPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;

    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : CupertinoColors.white,
        border: Border(
          top: BorderSide(
            color: isDark
                ? CupertinoColors.systemGrey.darkColor
                : CupertinoColors.systemGrey4,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildToolbarButton(
            context: context,
            icon: CupertinoIcons.text_badge_checkmark,
            tooltip: 'ルビを追加',
            onPressed: () => _showRubyDialog(context),
          ),
          _buildToolbarButton(
            context: context,
            icon: CupertinoIcons.textformat_abc_dottedunderline,
            tooltip: '傍点を追加',
            onPressed: () => _showEmphasisDotsDialog(context),
          ),
          _buildToolbarButton(
            context: context,
            icon: CupertinoIcons.minus,
            tooltip: '罫線を追加',
            onPressed: () => _insertHorizontalLine(),
          ),
          _buildToolbarButton(
            context: context,
            icon: CupertinoIcons.ellipsis,
            tooltip: '三点リーダを追加',
            onPressed: () => _insertEllipsis(),
          ),
          _buildToolbarButton(
            context: context,
            icon: CupertinoIcons.eye,
            tooltip: 'プレビュー',
            onPressed: () => onPreviewPressed(controller.text),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbarButton({
    required BuildContext context,
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;

    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      onPressed: onPressed,
      child: Tooltip(
        message: tooltip,
        child: Icon(
          icon,
          size: 22,
          color: isDark ? CupertinoColors.white : CupertinoColors.black,
        ),
      ),
    );
  }

  // ルビダイアログを表示
  void _showRubyDialog(BuildContext context) {
    final baseTextController = TextEditingController();
    final rubyTextController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('ルビを追加'),
        content: Form(
          key: formKey,
          child: Column(
            children: [
              const SizedBox(height: 10),
              CupertinoFormRow(
                prefix: const Text('親文字:'),
                child: CupertinoTextFormFieldRow(
                  controller: baseTextController,
                  placeholder: '親文字（最大10文字）',
                  maxLength: 10,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '親文字を入力してください';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 10),
              CupertinoFormRow(
                prefix: const Text('ルビ:'),
                child: CupertinoTextFormFieldRow(
                  controller: rubyTextController,
                  placeholder: 'ルビ（最大10文字）',
                  maxLength: 10,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'ルビを入力してください';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                '形式: ｜親文字《ルビ》',
                style: TextStyle(
                  fontSize: 12,
                  color: CupertinoColors.systemGrey,
                ),
              ),
            ],
          ),
        ),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          CupertinoDialogAction(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                final baseText = baseTextController.text;
                final rubyText = rubyTextController.text;
                _insertRuby(baseText, rubyText);
                Navigator.pop(context);
              }
            },
            child: const Text('追加'),
          ),
        ],
      ),
    );
  }

  // 傍点ダイアログを表示
  void _showEmphasisDotsDialog(BuildContext context) {
    final baseTextController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('傍点を追加'),
        content: Form(
          key: formKey,
          child: Column(
            children: [
              const SizedBox(height: 10),
              CupertinoFormRow(
                prefix: const Text('文字:'),
                child: CupertinoTextFormFieldRow(
                  controller: baseTextController,
                  placeholder: '傍点をつける文字（最大10文字）',
                  maxLength: 10,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '傍点をつける文字を入力してください';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                '形式: ｜傍点をつける文字《・・・》',
                style: TextStyle(
                  fontSize: 12,
                  color: CupertinoColors.systemGrey,
                ),
              ),
            ],
          ),
        ),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          CupertinoDialogAction(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                final baseText = baseTextController.text;
                _insertEmphasisDots(baseText);
                Navigator.pop(context);
              }
            },
            child: const Text('追加'),
          ),
        ],
      ),
    );
  }

  // ルビを挿入
  void _insertRuby(String baseText, String rubyText) {
    final currentText = controller.text;
    final selection = controller.selection;
    final rubyFormat = '｜$baseText《$rubyText》';

    final newText = currentText.replaceRange(
      selection.start,
      selection.end,
      rubyFormat,
    );

    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: selection.start + rubyFormat.length,
      ),
    );
  }

  // 傍点を挿入
  void _insertEmphasisDots(String baseText) {
    final currentText = controller.text;
    final selection = controller.selection;
    final dots = '・' * baseText.length;
    final emphasisFormat = '｜$baseText《$dots》';

    final newText = currentText.replaceRange(
      selection.start,
      selection.end,
      emphasisFormat,
    );

    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: selection.start + emphasisFormat.length,
      ),
    );
  }

  // 罫線を挿入
  void _insertHorizontalLine() {
    final currentText = controller.text;
    final selection = controller.selection;
    const horizontalLine = '――';

    final newText = currentText.replaceRange(
      selection.start,
      selection.end,
      horizontalLine,
    );

    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: selection.start + horizontalLine.length,
      ),
    );
  }

  // 三点リーダを挿入
  void _insertEllipsis() {
    final currentText = controller.text;
    final selection = controller.selection;
    const ellipsis = '……';

    final newText = currentText.replaceRange(
      selection.start,
      selection.end,
      ellipsis,
    );

    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: selection.start + ellipsis.length,
      ),
    );
  }
}
