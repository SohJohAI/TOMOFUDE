import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

/// A screen that displays the Specified Commercial Transaction Act disclosure.
///
/// This screen shows the legal information required by the Japanese
/// Specified Commercial Transaction Act (特定商取引法).
class TransactionLawScreen extends StatelessWidget {
  /// Creates a transaction law screen.
  const TransactionLawScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('特定商取引法に基づく表記'),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Title
            const Text(
              '特定商取引法に基づく表記',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            // Content table
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: isDark
                      ? CupertinoColors.systemGrey.darkColor
                      : CupertinoColors.systemGrey4,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Table(
                border: TableBorder.all(
                  color: isDark
                      ? CupertinoColors.systemGrey.darkColor
                      : CupertinoColors.systemGrey4,
                  width: 0.5,
                ),
                columnWidths: const {
                  0: FlexColumnWidth(1),
                  1: FlexColumnWidth(3),
                },
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                children: [
                  _buildTableRow('販売事業者名', '大榮優樹'),
                  _buildTableRow('責任者氏名', '同上'),
                  _buildTableRow('所在地', '埼玉県戸田市新曽1469-1セレブラール戸田210'),
                  _buildTableRow('電話番号', '080-9058-7429'),
                  _buildTableRow('メールアドレス', 'sohjohai@gmail.com'),
                  _buildTableRow(
                    '販売価格',
                    'プランごとに異なります。詳しくは 料金ページ をご確認ください。',
                    onTap: () => _navigateToSubscriptionScreen(context),
                  ),
                  _buildTableRow(
                      '商品代金以外の必要料金', 'なし（インターネット接続にかかる通信費はお客様のご負担となります）'),
                  _buildTableRow('支払い方法', 'クレジットカード（Stripe決済）'),
                  _buildTableRow('支払い時期', 'サブスクリプション申込時に決済されます'),
                  _buildTableRow('商品の引渡時期', '決済完了後すぐにサービスを利用可能です'),
                  _buildTableRow('返品・キャンセルについて',
                      '商品の性質上、提供後の返品・返金は承っておりません。解約はいつでも可能で、次回更新日以降の請求は行われません。'),
                  _buildTableRow('動作環境',
                      '最新版のGoogle Chrome、Safari、EdgeなどのWebブラウザが必要です。スマートフォン・タブレットにも対応しています。'),
                  _buildTableRow(
                      '特別な販売条件', '海外からのご利用には対応しておりません。日本国内に居住の方が対象です。'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a table row with the given title and content.
  TableRow _buildTableRow(String title, String content, {VoidCallback? onTap}) {
    final contentWidget = onTap != null
        ? GestureDetector(
            onTap: onTap,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: content.split('料金ページ')[0]),
                  TextSpan(
                    text: '料金ページ',
                    style: const TextStyle(
                      color: CupertinoColors.activeBlue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  TextSpan(text: content.split('料金ページ')[1]),
                ],
              ),
            ),
          )
        : Text(content);

    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: contentWidget,
        ),
      ],
    );
  }

  /// Navigates to the subscription screen.
  void _navigateToSubscriptionScreen(BuildContext context) {
    Navigator.of(context).pushNamed('/subscription');
  }
}
