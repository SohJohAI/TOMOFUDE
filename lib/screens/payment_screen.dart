import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../providers/payment_provider.dart';
import '../widgets/point_display_widget.dart';
import '../screens/referral_code_screen.dart';
import '../screens/point_history_screen.dart';
import '../screens/subscription_screen.dart';

/// A screen that displays the user's payment information.
///
/// This screen shows the user's points, referral code, and point history.
class PaymentScreen extends StatefulWidget {
  /// Creates a payment screen.
  const PaymentScreen({Key? key}) : super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// Loads the user's payment data.
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final provider = Provider.of<PaymentProvider>(context, listen: false);
      await provider.initialize();
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('ポイント管理'),
      ),
      child: SafeArea(
        child: _isLoading
            ? const Center(child: CupertinoActivityIndicator())
            : _buildContent(),
      ),
    );
  }

  /// Builds the main content of the screen.
  Widget _buildContent() {
    final provider = Provider.of<PaymentProvider>(context);
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Point display
          const PointDisplayWidget(),
          const SizedBox(height: 24),

          // Action buttons
          _buildActionButtons(isDark),
          const SizedBox(height: 24),

          // Subscription button
          _buildSubscriptionButton(isDark),
          const SizedBox(height: 24),

          // Information section
          _buildInfoSection(isDark),
          const SizedBox(height: 24),

          // Error message
          if (provider.errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CupertinoColors.systemRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: CupertinoColors.systemRed.withOpacity(0.3),
                ),
              ),
              child: Text(
                provider.errorMessage!,
                style: const TextStyle(
                  color: CupertinoColors.systemRed,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }

  /// Builds the subscription button.
  Widget _buildSubscriptionButton(bool isDark) {
    return CupertinoButton.filled(
      onPressed: _navigateToSubscriptionScreen,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(CupertinoIcons.star_fill),
          const SizedBox(width: 8),
          const Text('月額プランに加入する'),
        ],
      ),
    );
  }

  /// Builds the action buttons section.
  Widget _buildActionButtons(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CupertinoButton.filled(
          onPressed: _navigateToReferralCodeScreen,
          child: const Text('紹介コードを入力'),
        ),
        const SizedBox(height: 12),
        CupertinoButton(
          padding: const EdgeInsets.symmetric(vertical: 12),
          color: isDark ? const Color(0xFF252525) : CupertinoColors.white,
          onPressed: _navigateToPointHistoryScreen,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(CupertinoIcons.list_bullet),
              const SizedBox(width: 8),
              Text(
                'ポイント履歴を表示',
                style: TextStyle(
                  color: isDark ? CupertinoColors.white : CupertinoColors.black,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Builds the information section.
  Widget _buildInfoSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252525) : const Color(0xFFF5F5F5),
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
          Row(
            children: [
              Icon(
                CupertinoIcons.info_circle,
                color: CupertinoTheme.of(context).primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                'ポイントについて',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? CupertinoColors.white : CupertinoColors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'ポイントはAI執筆支援機能を利用する際に消費されます。'
            '無料ポイントは毎月自動的に付与され、有料ポイントは購入することができます。',
          ),
          const SizedBox(height: 8),
          const Text(
            '友達を紹介すると、あなたと友達の両方に500ポイントが付与されます。',
          ),
          const SizedBox(height: 8),
          const Text(
            '※無料ポイントには有効期限があります。',
            style: TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  /// Navigates to the referral code screen.
  Future<void> _navigateToReferralCodeScreen() async {
    final result = await Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => const ReferralCodeScreen(),
      ),
    );

    if (result == true) {
      // Referral code was applied successfully
      _loadData();
      _showSuccessDialog('紹介コードが適用されました！500ポイントが付与されました。');
    }
  }

  /// Navigates to the point history screen.
  void _navigateToPointHistoryScreen() {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => const PointHistoryScreen(),
      ),
    );
  }

  /// Navigates to the subscription screen.
  void _navigateToSubscriptionScreen() {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => const SubscriptionScreen(),
      ),
    );
  }

  /// Shows a success dialog.
  void _showSuccessDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('成功'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
