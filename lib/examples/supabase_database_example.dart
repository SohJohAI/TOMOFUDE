import 'package:flutter/material.dart';
import '../services/supabase_database_service.dart';

/// Example widget demonstrating Supabase database operations
class SupabaseDatabaseExample extends StatefulWidget {
  const SupabaseDatabaseExample({Key? key}) : super(key: key);

  @override
  _SupabaseDatabaseExampleState createState() =>
      _SupabaseDatabaseExampleState();
}

class _SupabaseDatabaseExampleState extends State<SupabaseDatabaseExample> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _contentController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _selectedProjectId;
  String _selectedPlotType = 'setting'; // Default plot type
  bool _isLoading = false;
  String? _message;
  List<Map<String, dynamic>> _projects = [];
  List<Map<String, dynamic>> _plotData = [];

  // Get the database service
  final _databaseService = SupabaseDatabaseService();

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  /// Load projects for the current user
  Future<void> _loadProjects() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final projects = await _databaseService.getUserProjects();
      setState(() {
        _projects = projects;
        if (projects.isNotEmpty && _selectedProjectId == null) {
          _selectedProjectId = projects.first['id'];
          _loadPlotData();
        }
      });
    } catch (e) {
      setState(() {
        _message = 'Error loading projects: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Load plot data for the selected project
  Future<void> _loadPlotData() async {
    if (_selectedProjectId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final plotData =
          await _databaseService.getProjectPlotData(_selectedProjectId!);
      setState(() {
        _plotData = plotData;
      });
    } catch (e) {
      setState(() {
        _message = 'Error loading plot data: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Create a new project
  Future<void> _createProject() async {
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
          _message = 'Project created successfully';
          _titleController.clear();
          _descriptionController.clear();
        });
        await _loadProjects();
      } else {
        setState(() {
          _message = 'Failed to create project';
        });
      }
    } catch (e) {
      setState(() {
        _message = 'Error creating project: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Add plot data to the selected project
  Future<void> _addPlotData() async {
    if (_selectedProjectId == null || !_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      final plotDataId = await _databaseService.addPlotData(
        _selectedProjectId!,
        _selectedPlotType,
        _contentController.text.trim(),
      );

      if (plotDataId != null) {
        setState(() {
          _message = 'Plot data added successfully';
          _contentController.clear();
        });
        await _loadPlotData();
      } else {
        setState(() {
          _message = 'Failed to add plot data';
        });
      }
    } catch (e) {
      setState(() {
        _message = 'Error adding plot data: $e';
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
        _message = 'Project deleted successfully';
        if (_selectedProjectId == projectId) {
          _selectedProjectId = null;
          _plotData = [];
        }
      });
      await _loadProjects();
    } catch (e) {
      setState(() {
        _message = 'Error deleting project: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Delete plot data
  Future<void> _deletePlotData(String plotDataId) async {
    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      await _databaseService.deletePlotData(plotDataId);
      setState(() {
        _message = 'Plot data deleted successfully';
      });
      await _loadPlotData();
    } catch (e) {
      setState(() {
        _message = 'Error deleting plot data: $e';
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
        title: const Text('Supabase Database Example'),
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
                            color: _message!.contains('Error')
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
                              'Create New Project',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _titleController,
                              decoration: const InputDecoration(
                                labelText: 'Title',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a title';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _descriptionController,
                              decoration: const InputDecoration(
                                labelText: 'Description',
                                border: OutlineInputBorder(),
                              ),
                              maxLines: 3,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _createProject,
                              child: const Text('Create Project'),
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
                              'Your Projects',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (_projects.isEmpty)
                              const Text('No projects found')
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
                                    selected:
                                        _selectedProjectId == project['id'],
                                    onTap: () {
                                      setState(() {
                                        _selectedProjectId = project['id'];
                                      });
                                      _loadPlotData();
                                    },
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
                    // Plot data section
                    if (_selectedProjectId != null)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                'Add Plot Data',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              DropdownButtonFormField<String>(
                                value: _selectedPlotType,
                                decoration: const InputDecoration(
                                  labelText: 'Plot Type',
                                  border: OutlineInputBorder(),
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'setting',
                                    child: Text('Setting'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'plot',
                                    child: Text('Plot'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'scene',
                                    child: Text('Scene'),
                                  ),
                                ],
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      _selectedPlotType = value;
                                    });
                                  }
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _contentController,
                                decoration: const InputDecoration(
                                  labelText: 'Content',
                                  border: OutlineInputBorder(),
                                ),
                                maxLines: 5,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter content';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _addPlotData,
                                child: const Text('Add Plot Data'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),
                    // Plot data list
                    if (_selectedProjectId != null)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                'Plot Data',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              if (_plotData.isEmpty)
                                const Text('No plot data found')
                              else
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _plotData.length,
                                  itemBuilder: (context, index) {
                                    final plotData = _plotData[index];
                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Chip(
                                                  label: Text(plotData['type']),
                                                ),
                                                IconButton(
                                                  icon:
                                                      const Icon(Icons.delete),
                                                  onPressed: () =>
                                                      _deletePlotData(
                                                          plotData['id']),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Text(plotData['content']),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
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

/// Code snippets for direct Supabase database access
class SupabaseDatabaseSnippets {
  /// Example: Create a project
  static void createProject() async {
    // Direct access example
    await SupabaseDatabaseService.directCreateProject(
      '新しい小説',
      'ファンタジー冒険譚',
    );
  }

  /// Example: Get user projects
  static void getUserProjects() async {
    final projects = await SupabaseDatabaseService.directGetUserProjects();
    for (final project in projects) {
      print('Project: ${project['title']}');
    }
  }

  /// Example: Add plot data
  static void addPlotData(String projectId) async {
    await SupabaseDatabaseService.directAddPlotData(
      projectId,
      'setting',
      '物語は魔法が日常的に使われる世界で展開します。',
    );
  }
}
