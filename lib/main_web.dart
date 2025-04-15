// This is a web-specific version of main.dart that uses Firebase web packages
// with the necessary fixes for compatibility

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core_web/firebase_core_web_interop.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Import Firebase for web
import 'firebase_imports_web.dart';
import 'firebase_web_fix.dart';

import 'providers/app_state.dart';
import 'providers/novel_list_provider.dart';
import 'providers/work_list_provider.dart';
import 'providers/payment_provider.dart';
import 'screens/novel_list_screen.dart';
import 'screens/work_list_screen.dart';
import 'screens/payment_screen.dart';
// Import web-specific services
import 'services/auth_service_web.dart';
import 'services/point_service_web.dart';
import 'services/service_locator.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  print('Running on web platform, initializing Firebase for web');

  try {
    // Initialize Firebase for web
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully for web');
  } catch (e) {
    print('Failed to initialize Firebase for web: $e');
    // Continue with mock implementations
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
