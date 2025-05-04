import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../providers/payment_provider.dart';

/// A screen that allows users to enter a referral code.
///
/// This screen provides a form for entering a referral code and
/// a button to apply the code.
class ReferralCodeScreen extends StatefulWidget {
  /// Creates a referral code screen.
  const ReferralCodeScreen({Key? key}) : super(key: key);

  @override
  State<ReferralCodeScreen> createState() => _ReferralCodeScreenState();
}

class _ReferralCodeScreenState extends State<ReferralCodeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('紹介コード入力'),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Information card
                _buildInfoCard(isDark),
                const SizedBox(height: 24),

                // Code input field
                CupertinoTextField(
                  controller: _codeController,
                  placeholder: '紹介コードを入力（例：ABCD1234）',
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isDark
                          ? CupertinoColors.systemGrey.darkColor
                          : CupertinoColors.systemGrey4,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  style: TextStyle(
                    color:
                        isDark ? CupertinoColors.white : CupertinoColors.black,
                  ),
                  autocorrect: false,
                  textCapitalization: TextCapitalization.characters,
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: CupertinoColors.systemRed,
                      fontSize: 14,
                    ),
                  ),
                ],
                const SizedBox(height: 24),

                // Apply button
                _isSubmitting
                    ? const Center(child: CupertinoActivityIndicator())
                    : CupertinoButton.filled(
                        onPressed: _applyReferralCode,
                        child: const Text('紹介コードを適用'),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the information card.
  Widget _buildInfoCard(bool isDark) {
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
                '紹介コードについて',
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
            '友達から紹介コードを受け取った場合は、こちらから入力してください。'
            '紹介コードを適用すると、あなたに500ポイントが付与されます。',
          ),
          const SizedBox(height: 8),
          const Text(
            '※紹介コードは1回のみ使用できます。',
            style: TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  /// Applies the referral code.
  Future<void> _applyReferralCode() async {
    // Validate the code format
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() {
        _errorMessage = '紹介コードを入力してください。';
      });
      return;
    }

    if (!RegExp(r'^[A-Z0-9]{8}$').hasMatch(code)) {
      setState(() {
        _errorMessage = '紹介コードは8桁の英数字で入力してください。';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final provider = Provider.of<PaymentProvider>(context, listen: false);
      final success = await provider.applyReferralCode(code);

      if (success) {
        // Return to the previous screen with success result
        Navigator.pop(context, true);
      } else {
        setState(() {
          _errorMessage = '紹介コードの適用に失敗しました。無効なコードか、すでに使用されています。';
          _isSubmitting = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'エラーが発生しました: ${e.toString()}';
        _isSubmitting = false;
      });
    }
  }
}
