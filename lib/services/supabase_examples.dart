import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'service_locator.dart';
import 'supabase_service_interface.dart';

/// Examples of how to use the Supabase service
class SupabaseExamples {
  /// Get the Supabase service
  static final SupabaseServiceInterface _supabaseService =
      serviceLocator<SupabaseServiceInterface>();

  /// Get the Supabase client
  static SupabaseClient get _client => _supabaseService.client;

  /// Example: Fetch data from a table
  static Future<List<Map<String, dynamic>>> fetchData(String tableName) async {
    final response = await _client.from(tableName).select();
    return response;
  }

  /// Example: Insert data into a table
  static Future<void> insertData(
      String tableName, Map<String, dynamic> data) async {
    await _client.from(tableName).insert(data);
  }

  /// Example: Update data in a table
  static Future<void> updateData(
      String tableName, String id, Map<String, dynamic> data) async {
    await _client.from(tableName).update(data).eq('id', id);
  }

  /// Example: Delete data from a table
  static Future<void> deleteData(String tableName, String id) async {
    await _client.from(tableName).delete().eq('id', id);
  }

  /// Example: Query data with filters
  static Future<List<Map<String, dynamic>>> queryData(
      String tableName, String column, dynamic value) async {
    final response = await _client.from(tableName).select().eq(column, value);
    return response;
  }

  /// Example: Fetch user profile
  static Future<Map<String, dynamic>?> fetchUserProfile() async {
    final userId = _supabaseService.currentUser?.id;
    if (userId == null) return null;

    final response =
        await _client.from('profiles').select().eq('id', userId).single();
    return response;
  }

  /// Example: Upload a file to storage
  static Future<String> uploadFile(
      String bucket, String path, Uint8List fileBytes) async {
    final response = await _client.storage.from(bucket).uploadBinary(
          path,
          fileBytes,
        );
    return response;
  }

  /// Example: Get a public URL for a file
  static String getPublicUrl(String bucket, String path) {
    return _client.storage.from(bucket).getPublicUrl(path);
  }

  /// Example: Delete a file from storage
  static Future<void> deleteFile(String bucket, String path) async {
    await _client.storage.from(bucket).remove([path]);
  }

  /// Example: Create a realtime subscription
  /// Note: This is a simplified example. Refer to Supabase documentation
  /// for the most up-to-date realtime API usage.
  static RealtimeChannel createRealtimeSubscription(String channelName) {
    final channel = _client.channel(channelName);
    channel.subscribe();
    return channel;
  }

  /// Example: Execute a Postgres function
  static Future<dynamic> executeFunction(
      String functionName, Map<String, dynamic> params) async {
    final response = await _client.rpc(functionName, params: params);
    return response;
  }
}
