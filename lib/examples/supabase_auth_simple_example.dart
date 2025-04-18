import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// A simple example demonstrating Supabase authentication
/// based on the user's requested code snippets
class SupabaseAuthSimpleExample extends StatefulWidget {
  const SupabaseAuthSimpleExample({Key? key}) : super(key: key);

  @override
  _SupabaseAuthSimpleExampleState createState() =>
      _SupabaseAuthSimpleExampleState();
}

class _SupabaseAuthSimpleExampleState extends State<SupabaseAuthSimpleExample> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _message;
  bool _isLoading = false;

  // Get the Supabase client directly as shown in the user's example
  final supabase = Supabase.instance.client;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Sign up with email and password
  Future<void> _signUp() async {
    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      // サインアップ (Sign up)
      final response = await supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (response.user != null) {
        setState(() {
          _message = 'Successfully signed up: ${response.user!.email}';
        });
      } else {
        setState(() {
          _message = 'Sign up failed';
        });
      }
    } catch (e) {
      setState(() {
        _message = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Sign in with email and password
  Future<void> _signIn() async {
    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      // ログイン (Login)
      final response = await supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (response.user != null) {
        setState(() {
          _message = 'Successfully signed in: ${response.user!.email}';
        });
      } else {
        setState(() {
          _message = 'Sign in failed';
        });
      }
    } catch (e) {
      setState(() {
        _message = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Get current user
  void _getCurrentUser() {
    // 現在のユーザー (Current user)
    final user = supabase.auth.currentUser;

    setState(() {
      if (user != null) {
        _message = 'Current user: ${user.email}';
      } else {
        _message = 'No user is currently signed in';
      }
    });
  }

  /// Sign out
  Future<void> _signOut() async {
    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      // ログアウト (Logout)
      await supabase.auth.signOut();
      setState(() {
        _message = 'Successfully signed out';
      });
    } catch (e) {
      setState(() {
        _message = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Supabase Auth Simple Example'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
              ),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            if (_message != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  _message!,
                  style: TextStyle(
                    color:
                        _message!.contains('Error') ? Colors.red : Colors.green,
                  ),
                ),
              ),
            ElevatedButton(
              onPressed: _isLoading ? null : _signUp,
              child: const Text('Sign Up'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _isLoading ? null : _signIn,
              child: const Text('Sign In'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _getCurrentUser,
              child: const Text('Get Current User'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _isLoading ? null : _signOut,
              child: const Text('Sign Out'),
            ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}

/// Code snippets from the user's request
class SupabaseAuthSnippets {
  // Get the Supabase client
  final supabase = Supabase.instance.client;

  void demonstrateAuthSnippets() async {
    // Example email and password
    final email = 'user@example.com';
    final password = 'password123';

    // サインアップ (Sign up)
    await supabase.auth.signUp(email: email, password: password);

    // ログイン (Login)
    await supabase.auth.signInWithPassword(email: email, password: password);

    // 現在のユーザー (Current user)
    final user = supabase.auth.currentUser;
    print('Current user: ${user?.email}');

    // ログアウト (Logout)
    await supabase.auth.signOut();
  }
}
