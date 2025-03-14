import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_state.dart';
import 'providers/novel_list_provider.dart';
import 'screens/novel_list_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => NovelAppState()),
        ChangeNotifierProvider(create: (context) => NovelListProvider()),
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

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '共筆。（TOMOFUDE）- AI小説執筆アプリ',
      theme: ThemeData(
        primaryColor: const Color(0xFF5D5CDE),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF5D5CDE),
          secondary: Color(0xFF5D5CDE),
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: Colors.white,
        cardColor: const Color(0xFFF8F9FA),
        textTheme: Typography.material2018().black,
        // TextSelectionThemeDataを使用して入力フィールドの表示を設定
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: Color(0xFF5D5CDE),
          selectionColor: Color(0xFFD0D0F7),
          selectionHandleColor: Color(0xFF5D5CDE),
        ),
      ),
      darkTheme: ThemeData(
        primaryColor: const Color(0xFF5D5CDE),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF5D5CDE),
          secondary: Color(0xFF5D5CDE),
          surface: Color(0xFF252525),
        ),
        scaffoldBackgroundColor: const Color(0xFF181818),
        cardColor: const Color(0xFF252525),
        textTheme: Typography.material2018().white,
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: Color(0xFF5D5CDE),
          selectionColor: Color(0xFF3E3E8F),
          selectionHandleColor: Color(0xFF5D5CDE),
        ),
      ),
      themeMode: appState.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: const NovelListScreen(),
    );
  }
}
