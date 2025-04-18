# Supabase Tables Setup Guide

This guide explains how to set up the required tables in your Supabase PostgreSQL database and how to interact with them from your Flutter application.

## Setting Up Tables in Supabase

1. Log in to your Supabase dashboard at [https://app.supabase.com/](https://app.supabase.com/)
2. Navigate to your project
3. Go to the SQL Editor (in the left sidebar)
4. Click "New Query"
5. Copy and paste the entire content from the `supabase_tables_setup.sql` file
6. Click "Run" to execute the SQL script

This will create the following tables with appropriate Row Level Security (RLS) policies:

### users Table
- `id` (UUID, Primary Key, auto-generated)
- `email` (text, unique)
- `plan` (text, default 'free')
- `points` (integer, default 300)

### projects Table
- `id` (UUID, Primary Key, auto-generated)
- `user_id` (UUID, references users.id)
- `title` (text)
- `description` (text)
- `created_at` (timestamp, auto-generated)

### plot_data Table
- `id` (UUID, Primary Key, auto-generated)
- `project_id` (UUID, references projects.id)
- `type` (text) - examples: setting, plot, scene
- `content` (text)
- `created_at` (timestamp, auto-generated)

## Interacting with Tables from Flutter

Your application already has the necessary Supabase service implementation. Here are examples of how to interact with the new tables:

### Working with Users

```dart
// Get the Supabase service
final supabaseService = serviceLocator<SupabaseServiceInterface>();

// Get current user ID
final userId = supabaseService.currentUser?.id;

// Update user plan
await SupabaseExamples.updateData('users', userId, {
  'plan': 'premium'
});

// Update user points
await SupabaseExamples.updateData('users', userId, {
  'points': 500
});

// Get user data
final userData = await SupabaseExamples.queryData('users', 'id', userId);
```

### Working with Projects

```dart
// Create a new project
await SupabaseExamples.insertData('projects', {
  'user_id': supabaseService.currentUser?.id,
  'title': 'My Novel Project',
  'description': 'A story about adventure and discovery'
});

// Get all projects for current user
final userProjects = await SupabaseExamples.queryData(
  'projects', 
  'user_id', 
  supabaseService.currentUser?.id
);

// Update a project
await SupabaseExamples.updateData('projects', projectId, {
  'title': 'Updated Project Title',
  'description': 'New project description'
});

// Delete a project
await SupabaseExamples.deleteData('projects', projectId);
```

### Working with Plot Data

```dart
// Add plot data to a project
await SupabaseExamples.insertData('plot_data', {
  'project_id': projectId,
  'type': 'setting',
  'content': 'The story takes place in a futuristic city with flying cars and AI companions.'
});

// Get all plot data for a project
final plotData = await SupabaseExamples.queryData(
  'plot_data', 
  'project_id', 
  projectId
);

// Get plot data of a specific type
final sceneData = await _client
  .from('plot_data')
  .select()
  .eq('project_id', projectId)
  .eq('type', 'scene');

// Update plot data
await SupabaseExamples.updateData('plot_data', plotDataId, {
  'content': 'Updated content for this plot element'
});

// Delete plot data
await SupabaseExamples.deleteData('plot_data', plotDataId);
```

## Row Level Security (RLS)

The SQL script sets up Row Level Security policies to ensure that:

1. Users can only access their own user data
2. Users can only create, read, update, and delete their own projects
3. Users can only create, read, update, and delete plot data that belongs to their own projects

This security is automatically enforced by Supabase at the database level.

## Performance Considerations

The SQL script creates indexes on foreign key columns to improve query performance:

- `idx_projects_user_id` on `projects.user_id`
- `idx_plot_data_project_id` on `plot_data.project_id`
- `idx_plot_data_type` on `plot_data.type`

These indexes will help speed up queries that filter by these columns.
