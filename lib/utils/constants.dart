// constants.dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Supabase configuration
String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';
String get supabaseFnUrl => dotenv.env['SUPABASE_FN_URL'] ?? '';
