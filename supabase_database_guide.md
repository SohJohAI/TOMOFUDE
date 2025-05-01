# Supabase データベース操作ガイド

このガイドでは、Flutter アプリケーションから Supabase データベースを操作する方法について説明します。

## 概要

Supabase は PostgreSQL データベースをベースにした BaaS (Backend as a Service) で、Flutter アプリケーションから簡単にデータベース操作を行うことができます。このプロジェクトでは以下のテーブルが設定されています：

### users テーブル

- id (UUID, Primary Key)
- email (text, unique)
- plan (text, default: 'free')
- points (integer, default: 300)

### projects テーブル

- id (UUID, Primary Key)
- user_id (UUID, users.id と紐付け)
- title (text)
- description (text)
- created_at (timestamp)

### plot_data テーブル

- id (UUID, Primary Key)
- project_id (UUID, projects.id と紐付け)
- type (text) - 例：setting、plot、scene
- content (text)
- created_at (timestamp)

## 使用方法

### 1. サービスクラスを使用する方法

`SupabaseDatabaseService` クラスを使用すると、データベース操作を簡単に行うことができます。

```dart
// サービスのインスタンスを取得
final databaseService = SupabaseDatabaseService();

// プロジェクトの作成
final projectId = await databaseService.createProject(
  '新しい小説',
  'ファンタジー冒険譚',
);

// ユーザーのプロジェクト一覧を取得
final projects = await databaseService.getUserProjects();

// プロットデータの追加
final plotDataId = await databaseService.addPlotData(
  projectId!,
  'setting',
  '物語は魔法が日常的に使われる世界で展開します。',
);

// プロジェクトのプロットデータを取得
final plotData = await databaseService.getProjectPlotData(projectId!);

// プロットデータの更新
await databaseService.updatePlotData(
  plotDataId!,
  '物語は魔法と科学が共存する世界で展開します。',
);

// プロットデータの削除
await databaseService.deletePlotData(plotDataId!);

// プロジェクトの削除
await databaseService.deleteProject(projectId!);
```

### 2. 直接アクセスする方法

Supabase クライアントに直接アクセスして、データベース操作を行うこともできます。

```dart
// Supabase クライアントを取得
final supabase = Supabase.instance.client;

// プロジェクトの作成
await supabase.from('projects').insert({
  'user_id': supabase.auth.currentUser!.id,
  'title': '新しい小説',
  'description': 'ファンタジー冒険譚',
});

// ユーザーのプロジェクト一覧を取得
final projects = await supabase
  .from('projects')
  .select()
  .eq('user_id', supabase.auth.currentUser!.id)
  .order('created_at', ascending: false);

// プロットデータの追加
await supabase.from('plot_data').insert({
  'project_id': projectId,
  'type': 'setting',
  'content': '物語は魔法が日常的に使われる世界で展開します。',
});

// プロジェクトのプロットデータを取得
final plotData = await supabase
  .from('plot_data')
  .select()
  .eq('project_id', projectId)
  .order('created_at', ascending: true);

// プロットデータの更新
await supabase.from('plot_data').update({
  'content': '物語は魔法と科学が共存する世界で展開します。',
}).eq('id', plotDataId);

// プロットデータの削除
await supabase.from('plot_data').delete().eq('id', plotDataId);

// プロジェクトの削除
await supabase.from('projects').delete().eq('id', projectId);
```

## 実装例

### プロジェクトの作成・取得・削除

```dart
// プロジェクトの作成
Future<String?> createProject(String title, String description) async {
  final supabase = Supabase.instance.client;
  final userId = supabase.auth.currentUser?.id;

  if (userId == null) return null;

  // UUIDの生成（オプション）
  final projectId = const Uuid().v4();

  await supabase.from('projects').insert({
    'id': projectId, // 自動生成させる場合は省略可能
    'user_id': userId,
    'title': title,
    'description': description,
  });

  return projectId;
}

// ユーザーのプロジェクト一覧取得
Future<List<Map<String, dynamic>>> getUserProjects() async {
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

// プロジェクト削除
Future<void> deleteProject(String projectId) async {
  final supabase = Supabase.instance.client;
  await supabase.from('projects').delete().eq('id', projectId);
}
```

### プロットデータの保存と取得

```dart
// プロットデータ追加
Future<String?> addPlotData(String projectId, String type, String content) async {
  final supabase = Supabase.instance.client;

  // UUIDの生成（オプション）
  final plotDataId = const Uuid().v4();

  await supabase.from('plot_data').insert({
    'id': plotDataId, // 自動生成させる場合は省略可能
    'project_id': projectId,
    'type': type,
    'content': content,
  });

  return plotDataId;
}

// プロジェクトのプロットデータ取得
Future<List<Map<String, dynamic>>> getProjectPlotData(String projectId) async {
  final supabase = Supabase.instance.client;

  final response = await supabase
    .from('plot_data')
    .select()
    .eq('project_id', projectId)
    .order('created_at', ascending: true);

  return response;
}

// タイプ別プロットデータ取得
Future<List<Map<String, dynamic>>> getPlotDataByType(String projectId, String type) async {
  final supabase = Supabase.instance.client;

  final response = await supabase
    .from('plot_data')
    .select()
    .eq('project_id', projectId)
    .eq('type', type)
    .order('created_at', ascending: true);

  return response;
}

// プロットデータ更新
Future<void> updatePlotData(String plotDataId, String content) async {
  final supabase = Supabase.instance.client;

  await supabase.from('plot_data').update({
    'content': content,
  }).eq('id', plotDataId);
}

// プロットデータ削除
Future<void> deletePlotData(String plotDataId) async {
  final supabase = Supabase.instance.client;

  await supabase.from('plot_data').delete().eq('id', plotDataId);
}
```

## サンプルアプリケーション

プロジェクトには、Supabase データベース操作のサンプルアプリケーションが含まれています。

- `lib/examples/supabase_database_example.dart` - データベース操作の UI サンプル

このサンプルアプリケーションでは、以下の機能を試すことができます：

1. プロジェクトの作成
2. プロジェクト一覧の表示
3. プロジェクトの削除
4. プロットデータの追加
5. プロットデータの表示
6. プロットデータの削除

## 注意点

1. データベース操作を行う前に、ユーザーが認証されていることを確認してください。
2. Row Level Security (RLS) ポリシーにより、ユーザーは自分のデータのみにアクセスできます。
3. エラーハンドリングを適切に行い、ユーザーにフィードバックを提供してください。
4. 大量のデータを扱う場合は、ページネーションを使用することを検討してください。

## 参考リンク

- [Supabase 公式ドキュメント](https://supabase.com/docs)
- [Supabase Flutter SDK](https://supabase.com/docs/reference/dart/introduction)
- [PostgreSQL ドキュメント](https://www.postgresql.org/docs/)
