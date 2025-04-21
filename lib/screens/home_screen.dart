import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6E32FF), Color(0xFF3B2EDC)],
            ),
          ),
          child: Row(
            children: [
              const Text('共筆。',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              const Spacer(),
              _NavButton(
                  label: '機能', onTap: () => _scrollTo(context, 'features')),
              _NavButton(
                  label: '料金', onTap: () => _scrollTo(context, 'pricing')),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pushNamed('/transaction_law');
                },
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: const Text(
                  '特商法表記',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () {
                  Navigator.of(context).pushNamed('/auth');
                },
                child: const Text('ログイン'),
              ),
            ],
          ),
        ),
      ),
      body: const _LandingBody(),
    );
  }

  static void _scrollTo(BuildContext context, String key) {
    _SectionKeys.of(context)?.scrollTo(key);
  }
}

class _LandingBody extends StatefulWidget {
  const _LandingBody();

  @override
  State<_LandingBody> createState() => _LandingBodyState();
}

class _LandingBodyState extends State<_LandingBody> {
  late final ScrollController _controller;
  final Map<String, GlobalKey> _keys = {
    'hero': GlobalKey(),
    'features': GlobalKey(),
    'pricing': GlobalKey(),
  };

  @override
  void initState() {
    super.initState();
    _controller = ScrollController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SectionKeys(
      keys: _keys,
      controller: _controller,
      child: SingleChildScrollView(
        controller: _controller,
        child: Column(
          children: [
            _HeroSection(key: _keys['hero']),
            _FeaturesSection(key: _keys['features']),
            _PricingSection(key: _keys['pricing']),
            const _FooterSection(),
          ],
        ),
      ),
    );
  }
}

class _SectionKeys extends InheritedWidget {
  const _SectionKeys(
      {required this.keys, required this.controller, required super.child});
  final Map<String, GlobalKey> keys;
  final ScrollController controller;

  void scrollTo(String name) {
    final key = keys[name];
    if (key != null && key.currentContext != null) {
      Scrollable.ensureVisible(
        key.currentContext!,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    }
  }

  static _SectionKeys? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_SectionKeys>();

  @override
  bool updateShouldNotify(covariant _SectionKeys oldWidget) => false;
}

class _HeroSection extends StatelessWidget {
  const _HeroSection({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Container(
      height: 560,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: width < 800 ? width : 800),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '書くことに、創造の翼を。',
                style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                    color: Colors.white),
              ),
              const SizedBox(height: 16),
              const Text(
                '共筆。はAIと共に物語を紡ぐ、次世代の小説執筆プラットフォーム。\nアイデア出しからプロット構成、本文生成まで、すべてをワンクリックで。',
                style:
                    TextStyle(fontSize: 18, height: 1.6, color: Colors.white70),
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: () {
                  Navigator.of(context).pushNamed('/auth');
                },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF6E32FF),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text('今すぐ使ってみる', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeaturesSection extends StatelessWidget {
  const _FeaturesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
      child: Column(
        children: [
          const Text('主な機能',
              style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold)),
          const SizedBox(height: 40),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 24,
            runSpacing: 24,
            children: const [
              _FeatureCard(
                  icon: Icons.map,
                  title: 'プロットブースター',
                  description: 'ジャンル選択から章構成まで、ステップ形式で骨子を瞬時に生成。'),
              _FeatureCard(
                  icon: Icons.person,
                  title: 'キャラクター設計',
                  description: 'バックストーリーや性格設定もAIがサポート。'),
              _FeatureCard(
                  icon: Icons.auto_stories,
                  title: '本文生成',
                  description: 'AIが文体に合わせて自然な文章を出力。'),
              _FeatureCard(
                  icon: Icons.monetization_on,
                  title: 'ポイント制',
                  description: '使った分だけ支払う料金体系。月額プランもあり。'),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard(
      {required this.icon, required this.title, required this.description});
  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: SizedBox(
        width: 260,
        height: 220,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon,
                  size: 48, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 16),
              Text(title,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(description,
                  style: const TextStyle(fontSize: 14, height: 1.4)),
            ],
          ),
        ),
      ),
    );
  }
}

class _PricingSection extends StatelessWidget {
  const _PricingSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
      color: Colors.black12,
      child: Column(
        children: [
          const Text('料金プラン',
              style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold)),
          const SizedBox(height: 40),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 24,
            runSpacing: 24,
            children: const [
              _PlanCard(
                  name: '梅',
                  price: '¥500/月',
                  points: '約13,000文字',
                  highlight: false),
              _PlanCard(
                  name: '竹',
                  price: '¥1,500/月',
                  points: '約30,000文字',
                  highlight: true),
              _PlanCard(
                  name: '松',
                  price: '¥3,000/月',
                  points: '約100,000文字',
                  highlight: false),
            ],
          ),
          const SizedBox(height: 40),
          // 特商法表記へのリンク
          Center(
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pushNamed('/transaction_law');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              icon: const Icon(Icons.description),
              label: const Text(
                '特定商取引法に基づく表記',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard(
      {required this.name,
      required this.price,
      required this.points,
      this.highlight = false});
  final String name;
  final String price;
  final String points;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: highlight ? 12 : 6,
      color: highlight ? Theme.of(context).colorScheme.primaryContainer : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: SizedBox(
        width: 260,
        height: 260,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name,
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(price, style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 16),
              Text(points, style: const TextStyle(fontSize: 14)),
              const Spacer(),
              FilledButton(
                onPressed: () {
                  Navigator.of(context).pushNamed('/subscription');
                },
                child: const Text('選択'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FooterSection extends StatelessWidget {
  const _FooterSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      color: Colors.black,
      child: const Center(
        child: Text('© 2025 蒼青藍プロダクション | 共筆。',
            style: TextStyle(fontSize: 14, color: Colors.white70)),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      child: Text(label,
          style: const TextStyle(fontSize: 16, color: Colors.white)),
    );
  }
}
