import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// Only import Firebase on non-web platforms
import 'firebase_imports.dart'
    if (dart.library.html) 'firebase_imports_web.dart';
import 'providers/app_state.dart';
import 'providers/novel_list_provider.dart';
import 'providers/work_list_provider.dart';
import 'providers/payment_provider.dart';
import 'screens/novel_list_screen.dart';
import 'screens/work_list_screen.dart';
import 'screens/payment_screen.dart';
import 'services/service_locator.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (skip on web platform due to compatibility issues)
  print('Initializing Firebase...');
  try {
    if (kIsWeb) {
      print(
          'Running on web platform, skipping Firebase initialization due to compatibility issues');
      // Skip Firebase initialization on web
    } else {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print('Firebase initialized successfully');
    }
  } catch (e) {
    print('Failed to initialize Firebase: $e');
    // Continue without Firebase
  }

  // Initialize service locator
  await setupServiceLocator();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => NovelAppState()),
        ChangeNotifierProvider(create: (context) => NovelListProvider()),
        ChangeNotifierProvider(create: (context) => WorkListProvider()),
        ChangeNotifierProvider(create: (context) => PaymentProvider()),
      ],
      child: const TomofudeApp(),
    ),
  );
}

class TomofudeApp extends StatelessWidget {
  const TomofudeApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<NovelAppState>(context);

    // Cupertinoスタイルのアプリに変更
    return CupertinoApp(
      debugShowCheckedModeBanner: false,
      title: '共筆。（TOMOFUDE）- AI小説執筆アプリ',
      theme: CupertinoThemeData(
        primaryColor: const Color(0xFF5D5CDE),
        brightness: appState.isDarkMode ? Brightness.dark : Brightness.light,
        scaffoldBackgroundColor: appState.isDarkMode
            ? const Color(0xFF181818)
            : CupertinoColors.white,
        barBackgroundColor: appState.isDarkMode
            ? const Color(0xFF252525)
            : CupertinoColors.white,
        textTheme: CupertinoTextThemeData(
          primaryColor: const Color(0xFF5D5CDE),
          textStyle: TextStyle(
            color: appState.isDarkMode
                ? CupertinoColors.white
                : CupertinoColors.black,
            fontFamily: 'Hiragino Sans',
          ),
        ),
      ),
      // Material Widgetも使用するためのブリッジ
      builder: (context, child) {
        return Material(color: Colors.transparent, child: child);
      },
      routes: {
        '/': (context) => const NovelListScreen(),
        '/works': (context) => const WorkListScreen(),
        '/payment': (context) => const PaymentScreen(),
      },
      initialRoute: '/',
    );
  }
}
