# Supabase Authentication Guide

This guide explains how to use Supabase authentication in your Flutter application.

## Overview

The implementation provides the following authentication features:

1. Email + password sign-up
2. Email + password login
3. Getting current user information
4. Logout functionality

## Implementation Details

The authentication functionality is implemented using the following components:

1. `SupabaseService` - Handles communication with Supabase
2. `SupabaseAuthService` - Implements the `AuthServiceInterface` using Supabase
3. `SupabaseAuthService_web` - Web-specific implementation for Supabase authentication

## How to Use

### Basic Authentication Operations

```dart
// Get the auth service from the service locator
final authService = serviceLocator<AuthServiceInterface>();

// Sign up with email and password
final result = await authService.signUpWithEmail('user@example.com', 'password123');
if (result != null) {
  print('Successfully signed up: ${result.user?.email}');
}

// Sign in with email and password
final result = await authService.signInWithEmail('user@example.com', 'password123');
if (result != null) {
  print('Successfully signed in: ${result.user?.email}');
}

// Get current user
final user = authService.currentUser;
if (user != null) {
  print('Current user: ${user.email}');
} else {
  print('No user is currently signed in');
}

// Sign out
await authService.signOut();
```

### Listening to Authentication State Changes

You can listen to authentication state changes to update your UI when the user signs in or out:

```dart
authService.authStateChanges.listen((user) {
  if (user != null) {
    print('User is signed in: ${user.email}');
    // Update UI for signed-in state
  } else {
    print('User is signed out');
    // Update UI for signed-out state
  }
});
```

## Example Widget

An example widget demonstrating Supabase authentication is available in `lib/examples/supabase_auth_example.dart`. This widget provides a simple UI for signing up, signing in, signing out, and getting the current user.

To use this widget in your app:

```dart
import 'package:your_app/examples/supabase_auth_example.dart';

// In your build method
@override
Widget build(BuildContext context) {
  return const SupabaseAuthExample();
}
```

## Error Handling

The authentication methods use the app's error handler to provide consistent error handling. Errors are caught and can be displayed to the user.

```dart
try {
  await authService.signInWithEmail(email, password);
} catch (e) {
  // Handle error
  print('Error signing in: $e');
}
```

## User Data

When a user signs up, a record is created in the Supabase `users` table with the following default values:

- `email`: The user's email address
- `plan`: 'free'
- `points`: 300

You can update this data using the `updateUserData` method in the `SupabaseService`:

```dart
await supabaseService.updateUserData({
  'plan': 'premium',
  'points': 500,
});
```

## Web Support

The implementation includes web-specific support through the `supabase_auth_service_web.dart` file. The service locator automatically uses the appropriate implementation based on the platform.

## Additional Features

The current implementation focuses on email + password authentication. Additional authentication methods like Google Sign-In could be added in the future.
