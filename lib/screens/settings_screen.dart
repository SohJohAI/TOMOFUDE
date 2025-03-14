import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/app_settings.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<NovelAppState>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.dark_mode),
            title: const Text('ダークモード'),
            trailing: Switch(
              value: appState.isDarkMode,
              onChanged: (value) {
                appState.toggleTheme();
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.text_fields),
            title: const Text('文字サイズ'),
            subtitle: Slider(
              min: 12,
              max: 24,
              divisions: 12,
              label: appState.settings.fontSize.round().toString(),
              value: appState.settings.fontSize,
              onChanged: (value) {
                appState.updateFontSize(value);
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.font_download),
            title: const Text('フォント'),
            trailing: DropdownButton<String>(
              value: appState.settings.fontFamily,
              items: const [
                DropdownMenuItem(
                  value: 'Hiragino Sans',
                  child: Text('ヒラギノ角ゴ'),
                ),
                DropdownMenuItem(
                  value: 'YuMincho',
                  child: Text('游明朝'),
                ),
                DropdownMenuItem(
                  value: 'Noto Sans JP',
                  child: Text('Noto Sans'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  appState.updateFontFamily(value);
                }
              },
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('アプリについて'),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: '共筆。（TOMOFUDE）',
                applicationVersion: 'バージョン 1.1',
                applicationIcon: const Icon(Icons.book, size: 48),
                applicationLegalese: '© 2023-2025 TOMOFUDE Project',
                children: [
                  const SizedBox(height: 16),
                  const Text('AI支援型小説執筆アプリです。\nあなたの創作をサポートします。'),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
