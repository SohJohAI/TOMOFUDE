import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../services/auth_service_interface.dart';
import '../services/service_locator.dart';

/// A customized authentication screen for the app.
///
/// This screen provides a user-friendly interface for signing up and signing in.
class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;
  bool _isSignUp = false; // Toggle between sign in and sign up
  bool _obscurePassword = true; // Toggle password visibility

  // Get the auth service from the service locator
  final AuthServiceInterface _authService =
      serviceLocator<AuthServiceInterface>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Sign up with email and password
  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _authService.signUpWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (result != null) {
        if (result.user == null) {
          // ユーザーがnullの場合はメール確認が必要
          _showMessage('登録が完了しました。確認メールをご確認ください。');
        } else {
          // Successfully signed up and user is available
          _showMessage('登録が完了しました: ${result.user?.email}');
        }
      } else {
        // Sign up failed
        setState(() {
          _errorMessage = '登録に失敗しました';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = _formatErrorMessage(e.toString());
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Sign in with email and password
  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _authService.signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (result != null) {
        // Successfully signed in
        _showMessage('ログインしました: ${result.user?.email}');
      } else {
        // Sign in failed
        setState(() {
          _errorMessage = 'ログインに失敗しました';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = _formatErrorMessage(e.toString());
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Format error message to be more user-friendly
  String _formatErrorMessage(String message) {
    if (message.contains('Invalid login credentials')) {
      return 'メールアドレスまたはパスワードが正しくありません';
    } else if (message.contains('Email not confirmed')) {
      return 'メールアドレスが確認されていません。メールをご確認ください';
    } else if (message.contains('User already registered')) {
      return 'このメールアドレスは既に登録されています';
    } else if (message.contains('Password should be at least 6 characters')) {
      return 'パスワードは6文字以上である必要があります';
    } else if (message.contains('Invalid email')) {
      return '有効なメールアドレスを入力してください';
    }
    return message;
  }

  /// Show a message to the user
  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    final primaryColor = CupertinoTheme.of(context).primaryColor;

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('共筆。（TOMOFUDE）'),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // App logo or icon
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32.0),
                  child: Icon(
                    CupertinoIcons.book,
                    size: 80,
                    color: primaryColor,
                  ),
                ),

                // Title
                Text(
                  _isSignUp ? '新規登録' : 'ログイン',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 24),

                // Email field
                CupertinoTextField(
                  controller: _emailController,
                  placeholder: 'メールアドレス',
                  keyboardType: TextInputType.emailAddress,
                  prefix: const Padding(
                    padding: EdgeInsets.only(left: 10),
                    child: Icon(CupertinoIcons.mail),
                  ),
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isDark
                          ? CupertinoColors.systemGrey
                          : CupertinoColors.systemGrey4,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  onEditingComplete: () => FocusScope.of(context).nextFocus(),
                ),

                const SizedBox(height: 16),

                // Password field
                CupertinoTextField(
                  controller: _passwordController,
                  placeholder: 'パスワード',
                  obscureText: _obscurePassword,
                  prefix: const Padding(
                    padding: EdgeInsets.only(left: 10),
                    child: Icon(CupertinoIcons.lock),
                  ),
                  suffix: Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: Icon(
                        _obscurePassword
                            ? CupertinoIcons.eye
                            : CupertinoIcons.eye_slash,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isDark
                          ? CupertinoColors.systemGrey
                          : CupertinoColors.systemGrey4,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  onEditingComplete: _isSignUp ? _signUp : _signIn,
                ),

                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                          color: CupertinoColors.destructiveRed),
                      textAlign: TextAlign.center,
                    ),
                  ),

                const SizedBox(height: 24),

                // Sign in/up button
                CupertinoButton.filled(
                  onPressed:
                      _isLoading ? null : (_isSignUp ? _signUp : _signIn),
                  child: _isLoading
                      ? const CupertinoActivityIndicator(
                          color: CupertinoColors.white)
                      : Text(_isSignUp ? '登録する' : 'ログインする'),
                ),

                const SizedBox(height: 16),

                // Toggle between sign in and sign up
                CupertinoButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          setState(() {
                            _isSignUp = !_isSignUp;
                            _errorMessage = null;
                          });
                        },
                  child: Text(
                    _isSignUp ? 'アカウントをお持ちの方はこちら' : '新規登録はこちら',
                    style: TextStyle(color: primaryColor),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
