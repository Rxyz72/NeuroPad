import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:neuropad/firebase_options.dart';
import 'login_page.dart';
import 'home_page.dart';
import 'notification_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;

// Global notifier for theme management
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  tz.initializeTimeZones();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await NotificationService().initNotification();

  // --- PERSISTENCE LOGIC ---
  final prefs = await SharedPreferences.getInstance();
  final isDark = prefs.getBool('isDarkMode') ?? false;
  themeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, currentMode, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            FlutterQuillLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en', 'US')],
          themeMode: currentMode,

          // MODERN LIGHT THEME
          theme: ThemeData(
            brightness: Brightness.light,
            fontFamily: 'Delius',
            scaffoldBackgroundColor: Colors.white,
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              elevation: 0,
            ),
            cardColor: const Color(0xFFF7F7F7),
          ),

          // MODERN DARK THEME
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            fontFamily: 'Delius',
            scaffoldBackgroundColor: const Color(0xFF121212),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF121212),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            cardColor: const Color(0xFF1E1E1E),
          ),

          home: const AuthWrapper(),
          routes: {
            '/login': (context) => const LoginPage(),
            '/home': (context) => const HomePage(),
          },
        );
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: Colors.black)),
          );
        }
        return snapshot.hasData ? const HomePage() : const LoginPage();
      },
    );
  }
}