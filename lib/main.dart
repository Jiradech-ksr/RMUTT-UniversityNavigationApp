import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const UniversityNavigationAppApp());
}

class UniversityNavigationAppApp extends StatelessWidget {
  const UniversityNavigationAppApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RMUTT Navigator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        // Primary Color: Indigo (Professional Blue)
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A237E), // Indigo 900
          secondary: const Color(0xFFFFC107), // Amber (Accent)
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(
          0xFFF5F5F5,
        ), // Light Grey Background
        // AppBar Theme
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1A237E),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),

        // Text Theme (Modern & Readable)
        textTheme: const TextTheme(
          headlineSmall: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          bodyLarge: TextStyle(fontSize: 16, color: Colors.black87),
          bodyMedium: TextStyle(fontSize: 14, color: Colors.black54),
        ),

        // Input Decoration (Search Bars, etc.)
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
          prefixIconColor: Colors.grey,
        ),

        // Elevated Button Theme
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A237E), // Indigo
            foregroundColor: Colors.white,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          ),
        ),
      ),

      // ----------------------------
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}
