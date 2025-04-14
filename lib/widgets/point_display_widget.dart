import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../providers/payment_provider.dart';
import '../models/user_point.dart';

/// A widget that displays the user's point information.
///
/// This widget shows the user's total points, free points, and paid points.
class PointDisplayWidget extends StatelessWidget {
  /// Creates a point display widget.
  const PointDisplayWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PaymentProvider>(context);
    final userPoint = provider.userPoint;
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;

    return Card(
      color: isDark ? const Color(0xFF252525) : CupertinoColors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark
              ? CupertinoColors.systemGrey.darkColor
              : CupertinoColors.systemGrey4,
          width: 0.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ポイント残高',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color:
                        isDark ? CupertinoColors.white : CupertinoColors.black,
                  ),
                ),
                _buildRefreshButton(context, provider),
              ],
            ),
            const SizedBox(height: 16),
            _buildPointDisplay(context, userPoint, isDark),
            const SizedBox(height: 16),
            _buildPointDetails(context, userPoint, isDark),
          ],
        ),
      ),
    );
  }

  /// Builds the refresh button.
  Widget _buildRefreshButton(BuildContext context, PaymentProvider provider) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      child: const Icon(
        CupertinoIcons.refresh,
        size: 20,
      ),
      onPressed: () {
        provider.initialize();
      },
    );
  }

  /// Builds the main point display.
  Widget _buildPointDisplay(
      BuildContext context, UserPoint? userPoint, bool isDark) {
    final total = userPoint?.point ?? 0;

    return Center(
      child: Column(
        children: [
          Text(
            total.toString(),
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: CupertinoTheme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'ポイント',
            style: TextStyle(
              fontSize: 16,
              color: isDark
                  ? CupertinoColors.systemGrey
                  : CupertinoColors.systemGrey2,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the point details section.
  Widget _buildPointDetails(
      BuildContext context, UserPoint? userPoint, bool isDark) {
    final freePoint = userPoint?.freePoint ?? 0;
    final paidPoint = userPoint?.paidPoint ?? 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _buildPointDetailRow(
            context,
            '無料ポイント',
            freePoint.toString(),
            CupertinoColors.activeBlue,
            isDark,
          ),
          const SizedBox(height: 8),
          _buildPointDetailRow(
            context,
            '有料ポイント',
            paidPoint.toString(),
            CupertinoColors.activeGreen,
            isDark,
          ),
          if (userPoint?.referralExpiry != null) ...[
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
            _buildExpiryInfo(context, userPoint!, isDark),
          ],
        ],
      ),
    );
  }

  /// Builds a row in the point details section.
  Widget _buildPointDetailRow(BuildContext context, String label, String value,
      Color valueColor, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isDark
                ? CupertinoColors.systemGrey
                : CupertinoColors.systemGrey2,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  /// Builds the expiry information section.
  Widget _buildExpiryInfo(
      BuildContext context, UserPoint userPoint, bool isDark) {
    final now = DateTime.now();
    final expiry = userPoint.referralExpiry!;
    final daysLeft = expiry.difference(now).inDays;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '紹介ボーナス有効期限',
          style: TextStyle(
            fontSize: 14,
            color: isDark
                ? CupertinoColors.systemGrey
                : CupertinoColors.systemGrey2,
          ),
        ),
        Text(
          '$daysLeft日後',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: daysLeft < 7
                ? CupertinoColors.systemRed
                : CupertinoColors.systemOrange,
          ),
        ),
      ],
    );
  }
}
