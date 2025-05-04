import 'package:flutter/cupertino.dart';

// Cupertinoスタイルの折りたたみセクション
class _CupertinoExpandableSection extends StatefulWidget {
  final Widget header;
  final Widget content;

  const _CupertinoExpandableSection({
    Key? key,
    required this.header,
    required this.content,
  }) : super(key: key);

  @override
  _CupertinoExpandableSectionState createState() =>
      _CupertinoExpandableSectionState();
}

class _CupertinoExpandableSectionState
    extends State<_CupertinoExpandableSection> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ヘッダー部分（タップ可能）
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: widget.header),
              Icon(
                _isExpanded
                    ? CupertinoIcons.chevron_up
                    : CupertinoIcons.chevron_down,
                size: 18,
                color: isDark
                    ? CupertinoColors.systemGrey
                    : CupertinoColors.systemGrey2,
              ),
            ],
          ),
        ),

        // コンテンツ部分（展開時のみ表示）
        if (_isExpanded) widget.content,
      ],
    );
  }
}

class FAQScreen extends StatelessWidget {
  const FAQScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('よくある質問'),
        border: null,
      ),
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // タイトルと説明
          const Padding(
            padding: EdgeInsets.only(top: 16),
            child: Text(
              'よくある質問 (FAQ)',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '「共筆。」アプリについてよくある質問と回答をまとめました。',
            style: TextStyle(
              fontSize: 16,
              color: isDark
                  ? CupertinoColors.systemGrey
                  : CupertinoColors.systemGrey2,
            ),
          ),
          const SizedBox(height: 24),

          // FAQ項目
          _buildFAQItem(
            context,
            question: '共筆。（Tomofude)とは？',
            answer:
                '共筆。は小説執筆におけるAIの支援をより簡単に受けられるようにするためのサービスです。ワンクリックで設定情報・プロット・次の展開候補を生成し、執筆のサポートをします。',
          ),

          _buildFAQItem(
            context,
            question: '現在のバージョンでは何ができますか？',
            answer:
                '現在公開しているバージョンではUIを体験できますが、AI機能はダミー（モック）です！実際にAPIを通しているわけではありません。',
          ),

          _buildFAQItem(
            context,
            question: 'AI機能が使えるのは？',
            answer: 'Poe版になります。https://poe.com/TOMOFUDE',
          ),

          _buildFAQItem(
            context,
            question: '今後のアップデート予定は？',
            answer:
                '開発者のやる気と収益化の見込み次第です。ユーザーの皆様が共筆。に可能性を感じていただけるようであれば、APIを実装して本格的にAI機能を提供します。',
          ),

          _buildFAQItem(
            context,
            question: '正式リリースの予定は？',
            answer: '現時点では未定です。皆様のフィードバックや利用状況を見ながら判断します。',
          ),

          _buildFAQItem(
            context,
            question: '利用にお金はかかりますか？',
            answer: '現状、無料で利用できます。ただし、将来的に収益化のため広告導入や有料プランを検討する可能性があります。',
          ),

          _buildFAQItem(
            context,
            question: '不具合を見つけたら？',
            answer: 'もしバグや不具合を見つけた場合は、下記の開発者のメアドもしくはXにてDMを送ってください。X:@sohjohAI',
          ),

          // 必要に応じて追加のFAQ項目
          // ...
          const SizedBox(height: 32),

          // 問い合わせ案内
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF252525)
                  : CupertinoColors.systemGrey6,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark
                    ? CupertinoColors.systemGrey.darkColor
                    : CupertinoColors.systemGrey4,
                width: 0.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'お問い合わせ',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'ご質問やご意見がありましたら、下記のメールアドレスまでご連絡ください。',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? CupertinoColors.systemGrey
                        : CupertinoColors.systemGrey2,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      CupertinoIcons.mail,
                      size: 16,
                      color: CupertinoTheme.of(context).primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'sohjohai@gmail.com',
                      style: TextStyle(
                        color: CupertinoTheme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          // バージョン情報
          Center(
            child: Text(
              'ver 1.0.0',
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? CupertinoColors.systemGrey
                    : CupertinoColors.systemGrey2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // FAQ項目ウィジェット（Cupertinoスタイル）
  Widget _buildFAQItem(
    BuildContext context, {
    required String question,
    required String answer,
  }) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;

    // Cupertinoスタイルの折りたたみパネル
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252525) : CupertinoColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark
              ? CupertinoColors.systemGrey.darkColor
              : CupertinoColors.systemGrey4,
          width: 0.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: _CupertinoExpandableSection(
          header: Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              question,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isDark ? CupertinoColors.white : CupertinoColors.black,
              ),
            ),
          ),
          content: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
            child: Text(
              answer,
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? CupertinoColors.systemGrey
                    : CupertinoColors.systemGrey2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
