import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/payment_provider.dart';
import '../widgets/point_display_widget.dart';
import 'referral_code_screen.dart';
import 'point_history_screen.dart';

/// A screen that displays the user's payment information.
///
/// This screen shows the user's points, referral code, and provides
/// options to view point history and enter a referral code.
class PaymentScreen extends StatefulWidget {
  /// Creates a payment screen.
  const PaymentScreen({Key? key}) : super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _initializeProvider();
      _isInitialized = true;
    }
  }

  /// Initializes the payment provider.
  Future<void> _initializeProvider() async {
    final provider = Provider.of<PaymentProvider>(context, listen: false);
    await provider.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ポイント'),
      ),
      body: Consumer<PaymentProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (provider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'エラーが発生しました',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    provider.errorMessage!,
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _initializeProvider,
                    child: const Text('再読み込み'),
                  ),
                ],
              ),
            );
          }

          if (!provider.isAuthenticated) {
            return _buildUnauthenticatedView();
          }

          return _buildAuthenticatedView(provider);
        },
      ),
    );
  }

  /// Builds the view for unauthenticated users.
  Widget _buildUnauthenticatedView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.account_circle_outlined,
              size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'ログインが必要です',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text('ポイントを利用するにはログインしてください'),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              // Navigate to login screen
              // This will be implemented later
            },
            child: const Text('ログイン'),
          ),
        ],
      ),
    );
  }

  /// Builds the view for authenticated users.
  Widget _buildAuthenticatedView(PaymentProvider provider) {
    return RefreshIndicator(
      onRefresh: _initializeProvider,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Point display widget
            const PointDisplayWidget(),

            const SizedBox(height: 24),

            // Action buttons
            _buildActionButtons(),

            const SizedBox(height: 24),

            // Information cards
            _buildInfoCards(),
          ],
        ),
      ),
    );
  }

  /// Builds the action buttons section.
  Widget _buildActionButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'アクション',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                icon: Icons.history,
                label: 'ポイント履歴',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PointHistoryScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionButton(
                icon: Icons.code,
                label: '紹介コード入力',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ReferralCodeScreen(),
                    ),
                  ).then((applied) {
                    if (applied == true) {
                      _initializeProvider();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('紹介コードが適用されました！'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Builds an action button.
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Column(
        children: [
          Icon(icon),
          const SizedBox(height: 8),
          Text(label),
        ],
      ),
    );
  }

  /// Builds the information cards section.
  Widget _buildInfoCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'ポイントについて',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'ポイントの使い方',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'ポイントは以下の機能で使用できます：\n'
                  '• AIによる小説執筆支援\n'
                  '• プロットブースターの高度な機能\n'
                  '• 感情分析ツール\n'
                  '• その他の有料機能',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.card_giftcard,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '無料ポイントについて',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  '無料ポイントは毎月1日にリセットされます。\n'
                  '未使用の無料ポイントは翌月に繰り越されません。',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.people,
                      color: Colors.purple,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '友達紹介プログラム',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  '友達を招待して、お互いにポイントをゲット！\n'
                  '• あなたの紹介コードを友達に共有\n'
                  '• 友達が登録時にコードを入力\n'
                  '• あなたに1500ポイント、友達に500ポイントが付与されます',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
