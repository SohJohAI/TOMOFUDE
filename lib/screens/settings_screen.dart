import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import 'transaction_law_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<NovelAppState>(context);
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('設定'),
        border: null,
      ),
      child: SafeArea(
        child: ListView(
          children: [
            // ダークモード設定
            _buildSettingItem(
              context,
              icon: CupertinoIcons.moon_fill,
              title: 'ダークモード',
              trailing: CupertinoSwitch(
                value: appState.isDarkMode,
                activeTrackColor: CupertinoTheme.of(context).primaryColor,
                onChanged: (value) {
                  appState.toggleTheme();
                },
              ),
            ),

            // 文字サイズ設定
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        CupertinoIcons.textformat_size,
                        color: isDark
                            ? CupertinoColors.systemGrey
                            : CupertinoColors.systemGrey2,
                      ),
                      const SizedBox(width: 10),
                      const Text('文字サイズ'),
                      const SizedBox(width: 8),
                      Text(
                        '${appState.settings.fontSize.round()}',
                        style: TextStyle(
                          color: isDark
                              ? CupertinoColors.systemGrey
                              : CupertinoColors.systemGrey2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  CupertinoSlider(
                    min: 12,
                    max: 24,
                    divisions: 12,
                    value: appState.settings.fontSize,
                    onChanged: (value) {
                      appState.updateFontSize(value);
                    },
                  ),
                ],
              ),
            ),

            // フォント設定
            _buildSettingItem(
              context,
              icon: CupertinoIcons.textformat,
              title: 'フォント',
              trailing: CupertinoButton(
                padding: EdgeInsets.zero,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _getFontDisplayName(appState.settings.fontFamily),
                      style: TextStyle(
                        color: isDark
                            ? CupertinoColors.systemGrey
                            : CupertinoColors.systemGrey2,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      CupertinoIcons.chevron_right,
                      color: isDark
                          ? CupertinoColors.systemGrey
                          : CupertinoColors.systemGrey2,
                      size: 18,
                    ),
                  ],
                ),
                onPressed: () => _showFontPicker(context, appState),
              ),
            ),

            // 区切り線
            Container(
              height: 0.5,
              margin: const EdgeInsets.symmetric(vertical: 8),
              color: isDark
                  ? CupertinoColors.systemGrey.withOpacity(0.3)
                  : CupertinoColors.systemGrey4,
            ),

            // アプリについて
            _buildSettingItem(
              context,
              icon: CupertinoIcons.info,
              title: 'アプリについて',
              onTap: () {
                showCupertinoDialog(
                  context: context,
                  builder: (context) => CupertinoAlertDialog(
                    title: const Text('共筆。（TOMOFUDE）'),
                    content: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(height: 8),
                        Text('バージョン 1.1'),
                        SizedBox(height: 8),
                        Text('© 2023-2025 TOMOFUDE Project'),
                        SizedBox(height: 16),
                        Text('AI支援型小説執筆アプリです。\nあなたの創作をサポートします。'),
                      ],
                    ),
                    actions: [
                      CupertinoDialogAction(
                        child: const Text('閉じる'),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                );
              },
            ),

            // 特定商取引法に基づく表記
            _buildSettingItem(
              context,
              icon: CupertinoIcons.doc_text,
              title: '特定商取引法に基づく表記',
              onTap: () {
                Navigator.of(context).push(
                  CupertinoPageRoute(
                    builder: (context) => const TransactionLawScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // 設定項目ウィジェット
  Widget _buildSettingItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: CupertinoColors.systemBackground.withOpacity(0),
        child: Row(
          children: [
            Icon(
              icon,
              color: isDark
                  ? CupertinoColors.systemGrey
                  : CupertinoColors.systemGrey2,
            ),
            const SizedBox(width: 10),
            Text(title),
            const Spacer(),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  // フォント名の表示用文字列を取得
  String _getFontDisplayName(String fontFamily) {
    switch (fontFamily) {
      case 'Hiragino Sans':
        return 'ヒラギノ角ゴ';
      case 'YuMincho':
        return '游明朝';
      case 'Noto Sans JP':
        return 'Noto Sans';
      default:
        return fontFamily;
    }
  }

  // フォント選択ピッカーを表示
  void _showFontPicker(BuildContext context, NovelAppState appState) {
    final fonts = ['ヒラギノ角ゴ', '游明朝', 'Noto Sans'];
    final fontValues = ['Hiragino Sans', 'YuMincho', 'Noto Sans JP'];
    int selectedIndex = fontValues.indexOf(appState.settings.fontFamily);
    if (selectedIndex < 0) selectedIndex = 0;

    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 250,
        color: CupertinoTheme.of(context).scaffoldBackgroundColor,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  child: const Text('キャンセル'),
                  onPressed: () => Navigator.pop(context),
                ),
                CupertinoButton(
                  child: const Text('完了'),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Expanded(
              child: CupertinoPicker(
                itemExtent: 32,
                scrollController: FixedExtentScrollController(
                  initialItem: selectedIndex,
                ),
                onSelectedItemChanged: (index) {
                  appState.updateFontFamily(fontValues[index]);
                },
                children:
                    fonts.map((font) => Center(child: Text(font))).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
