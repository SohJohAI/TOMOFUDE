import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../models/user_point.dart';
import '../services/point_service.dart';

/// A widget that displays the user's point information.
///
/// This widget shows the total points, free points, paid points,
/// and the user's referral code with a share button.
class PointDisplayWidget extends StatelessWidget {
  /// Creates a point display widget.
  const PointDisplayWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final pointService = PointService();

    return FutureBuilder<UserPoint?>(
      future: pointService.getUserPoint(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (snapshot.hasError) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'エラーが発生しました',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Refresh the widget
                      (context as Element).markNeedsBuild();
                    },
                    child: const Text('再読み込み'),
                  ),
                ],
              ),
            ),
          );
        }

        final userPoint = snapshot.data;

        if (userPoint == null) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Icon(Icons.account_circle_outlined, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'ポイント情報がありません',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text('ログインするとポイントが表示されます'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Navigate to login screen
                      // This will be implemented later
                    },
                    child: const Text('ログイン'),
                  ),
                ],
              ),
            ),
          );
        }

        // Calculate days until free points reset
        final now = DateTime.now();
        final nextMonth = DateTime(now.year, now.month + 1, 1);
        final daysUntilReset = nextMonth.difference(now).inDays;

        return Card(
          elevation: 4,
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
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: () {
                        // Refresh the widget
                        (context as Element).markNeedsBuild();
                      },
                      tooltip: '更新',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${userPoint.point} P',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                ),
                const SizedBox(height: 16),
                _buildPointTypeRow(
                  context,
                  '無料ポイント',
                  userPoint.freePoint,
                  Icons.card_giftcard,
                  Colors.green,
                ),
                const SizedBox(height: 4),
                Text(
                  '※無料ポイントは毎月1日にリセットされます（残り$daysUntilReset日）',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.red,
                      ),
                ),
                const SizedBox(height: 8),
                _buildPointTypeRow(
                  context,
                  '有料ポイント',
                  userPoint.paidPoint,
                  Icons.monetization_on,
                  Colors.amber,
                ),
                const Divider(height: 32),
                _buildReferralCodeSection(context, userPoint.referralCode),
                const SizedBox(height: 16),
                Center(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.history),
                    label: const Text('ポイント履歴を見る'),
                    onPressed: () {
                      // Navigate to point history screen
                      // This will be implemented later
                      Navigator.pushNamed(context, '/point-history');
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Builds a row displaying a type of point (free or paid).
  Widget _buildPointTypeRow(
    BuildContext context,
    String label,
    int points,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const Spacer(),
        Text(
          '$points P',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  /// Builds the referral code section with a share button.
  Widget _buildReferralCodeSection(BuildContext context, String referralCode) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '友達招待コード',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  child: Text(
                    referralCode,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontFamily: 'monospace',
                          letterSpacing: 1.5,
                        ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () {
                  Share.share(
                    '「共筆。」で小説を書こう！このコードを使うと500ポイントもらえます: $referralCode',
                  );
                },
                tooltip: '共有',
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '友達がこのコードを使うと、あなたに1500P、友達に500Pが付与されます。',
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}
