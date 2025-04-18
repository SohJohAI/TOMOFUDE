import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'providers/app_state.dart';
import 'providers/novel_list_provider.dart';
import 'providers/work_list_provider.dart';
import 'providers/payment_provider.dart';
import 'screens/novel_list_screen.dart';
import 'screens/work_list_screen.dart';
import 'screens/payment_screen.dart';
import 'screens/auth_gate.dart';
import 'services/service_locator.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://awbrfvdyokwkpwrqmfwd.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImF3YnJmdmR5b2t3a3B3cnFtZndkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDQ3MTcwODQsImV4cCI6MjA2MDI5MzA4NH0.e57mIz0nhuZpm-scH6k60w4ugzMNinaSthQTaeTZ2SQ',
  );

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
        '/': (context) => const AuthGate(),
        '/works': (context) => const WorkListScreen(),
        '/payment': (context) => const PaymentScreen(),
      },
      initialRoute: '/',
    );
  }
}
