import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// Service for interacting with Supabase database tables
class SupabaseDatabaseService {
  /// Singleton instance
  static final SupabaseDatabaseService _instance =
      SupabaseDatabaseService._internal();

  /// Factory constructor
  factory SupabaseDatabaseService() => _instance;

  /// Private constructor
  SupabaseDatabaseService._internal();

  /// Get the Supabase client
  SupabaseClient get _client => Supabase.instance.client;

  /// Get current user ID
  String? get _currentUserId => _client.auth.currentUser?.id;

  /// Check if user is authenticated
  bool get isAuthenticated => _currentUserId != null;

  // ==================== User Operations ====================

  /// Get current user data
  Future<Map<String, dynamic>?> getCurrentUserData() async {
    if (_currentUserId == null) return null;

    // Since we've checked _currentUserId is not null, we can use the non-null assertion
    final userId = _currentUserId!;

    final response =
        await _client.from('users').select().eq('id', userId).maybeSingle();
    return response;
  }

  /// Update user plan
  Future<void> updateUserPlan(String plan) async {
    if (_currentUserId == null) return;

    // Since we've checked _currentUserId is not null, we can use the non-null assertion
    final userId = _currentUserId!;

    await _client.from('users').update({
      'plan': plan,
    }).eq('id', userId);
  }

  /// Update user points
  Future<void> updateUserPoints(int points) async {
    if (_currentUserId == null) return;

    // Since we've checked _currentUserId is not null, we can use the non-null assertion
    final userId = _currentUserId!;

    await _client.from('users').update({
      'points': points,
    }).eq('id', userId);
  }

  // ==================== Project Operations ====================

  /// Create a new project
  Future<String?> createProject(String title, String description) async {
    if (_currentUserId == null) return null;

    // Since we've checked _currentUserId is not null, we can use the non-null assertion
    final userId = _currentUserId!;

    // Generate a new UUID for the project
    final projectId = const Uuid().v4();

    await _client.from('projects').insert({
      'id': projectId,
      'user_id': userId,
      'title': title,
      'description': description,
    });

    return projectId;
  }

  /// Get all projects for current user
  Future<List<Map<String, dynamic>>> getUserProjects() async {
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
  Future<Map<String, dynamic>?> getProject(String projectId) async {
    final response = await _client
        .from('projects')
        .select()
        .eq('id', projectId)
        .maybeSingle();
    return response;
  }

  /// Update a project
  Future<void> updateProject(
      String projectId, String title, String description) async {
    await _client.from('projects').update({
      'title': title,
      'description': description,
    }).eq('id', projectId);
  }

  /// Delete a project
  Future<void> deleteProject(String projectId) async {
    await _client.from('projects').delete().eq('id', projectId);
  }

  // ==================== Plot Data Operations ====================

  /// Add plot data to a project
  Future<String?> addPlotData(
      String projectId, String type, String content) async {
    // Generate a new UUID for the plot data
    final plotDataId = const Uuid().v4();

    await _client.from('plot_data').insert({
      'id': plotDataId,
      'project_id': projectId,
      'type': type,
      'content': content,
    });

    return plotDataId;
  }

  /// Get all plot data for a project
  Future<List<Map<String, dynamic>>> getProjectPlotData(
      String projectId) async {
    final response = await _client
        .from('plot_data')
        .select()
        .eq('project_id', projectId)
        .order('created_at', ascending: true);
    return response;
  }

  /// Get plot data of a specific type
  Future<List<Map<String, dynamic>>> getPlotDataByType(
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
  Future<void> updatePlotData(String plotDataId, String content) async {
    await _client.from('plot_data').update({
      'content': content,
    }).eq('id', plotDataId);
  }

  /// Delete plot data
  Future<void> deletePlotData(String plotDataId) async {
    await _client.from('plot_data').delete().eq('id', plotDataId);
  }

  // ==================== Direct Access Examples ====================

  /// Example of direct access to create a project
  static Future<void> directCreateProject(
      String title, String description) async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;

    if (userId == null) return;

    await supabase.from('projects').insert({
      'user_id': userId,
      'title': title,
      'description': description,
    });
  }

  /// Example of direct access to get user projects
  static Future<List<Map<String, dynamic>>> directGetUserProjects() async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;

    if (userId == null) return [];

    final response = await supabase
        .from('projects')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return response;
  }

  /// Example of direct access to add plot data
  static Future<void> directAddPlotData(
      String projectId, String type, String content) async {
    final supabase = Supabase.instance.client;

    await supabase.from('plot_data').insert({
      'project_id': projectId,
      'type': type,
      'content': content,
    });
  }
}
