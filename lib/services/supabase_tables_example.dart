import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'service_locator.dart';
import 'supabase_service_interface.dart';

/// Examples of how to use the Supabase tables for TOMOFUDE application
class SupabaseTablesExample {
  /// Get the Supabase service
  static final SupabaseServiceInterface _supabaseService =
      serviceLocator<SupabaseServiceInterface>();

  /// Get the Supabase client
  static SupabaseClient get _client => _supabaseService.client;

  /// Get current user ID
  static String? get _currentUserId => _supabaseService.currentUser?.id;

  /// Create a new user record after sign up
  static Future<void> createUserRecord(String email) async {
    if (_currentUserId == null) return;

    // Since we've checked _currentUserId is not null, we can use the non-null assertion
    final userId = _currentUserId!;

    await _client.from('users').insert({
      'id': userId,
      'email': email,
      // plan and points will use default values
    });
  }

  /// Get current user data
  static Future<Map<String, dynamic>?> getCurrentUserData() async {
    if (_currentUserId == null) return null;

    // Since we've checked _currentUserId is not null, we can use the non-null assertion
    final userId = _currentUserId!;

    final response =
        await _client.from('users').select().eq('id', userId).maybeSingle();
    return response;
  }

  /// Update user plan
  static Future<void> updateUserPlan(String plan) async {
    if (_currentUserId == null) return;

    // Since we've checked _currentUserId is not null, we can use the non-null assertion
    final userId = _currentUserId!;

    await _client.from('users').update({
      'plan': plan,
    }).eq('id', userId);
  }

  /// Update user points
  static Future<void> updateUserPoints(int points) async {
    if (_currentUserId == null) return;

    // Since we've checked _currentUserId is not null, we can use the non-null assertion
    final userId = _currentUserId!;

    await _client.from('users').update({
      'points': points,
    }).eq('id', userId);
  }

  /// Create a new project
  static Future<String?> createProject(String title, String description) async {
    if (_currentUserId == null) return null;

    // Generate a new UUID for the project
    final projectId = _generateUuid();

    // Since we've checked _currentUserId is not null, we can use the non-null assertion
    final userId = _currentUserId!;

    await _client.from('projects').insert({
      'id': projectId,
      'user_id': userId,
      'title': title,
      'description': description,
    });

    return projectId;
  }

  /// Get all projects for current user
  static Future<List<Map<String, dynamic>>> getUserProjects() async {
    if (_currentUserId == null) return [];

    // Since we've checked _currentUserId is not null, we can use the non-null assertion
    final userId = _currentUserId!;

    final response = await _client
        .from('projects')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return response;
  }

  /// Get a specific project
  static Future<Map<String, dynamic>?> getProject(String projectId) async {
    final response = await _client
        .from('projects')
        .select()
        .eq('id', projectId)
        .maybeSingle();
    return response;
  }

  /// Update a project
  static Future<void> updateProject(
      String projectId, String title, String description) async {
    await _client.from('projects').update({
      'title': title,
      'description': description,
    }).eq('id', projectId);
  }

  /// Delete a project
  static Future<void> deleteProject(String projectId) async {
    await _client.from('projects').delete().eq('id', projectId);
  }

  /// Add plot data to a project
  static Future<String?> addPlotData(
      String projectId, String type, String content) async {
    // Generate a new UUID for the plot data
    final plotDataId = _generateUuid();

    await _client.from('plot_data').insert({
      'id': plotDataId,
      'project_id': projectId,
      'type': type,
      'content': content,
    });

    return plotDataId;
  }

  /// Get all plot data for a project
  static Future<List<Map<String, dynamic>>> getProjectPlotData(
      String projectId) async {
    final response = await _client
        .from('plot_data')
        .select()
        .eq('project_id', projectId)
        .order('created_at', ascending: true);
    return response;
  }

  /// Get plot data of a specific type
  static Future<List<Map<String, dynamic>>> getPlotDataByType(
      String projectId, String type) async {
    final response = await _client
        .from('plot_data')
        .select()
        .eq('project_id', projectId)
        .eq('type', type)
        .order('created_at', ascending: true);
    return response;
  }

  /// Update plot data
  static Future<void> updatePlotData(String plotDataId, String content) async {
    await _client.from('plot_data').update({
      'content': content,
    }).eq('id', plotDataId);
  }

  /// Delete plot data
  static Future<void> deletePlotData(String plotDataId) async {
    await _client.from('plot_data').delete().eq('id', plotDataId);
  }

  /// Generate a UUID
  static String _generateUuid() {
    // Use the uuid package to generate a UUID
    const uuid = Uuid();
    return uuid.v4();
  }
}
