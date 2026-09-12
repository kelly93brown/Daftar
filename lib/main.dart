import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/home_screen.dart';
import 'services/app_state.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init(); // تهيئة الإشعارات
  runApp(const JewelryLedgerApp());
}

class JewelryLedgerApp extends StatefulWidget {
  const JewelryLedgerApp({super.key});

  @override
  State<JewelryLedgerApp> createState() => _JewelryLedgerAppState();
}

class _JewelryLedgerAppState extends State<JewelryLedgerApp> {
  final AppState _appState = AppState();

  @override
  void initState() {
    super.initState();
    _appState.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    const primaryTeal = Color(0xFF0D4E42);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'دفتر الصاغة والمجوهرات',
      themeMode: _appState.themeMode,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(_appState.fontScale)),
          child: child!,
        );
      },
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ar', 'DZ'), Locale('en', 'US')],
      locale: const Locale('ar', 'DZ'),
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: primaryTeal,
        colorScheme: ColorScheme.fromSeed(seedColor: primaryTeal, primary: primaryTeal),
        scaffoldBackgroundColor: const Color(0xFFF4F7F6),
      ),
      darkTheme: ThemeData.dark().copyWith(
        primaryColor: primaryTeal,
        colorScheme: ColorScheme.fromSeed(seedColor: primaryTeal, brightness: Brightness.dark),
      ),
      home: HomeScreen(state: _appState),
    );
  }
}
