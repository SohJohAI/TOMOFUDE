import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/point_history.dart';
import '../services/point_service.dart';

/// A screen that displays the user's point history.
///
/// This screen shows a list of point transactions, including
/// registration bonuses, referral bonuses, and point consumption.
class PointHistoryScreen extends StatefulWidget {
  /// Creates a point history screen.
  const PointHistoryScreen({Key? key}) : super(key: key);

  @override
  State<PointHistoryScreen> createState() => _PointHistoryScreenState();
}

class _PointHistoryScreenState extends State<PointHistoryScreen> {
  final _pointService = PointService();
  bool _isLoading = true;
  List<PointHistory> _history = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  /// Loads the point history from the service.
  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final history = await _pointService.getPointHistory();
      setState(() {
        _history = history;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ポイント履歴'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadHistory,
            tooltip: '更新',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  /// Builds the body of the screen based on the current state.
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
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
              _errorMessage!,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadHistory,
              child: const Text('再読み込み'),
            ),
          ],
        ),
      );
    }

    if (_history.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.history, color: Colors.grey, size: 48),
            const SizedBox(height: 16),
            Text(
              'ポイント履歴がありません',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text('ポイントを獲得または使用すると、ここに履歴が表示されます'),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _history.length,
      itemBuilder: (context, index) {
        return _buildHistoryItem(_history[index]);
      },
    );
  }

  /// Builds a list item for a point history entry.
  Widget _buildHistoryItem(PointHistory history) {
    // Format the timestamp
    final dateFormat = DateFormat('yyyy/MM/dd HH:mm');
    final formattedDate = dateFormat.format(history.timestamp);

    // Determine the icon and color based on the type
    IconData icon;
    Color color;

    switch (history.type) {
      case PointHistory.registerBonus:
        icon = Icons.person_add;
        color = Colors.blue;
        break;
      case PointHistory.referralBonus:
        icon = Icons.people;
        color = Colors.purple;
        break;
      case PointHistory.referralUsed:
        icon = Icons.person_add_alt_1;
        color = Colors.indigo;
        break;
      case PointHistory.pointConsumption:
        icon = Icons.shopping_cart;
        color = Colors.red;
        break;
      case PointHistory.monthlyReset:
        icon = Icons.refresh;
        color = Colors.orange;
        break;
      default:
        icon = Icons.swap_horiz;
        color = Colors.grey;
    }

    // Format the amount with a sign
    final amountText =
        history.amount >= 0 ? '+${history.amount}' : '${history.amount}';
    final amountColor = history.amount >= 0 ? Colors.green : Colors.red;

    // Check if the history item is expired
    final isExpired = history.expiryDate != null &&
        history.expiryDate!.isBefore(DateTime.now());

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color),
        ),
        title: Text(
          history.description,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isExpired ? Colors.grey : null,
            decoration: isExpired ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Text(formattedDate),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$amountText P',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isExpired ? Colors.grey : amountColor,
                fontSize: 16,
              ),
            ),
            if (isExpired)
              const Padding(
                padding: EdgeInsets.only(left: 4),
                child: Tooltip(
                  message: '有効期限切れ',
                  child: Icon(Icons.access_time, color: Colors.grey, size: 16),
                ),
              ),
          ],
        ),
        onTap: () => _showHistoryDetails(history),
      ),
    );
  }

  /// Shows a dialog with details about a point history entry.
  void _showHistoryDetails(PointHistory history) {
    final dateFormat = DateFormat('yyyy年MM月dd日 HH:mm:ss');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ポイント履歴詳細'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('種類', _getTypeLabel(history.type)),
            _buildDetailRow('説明', history.description),
            _buildDetailRow('ポイント', '${history.amount} P'),
            _buildDetailRow('日時', dateFormat.format(history.timestamp)),
            if (history.expiryDate != null)
              _buildDetailRow(
                '有効期限',
                dateFormat.format(history.expiryDate!),
                isExpired: history.expiryDate!.isBefore(DateTime.now()),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  /// Builds a row for the details dialog.
  Widget _buildDetailRow(String label, String value, {bool isExpired = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: isExpired ? Colors.red : null,
                decoration: isExpired ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Gets a user-friendly label for a point history type.
  String _getTypeLabel(String type) {
    switch (type) {
      case PointHistory.registerBonus:
        return '登録ボーナス';
      case PointHistory.referralBonus:
        return '紹介ボーナス';
      case PointHistory.referralUsed:
        return '紹介コード使用';
      case PointHistory.pointConsumption:
        return 'ポイント消費';
      case PointHistory.monthlyReset:
        return '月次リセット';
      default:
        return type;
    }
  }
}
