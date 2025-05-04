import 'package:flutter/material.dart';
import '../services/service_locator.dart';
import '../services/supabase_database_service.dart';

/// Example widget demonstrating Supabase database operations using the service locator
class SupabaseDatabaseServiceExample extends StatefulWidget {
  const SupabaseDatabaseServiceExample({Key? key}) : super(key: key);

  @override
  _SupabaseDatabaseServiceExampleState createState() =>
      _SupabaseDatabaseServiceExampleState();
}

class _SupabaseDatabaseServiceExampleState
    extends State<SupabaseDatabaseServiceExample> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _message;
  List<Map<String, dynamic>> _projects = [];

  // Get the database service from the service locator
  final _databaseService = serviceLocator<SupabaseDatabaseService>();

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// Load projects for the current user
  Future<void> _loadProjects() async {
    if (!_databaseService.isAuthenticated) {
      setState(() {
        _message = 'ユーザーが認証されていません。ログインしてください。';
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final projects = await _databaseService.getUserProjects();
      setState(() {
        _projects = projects;
      });
    } catch (e) {
      setState(() {
        _message = 'プロジェクト読み込みエラー: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Create a new project
  Future<void> _createProject() async {
    if (!_databaseService.isAuthenticated) {
      setState(() {
        _message = 'ユーザーが認証されていません。ログインしてください。';
      });
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      final projectId = await _databaseService.createProject(
        _titleController.text.trim(),
        _descriptionController.text.trim(),
      );

      if (projectId != null) {
        setState(() {
          _message = 'プロジェクトが作成されました';
          _titleController.clear();
          _descriptionController.clear();
        });
        await _loadProjects();
      } else {
        setState(() {
          _message = 'プロジェクト作成に失敗しました';
        });
      }
    } catch (e) {
      setState(() {
        _message = 'プロジェクト作成エラー: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Delete a project
  Future<void> _deleteProject(String projectId) async {
    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      await _databaseService.deleteProject(projectId);
      setState(() {
        _message = 'プロジェクトが削除されました';
      });
      await _loadProjects();
    } catch (e) {
      setState(() {
        _message = 'プロジェクト削除エラー: $e';
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
        title: const Text('Supabase Database Service Example'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_message != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          _message!,
                          style: TextStyle(
                            color: _message!.contains('エラー')
                                ? Colors.red
                                : Colors.green,
                          ),
                        ),
                      ),
                    // Project creation section
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'プロジェクト作成',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _titleController,
                              decoration: const InputDecoration(
                                labelText: 'タイトル',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'タイトルを入力してください';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _descriptionController,
                              decoration: const InputDecoration(
                                labelText: '説明',
                                border: OutlineInputBorder(),
                              ),
                              maxLines: 3,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _createProject,
                              child: const Text('プロジェクト作成'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Projects list
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'プロジェクト一覧',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (_projects.isEmpty)
                              const Text('プロジェクトがありません')
                            else
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _projects.length,
                                itemBuilder: (context, index) {
                                  final project = _projects[index];
                                  return ListTile(
                                    title: Text(project['title']),
                                    subtitle:
                                        Text(project['description'] ?? ''),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed: () =>
                                          _deleteProject(project['id']),
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Code example section
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'コード例',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 16),
                            Text(
                              '// サービスロケーターからデータベースサービスを取得\n'
                              'final databaseService = serviceLocator<SupabaseDatabaseService>();\n\n'
                              '// プロジェクト作成\n'
                              'final projectId = await databaseService.createProject(\n'
                              '  \'新しい小説\',\n'
                              '  \'ファンタジー冒険譚\',\n'
                              ');\n\n'
                              '// プロジェクト一覧取得\n'
                              'final projects = await databaseService.getUserProjects();\n\n'
                              '// プロジェクト削除\n'
                              'await databaseService.deleteProject(projectId!);',
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

/// Code snippets for using the Supabase database service with the service locator
class SupabaseDatabaseServiceSnippets {
  /// Example: Create a project
  static void createProject() async {
    // Get the database service from the service locator
    final databaseService = serviceLocator<SupabaseDatabaseService>();

    // Create a project
    final projectId = await databaseService.createProject(
      '新しい小説',
      'ファンタジー冒険譚',
    );

    print('Created project with ID: $projectId');
  }

  /// Example: Get user projects
  static void getUserProjects() async {
    // Get the database service from the service locator
    final databaseService = serviceLocator<SupabaseDatabaseService>();

    // Get user projects
    final projects = await databaseService.getUserProjects();

    for (final project in projects) {
      print('Project: ${project['title']}');
    }
  }

  /// Example: Add plot data
  static void addPlotData(String projectId) async {
    // Get the database service from the service locator
    final databaseService = serviceLocator<SupabaseDatabaseService>();

    // Add plot data
    final plotDataId = await databaseService.addPlotData(
      projectId,
      'setting',
      '物語は魔法が日常的に使われる世界で展開します。',
    );

    print('Created plot data with ID: $plotDataId');
  }
}
