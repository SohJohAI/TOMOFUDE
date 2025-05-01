import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'utils/constants.dart';

import 'providers/app_state.dart';
import 'providers/novel_list_provider.dart';
import 'providers/work_list_provider.dart';
import 'providers/payment_provider.dart';
import 'screens/novel_list_screen.dart';
import 'screens/work_list_screen.dart';
import 'screens/payment_screen.dart';
import 'screens/auth_gate.dart';
import 'screens/home_screen.dart';
import 'screens/transaction_law_screen.dart';
import 'screens/subscription_screen.dart';
import 'screens/faq_screen.dart';
import 'examples/claude_ai_service_test.dart';
import 'services/service_locator.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: '.env');

  // Initialize Supabase
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,

  void loginForTest() async {
    final response = await Supabase.instance.client.auth.signInWithPassword(
      email: "sohjohai@gmail.com",
      password: "D99U+P*zPf_rh2Y",
    );

    final jwt = response.session?.accessToken;
    print("ログイン成功！JWT: $jwt");
  }

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
    final jwt = Supabase.instance.client.auth.currentSession?.accessToken;
    print('JWT: $jwt');
    final appState = Provider.of<NovelAppState>(context);

    // Material 3 スタイルのアプリに変更
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '共筆。（TOMOFUDE）- AI小説執筆アプリ',
      theme: ThemeData(
        useMaterial3: true,
        brightness: appState.isDarkMode ? Brightness.dark : Brightness.light,
        colorSchemeSeed: const Color(0xFF6E32FF),
        fontFamily: 'Hiragino Sans',
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: const Color(0xFF6E32FF),
        fontFamily: 'Hiragino Sans',
      ),
      themeMode: appState.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      routes: {
        '/': (context) => HomeScreen(),
        '/auth': (context) => const AuthGate(),
        '/works': (context) => const WorkListScreen(),
        '/payment': (context) => const PaymentScreen(),
        '/transaction_law': (context) => const TransactionLawScreen(),
        '/subscription': (context) => const SubscriptionScreen(),
        '/faq': (context) => const FAQScreen(),
        '/api_test': (context) => const ClaudeAIServiceTest(),
      },
      initialRoute: '/',
    );
  }
}
