import 'package:flutter/material.dart';
import '../services/auth_service_interface.dart';
import '../services/service_locator.dart';

/// Example widget demonstrating Supabase authentication
class SupabaseAuthExample extends StatefulWidget {
  const SupabaseAuthExample({Key? key}) : super(key: key);

  @override
  _SupabaseAuthExampleState createState() => _SupabaseAuthExampleState();
}

class _SupabaseAuthExampleState extends State<SupabaseAuthExample> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;

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
        // Successfully signed up
        _showMessage('Successfully signed up: ${result.user?.email}');
      } else {
        // Sign up failed
        setState(() {
          _errorMessage = 'Sign up failed';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
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
        _showMessage('Successfully signed in: ${result.user?.email}');
      } else {
        // Sign in failed
        setState(() {
          _errorMessage = 'Sign in failed';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Sign out
  Future<void> _signOut() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.signOut();
      _showMessage('Successfully signed out');
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Get current user
  void _getCurrentUser() {
    final user = _authService.currentUser;
    if (user != null) {
      _showMessage('Current user: ${user.email}');
    } else {
      _showMessage('No user is currently signed in');
    }
  }

  /// Show a message to the user
  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Supabase Auth Example'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
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
                onPressed: _isLoading ? null : _signOut,
                child: const Text('Sign Out'),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _getCurrentUser,
                child: const Text('Get Current User'),
              ),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Example of how to use Supabase authentication in code
class SupabaseAuthCodeExample {
  final AuthServiceInterface _authService =
      serviceLocator<AuthServiceInterface>();

  /// Example: Sign up with email and password
  Future<void> signUp(String email, String password) async {
    try {
      final result = await _authService.signUpWithEmail(email, password);
      if (result != null) {
        print('Successfully signed up: ${result.user?.email}');
      }
    } catch (e) {
      print('Error signing up: $e');
    }
  }

  /// Example: Sign in with email and password
  Future<void> signIn(String email, String password) async {
    try {
      final result = await _authService.signInWithEmail(email, password);
      if (result != null) {
        print('Successfully signed in: ${result.user?.email}');
      }
    } catch (e) {
      print('Error signing in: $e');
    }
  }

  /// Example: Get current user
  void getCurrentUser() {
    final user = _authService.currentUser;
    if (user != null) {
      print('Current user: ${user.email}');
    } else {
      print('No user is currently signed in');
    }
  }

  /// Example: Sign out
  Future<void> signOut() async {
    try {
      await _authService.signOut();
      print('Successfully signed out');
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  /// Example: Listen to auth state changes
  void listenToAuthChanges() {
    _authService.authStateChanges.listen((user) {
      if (user != null) {
        print('User is signed in: ${user.email}');
      } else {
        print('User is signed out');
      }
    });
  }
}
