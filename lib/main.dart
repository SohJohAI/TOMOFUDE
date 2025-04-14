import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'providers/app_state.dart';
import 'providers/novel_list_provider.dart';
import 'providers/work_list_provider.dart';
import 'providers/payment_provider.dart';
import 'screens/novel_list_screen.dart';
import 'screens/work_list_screen.dart';
import 'screens/payment_screen.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase initialization is disabled for now
  // To enable Firebase:
  // 1. Uncomment Firebase dependencies in pubspec.yaml
  // 2. Run 'flutter pub get'
  // 3. Uncomment the Firebase initialization code in this file
  // 4. Set firebaseEnabled to true

  /*
  // Initialize Firebase if enabled
  bool firebaseEnabled = true;
  if (firebaseEnabled) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print('Firebase initialized successfully');
    } catch (e) {
      print('Failed to initialize Firebase: $e');
      // Continue without Firebase
    }
  }
  */
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
