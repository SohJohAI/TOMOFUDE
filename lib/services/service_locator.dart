import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:get_it/get_it.dart';

import 'ai_service.dart';
import 'ai_service_interface.dart';
import 'auth_service.dart';
import 'auth_service_interface.dart';
import 'export_service.dart';
import 'file_system_service.dart';
import 'plot_booster_service.dart';
import 'point_service.dart';
import 'point_service_interface.dart';
import 'preview_service.dart';
import 'storage_service.dart';
import 'supabase_service.dart';
import 'supabase_service_interface.dart';

/// Global ServiceLocator instance
final GetIt serviceLocator = GetIt.instance;

/// Initialize all services
Future<void> setupServiceLocator() async {
  // Register services as lazySingletons

  // AI Service
  serviceLocator.registerLazySingleton<AIService>(
    () => DummyAIService(),
  );

  // Auth Service
  serviceLocator.registerLazySingleton<AuthServiceInterface>(
    () {
      // Use the appropriate implementation based on the platform
      return AuthService();
    },
  );

  // Export Service
  serviceLocator.registerLazySingleton<ExportService>(
    () => ExportService(),
  );

  // File System Service
  serviceLocator.registerLazySingleton<FileSystemService>(
    () => FileSystemService(),
  );

  // Plot Booster Service
  serviceLocator.registerLazySingleton<PlotBoosterService>(
    () => PlotBoosterService(),
  );

  // Point Service
  serviceLocator.registerLazySingleton<PointServiceInterface>(
    () {
      // Use the appropriate implementation based on the platform
      return PointService();
    },
  );

  // Preview Service
  serviceLocator.registerLazySingleton<PreviewService>(
    () => PreviewService(),
  );

  // Storage Service
  serviceLocator.registerLazySingleton<StorageService>(
    () => StorageService(),
  );

  // Supabase Service
  serviceLocator.registerLazySingleton<SupabaseServiceInterface>(
    () => SupabaseService(),
  );

  // Initialize services that require async initialization
  await serviceLocator<AuthServiceInterface>().initialize();
  await serviceLocator<PointServiceInterface>().initialize();
  await serviceLocator<SupabaseServiceInterface>().initialize();
}
