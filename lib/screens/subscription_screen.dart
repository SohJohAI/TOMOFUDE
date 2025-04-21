import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../models/subscription_plan.dart';
import '../providers/payment_provider.dart';
import 'transaction_law_screen.dart';

/// A screen that displays subscription plans and allows users to subscribe.
///
/// This screen shows the available subscription plans (梅・竹・松) and allows
/// users to subscribe to a plan using Stripe.
class SubscriptionScreen extends StatefulWidget {
  /// Creates a subscription screen.
  const SubscriptionScreen({Key? key}) : super(key: key);

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// Loads the user's subscription data.
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final provider = Provider.of<PaymentProvider>(context, listen: false);
      await provider.loadCurrentPlan();
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
        middle: Text('サブスクリプション'),
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
          // Current plan
          if (provider.currentPlan != null) ...[
            _buildCurrentPlanCard(provider.currentPlan!, isDark),
            const SizedBox(height: 24),
          ],

          // Available plans
          const Text(
            '月額プラン',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...SubscriptionPlan.all
              .map((plan) => _buildPlanCard(plan, provider, isDark))
              .toList(),
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

  /// Builds a card for the current subscription plan.
  Widget _buildCurrentPlanCard(SubscriptionPlan plan, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF0F8FF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: CupertinoTheme.of(context).primaryColor,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                CupertinoIcons.checkmark_seal_fill,
                color: CupertinoTheme.of(context).primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                '現在のプラン',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: CupertinoTheme.of(context).primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            plan.name,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(plan.description),
          const SizedBox(height: 8),
          Text(
            '¥${plan.priceJpy}/月',
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 16),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(vertical: 12),
            color: CupertinoColors.systemRed,
            onPressed: _confirmCancelSubscription,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.xmark_circle),
                SizedBox(width: 8),
                Text('サブスクリプションをキャンセル'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a card for a subscription plan.
  Widget _buildPlanCard(
      SubscriptionPlan plan, PaymentProvider provider, bool isDark) {
    final isCurrentPlan = provider.currentPlan?.id == plan.id;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: isDark ? const Color(0xFF252525) : CupertinoColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isCurrentPlan
              ? CupertinoTheme.of(context).primaryColor
              : isDark
                  ? CupertinoColors.systemGrey.darkColor
                  : CupertinoColors.systemGrey4,
          width: isCurrentPlan ? 2 : 0.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              plan.name,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isCurrentPlan
                    ? CupertinoTheme.of(context).primaryColor
                    : null,
              ),
            ),
            const SizedBox(height: 8),
            Text(plan.description),
            const SizedBox(height: 8),
            Text(
              '¥${plan.priceJpy}/月',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              '毎月${plan.pointsPerMonth}ポイント付与',
              style: const TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: CupertinoButton(
                padding: const EdgeInsets.symmetric(vertical: 12),
                color: isCurrentPlan
                    ? CupertinoColors.systemGrey
                    : CupertinoTheme.of(context).primaryColor,
                onPressed: isCurrentPlan || provider.isProcessingPayment
                    ? null
                    : () => _subscribeToPlan(plan),
                child: Text(
                  isCurrentPlan ? '現在のプラン' : '購入する',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
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
                'サブスクリプションについて',
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
            'サブスクリプションに加入すると、毎月自動的にポイントが付与されます。'
            'ポイントはAI執筆支援機能を利用する際に消費されます。',
          ),
          const SizedBox(height: 8),
          const Text(
            '※サブスクリプションは自動更新されます。キャンセルしない限り、毎月自動的に課金されます。',
            style: TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '※サブスクリプションのキャンセルは、次回の更新日までに行う必要があります。',
            style: TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                CupertinoPageRoute(
                  builder: (context) => const TransactionLawScreen(),
                ),
              );
            },
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.doc_text,
                  color: CupertinoTheme.of(context).primaryColor,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  '特定商取引法に基づく表記',
                  style: TextStyle(
                    color: CupertinoTheme.of(context).primaryColor,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Subscribe to a plan.
  Future<void> _subscribeToPlan(SubscriptionPlan plan) async {
    final provider = Provider.of<PaymentProvider>(context, listen: false);

    final success = await provider.subscribeToPlan(plan);

    if (success && mounted) {
      _showSuccessDialog('サブスクリプションの購入が完了しました！');
    }
  }

  /// Confirm cancellation of the subscription.
  Future<void> _confirmCancelSubscription() async {
    final result = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('サブスクリプションのキャンセル'),
        content: const Text(
          'サブスクリプションをキャンセルしますか？\n'
          'キャンセルすると、次回の更新日以降は課金されなくなります。',
        ),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('キャンセルする'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('戻る'),
          ),
        ],
      ),
    );

    if (result == true) {
      await _cancelSubscription();
    }
  }

  /// Cancel the subscription.
  Future<void> _cancelSubscription() async {
    final provider = Provider.of<PaymentProvider>(context, listen: false);

    final success = await provider.cancelSubscription();

    if (success && mounted) {
      _showSuccessDialog('サブスクリプションのキャンセルが完了しました。\n次回の更新日以降は課金されなくなります。');
    }
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
