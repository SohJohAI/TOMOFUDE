# Supabase Setup Guide

This guide explains how to set up and use Supabase in the TOMOFUDE application.

## Prerequisites

1. Create a Supabase account at [https://supabase.com](https://supabase.com)
2. Create a new Supabase project

## Configuration

### 1. Get your Supabase credentials

After creating a project in Supabase, you need to get your project URL and API key:

1. Go to your Supabase project dashboard
2. Click on the "Settings" icon in the left sidebar
3. Click on "API" in the settings menu
4. You will find your:
   - **Project URL**: This is your Supabase URL
   - **anon/public** key: This is your Supabase API key

### 2. Update the Supabase service

Open the file `lib/services/supabase_service.dart` and replace the placeholder values with your actual Supabase credentials:

```dart
/// Supabase URL - Replace with your Supabase URL
static const String _supabaseUrl = 'YOUR_SUPABASE_URL';

/// Supabase API Key - Replace with your Supabase API Key
static const String _supabaseKey = 'YOUR_SUPABASE_API_KEY';
```

Replace `'YOUR_SUPABASE_URL'` with your actual Supabase project URL and `'YOUR_SUPABASE_API_KEY'` with your anon/public key.

## Database Setup

### Creating Tables

You can create tables in your Supabase project using the SQL editor or the Table editor in the Supabase dashboard.

Here's an example SQL for creating a basic users table:

```sql
CREATE TABLE public.profiles (
  id UUID REFERENCES auth.users NOT NULL PRIMARY KEY,
  username TEXT UNIQUE,
  display_name TEXT,
  avatar_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);

-- Create a secure RLS policy for the profiles table
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Public profiles are viewable by everyone." ON public.profiles
  FOR SELECT USING (true);

CREATE POLICY "Users can insert their own profile." ON public.profiles
  FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update their own profile." ON public.profiles
  FOR UPDATE USING (auth.uid() = id);
```

## Using Supabase in the App

The app is already set up to use Supabase. The `SupabaseService` class provides methods for authentication and data operations.

### Authentication

```dart
// Get the Supabase service
final supabaseService = serviceLocator<SupabaseServiceInterface>();

// Sign up
await supabaseService.signUpWithEmailAndPassword('user@example.com', 'password123');

// Sign in
await supabaseService.signInWithEmailAndPassword('user@example.com', 'password123');

// Sign out
await supabaseService.signOut();
```

### Database Operations

The `SupabaseExamples` class provides examples of common database operations:

```dart
// Fetch data from a table
final novels = await SupabaseExamples.fetchData('novels');

// Insert data into a table
await SupabaseExamples.insertData('novels', {
  'title': 'My Novel',
  'author_id': supabaseService.currentUser?.id,
  'created_at': DateTime.now().toIso8601String(),
});

// Update data in a table
await SupabaseExamples.updateData('novels', novelId, {
  'title': 'Updated Novel Title',
});

// Delete data from a table
await SupabaseExamples.deleteData('novels', novelId);
```

### Storage Operations

```dart
// Upload a file
final bytes = await File('path/to/file.jpg').readAsBytes();
final path = 'covers/${DateTime.now().millisecondsSinceEpoch}.jpg';
final url = await SupabaseExamples.uploadFile('novel-covers', path, bytes);

// Get a public URL for a file
final publicUrl = SupabaseExamples.getPublicUrl('novel-covers', path);

// Delete a file
await SupabaseExamples.deleteFile('novel-covers', path);
```

## Additional Resources

- [Supabase Documentation](https://supabase.com/docs)
- [Supabase Flutter SDK Documentation](https://supabase.com/docs/reference/dart/introduction)
- [Supabase Flutter Examples](https://github.com/supabase/supabase-flutter)
