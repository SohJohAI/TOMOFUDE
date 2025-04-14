import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/payment_provider.dart';
import '../models/point_history.dart';

/// A screen that displays the user's point history.
///
/// This screen shows a list of the user's point transactions,
/// including the amount, type, and date.
class PointHistoryScreen extends StatefulWidget {
  /// Creates a point history screen.
  const PointHistoryScreen({Key? key}) : super(key: key);

  @override
  State<PointHistoryScreen> createState() => _PointHistoryScreenState();
}

class _PointHistoryScreenState extends State<PointHistoryScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPointHistory();
  }

  /// Loads the user's point history.
  Future<void> _loadPointHistory() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final provider = Provider.of<PaymentProvider>(context, listen: false);
      await provider.loadPointHistory();
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('ポイント履歴'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(
            CupertinoIcons.refresh,
            size: 22,
          ),
          onPressed: _loadPointHistory,
        ),
      ),
      child: SafeArea(
        child: _buildContent(isDark),
      ),
    );
  }

  /// Builds the main content of the screen.
  Widget _buildContent(bool isDark) {
    if (_isLoading) {
      return const Center(
        child: CupertinoActivityIndicator(),
      );
    }

    final provider = Provider.of<PaymentProvider>(context);
    final history = provider.pointHistory;

    if (history.isEmpty) {
      return _buildEmptyState(isDark);
    }

    return _buildHistoryList(history, isDark);
  }

  /// Builds the empty state when there is no history.
  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.doc_text,
            size: 64,
            color: isDark
                ? CupertinoColors.systemGrey
                : CupertinoColors.systemGrey3,
          ),
          const SizedBox(height: 16),
          Text(
            'ポイント履歴がありません',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? CupertinoColors.white : CupertinoColors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ポイントを獲得または使用すると、ここに履歴が表示されます。',
            style: TextStyle(
              fontSize: 14,
              color: isDark
                  ? CupertinoColors.systemGrey
                  : CupertinoColors.systemGrey2,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Builds the history list.
  Widget _buildHistoryList(List<PointHistory> history, bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: history.length,
      itemBuilder: (context, index) {
        final item = history[index];
        return _buildHistoryItem(item, isDark);
      },
    );
  }

  /// Builds a history item.
  Widget _buildHistoryItem(PointHistory item, bool isDark) {
    final dateFormat = DateFormat('yyyy/MM/dd HH:mm');
    final formattedDate = dateFormat.format(item.timestamp);

    // Determine the color based on the type
    Color typeColor;
    IconData typeIcon;

    if (item.amount > 0) {
      typeColor = CupertinoColors.activeGreen;
      typeIcon = CupertinoIcons.plus_circle;
    } else {
      typeColor = CupertinoColors.systemRed;
      typeIcon = CupertinoIcons.minus_circle;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Type icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: typeColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                typeIcon,
                color: typeColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.description,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? CupertinoColors.white
                          : CupertinoColors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formattedDate,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? CupertinoColors.systemGrey
                          : CupertinoColors.systemGrey2,
                    ),
                  ),
                  if (item.expiryDate != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '有効期限: ${DateFormat('yyyy/MM/dd').format(item.expiryDate!)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: _isExpiringSoon(item.expiryDate!)
                            ? CupertinoColors.systemRed
                            : isDark
                                ? CupertinoColors.systemGrey
                                : CupertinoColors.systemGrey2,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Amount
            Text(
              item.amount > 0 ? '+${item.amount}' : '${item.amount}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: typeColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Checks if the expiry date is soon (within 7 days).
  bool _isExpiringSoon(DateTime expiryDate) {
    final now = DateTime.now();
    final difference = expiryDate.difference(now).inDays;
    return difference <= 7;
  }
}
