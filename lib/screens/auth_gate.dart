import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_screen.dart';
import 'novel_list_screen.dart';

/// A widget that redirects to the appropriate screen based on authentication state.
///
/// If the user is authenticated, it shows the NovelListScreen.
/// If the user is not authenticated, it shows the AuthScreen.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    // Listen for auth state changes to update the UI
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      // Trigger a rebuild when auth state changes
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Check if the user is authenticated
    final session = Supabase.instance.client.auth.currentSession;

    // Debug information
    print('AuthGate: session is $session');
    print('AuthGate: user is ${Supabase.instance.client.auth.currentUser}');

    if (session == null) {
      // User is not authenticated, show the auth screen
      return const AuthScreen();
    } else {
      // User is authenticated, show the main app screen
      return const NovelListScreen();
    }
  }
}
