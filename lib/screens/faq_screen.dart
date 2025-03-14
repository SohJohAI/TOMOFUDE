import 'package:flutter/material.dart';

class FAQScreen extends StatelessWidget {
  const FAQScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('よくある質問'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // タイトルと説明
          const Text(
            'よくある質問 (FAQ)',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '「共筆。」アプリについてよくある質問と回答をまとめました。',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
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
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey.shade800
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'お問い合わせ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'ご質問やご意見がありましたら、下記のメールアドレスまでご連絡ください。',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey.shade300
                        : Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.email,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    SelectableText(
                      'sohjohai@gmail.com',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
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
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white70
                    : Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // FAQ項目ウィジェット
  Widget _buildFAQItem(
    BuildContext context, {
    required String question,
    required String answer,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey.shade700
              : Colors.grey.shade300,
        ),
      ),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              answer,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey.shade300
                    : Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
