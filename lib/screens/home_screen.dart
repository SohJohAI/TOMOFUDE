import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:url_launcher/url_launcher.dart';
import 'auth_screen.dart';
import 'transaction_law_screen.dart';
import 'subscription_screen.dart';
import 'faq_screen.dart';

/// A screen that displays the homepage of the app.
///
/// This screen serves as the landing page for the app, providing information
/// about the app's features and subscription plans, as well as links to other
/// screens.
class HomeScreen extends StatelessWidget {
  /// Creates a home screen.
  HomeScreen({Key? key}) : super(key: key);

  final Uri plotBoosterUrl =
      Uri.parse('https://poe.com/no_deep_link/plotbooster');

  /// Launches the plot booster URL.
  void _launchURL() async {
    if (await canLaunchUrl(plotBoosterUrl)) {
      await launchUrl(plotBoosterUrl);
    } else {
      throw 'Could not launch $plotBoosterUrl';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    final primaryColor = CupertinoTheme.of(context).primaryColor;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('共筆。公式サイト'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                Navigator.of(context).pushNamed('/faq');
              },
              child: const Text('使い方',
                  style: TextStyle(color: CupertinoColors.white)),
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                Navigator.of(context).pushNamed('/subscription');
              },
              child: const Text('料金プラン',
                  style: TextStyle(color: CupertinoColors.white)),
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                Navigator.of(context).pushNamed('/transaction_law');
              },
              child: const Text('特商法表記',
                  style: TextStyle(color: CupertinoColors.white)),
            ),
          ],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      const SizedBox(height: 40),
                      const Text('AIと一緒に、小説を書こう。',
                          style: TextStyle(
                              fontSize: 28, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      const Text('共筆。はAIが創作を支援する小説執筆サポートツールです。'),
                      const SizedBox(height: 20),
                      CupertinoButton.filled(
                        onPressed: () {
                          Navigator.of(context).pushNamed('/auth');
                        },
                        child: const Text('今すぐ使ってみる'),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
                const Text('主な機能',
                    style:
                        TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                const Text('・プロットブースター：ステップ形式で物語の骨子を構築'),
                const Text('・設定情報の自動生成：キャラクターや世界観をAIが提案'),
                const Text('・展開候補提示：続きを書くためのアイデアを提供'),
                const SizedBox(height: 32),
                const Text('料金プラン',
                    style:
                        TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                const Text('・梅：月額500円（約13,000文字）'),
                const Text('・竹：月額1,500円（約30,000文字）'),
                const Text('・松：月額3,000円（約100,000文字）'),
                const SizedBox(height: 32),
                const Text('お問い合わせ',
                    style:
                        TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                const Text('蒼青藍プロダクション'),
                const Text('メール: example@example.com'),
                const SizedBox(height: 32),

                // 特商法表記へのリンク
                Center(
                  child: CupertinoButton(
                    color: CupertinoTheme.of(context).primaryColor,
                    onPressed: () {
                      Navigator.of(context).pushNamed('/transaction_law');
                    },
                    child: const Text('特定商取引法に基づく表記'),
                  ),
                ),
                const SizedBox(height: 40),
                const Divider(),
                const Center(child: Text('© 2025 蒼青藍プロダクション')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
