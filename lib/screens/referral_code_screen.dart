import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/point_service.dart';

/// A screen for entering and applying referral codes.
///
/// This screen allows users to enter a referral code and apply it
/// to receive bonus points.
class ReferralCodeScreen extends StatefulWidget {
  /// Creates a referral code screen.
  const ReferralCodeScreen({Key? key}) : super(key: key);

  @override
  State<ReferralCodeScreen> createState() => _ReferralCodeScreenState();
}

class _ReferralCodeScreenState extends State<ReferralCodeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _pointService = PointService();

  bool _isLoading = false;
  String? _errorMessage;
  bool _isSuccess = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('紹介コード入力'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildInfoCard(),
                const SizedBox(height: 24),
                _buildCodeInputField(),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  _buildErrorMessage(),
                ],
                if (_isSuccess) ...[
                  const SizedBox(height: 16),
                  _buildSuccessMessage(),
                ],
                const SizedBox(height: 24),
                _buildSubmitButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the information card explaining the referral code system.
  Widget _buildInfoCard() {
    return Card(
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
                  '紹介コードについて',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              '友達から紹介コードを受け取った場合は、こちらから入力してください。'
              '紹介コードを使用すると、あなたに500ポイント、紹介した友達に1500ポイントが付与されます。',
            ),
            const SizedBox(height: 8),
            const Text(
              '※紹介コードは1アカウントにつき1回のみ使用できます。',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the referral code input field.
  Widget _buildCodeInputField() {
    return TextFormField(
      controller: _codeController,
      decoration: InputDecoration(
        labelText: '紹介コード',
        hintText: '8桁の英数字（例: ABC12345）',
        prefixIcon: const Icon(Icons.code),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        suffixIcon: IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () => _codeController.clear(),
          tooltip: 'クリア',
        ),
      ),
      textCapitalization: TextCapitalization.characters,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9]')),
        LengthLimitingTextInputFormatter(8),
      ],
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '紹介コードを入力してください';
        }
        if (value.length != 8) {
          return '紹介コードは8桁です';
        }
        if (!RegExp(r'^[A-Z0-9]{8}$').hasMatch(value)) {
          return '無効な紹介コードです';
        }
        return null;
      },
      onChanged: (_) {
        // Clear error and success messages when the input changes
        if (_errorMessage != null || _isSuccess) {
          setState(() {
            _errorMessage = null;
            _isSuccess = false;
          });
        }
      },
      enabled: !_isLoading,
      autovalidateMode: AutovalidateMode.onUserInteraction,
    );
  }

  /// Builds the error message display.
  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(color: Colors.red.shade700),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the success message display.
  Widget _buildSuccessMessage() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, color: Colors.green.shade700),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              '紹介コードが適用されました！500ポイントが付与されました。',
              style: TextStyle(color: Colors.green),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the submit button.
  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _applyReferralCode,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: _isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Text('コードを適用'),
    );
  }

  /// Applies the entered referral code.
  Future<void> _applyReferralCode() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _isSuccess = false;
    });

    try {
      final code = _codeController.text.trim().toUpperCase();
      final success = await _pointService.applyReferralCode(code);

      setState(() {
        _isLoading = false;
        _isSuccess = success;
        if (!success) {
          _errorMessage = '紹介コードの適用に失敗しました。';
        }
      });

      if (success) {
        // Show a snackbar
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('紹介ボーナスが適用されました！'),
              backgroundColor: Colors.green,
            ),
          );

          // Wait a moment before popping the screen
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              Navigator.pop(context, true);
            }
          });
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = _getErrorMessage(e);
      });
    }
  }

  /// Gets a user-friendly error message from an exception.
  String _getErrorMessage(dynamic error) {
    final message = error.toString();

    if (message.contains('User not authenticated')) {
      return 'ログインが必要です。';
    }

    if (message.contains('Invalid referral code')) {
      return '無効な紹介コードです。';
    }

    if (message.contains('Referral code is inactive')) {
      return 'この紹介コードは無効になっています。';
    }

    if (message.contains('Referral code has expired')) {
      return 'この紹介コードは有効期限が切れています。';
    }

    if (message.contains('already used')) {
      return '紹介コードは既に使用されています。';
    }

    return 'エラーが発生しました: $message';
  }
}
