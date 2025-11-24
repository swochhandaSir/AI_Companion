import 'package:flutter/material.dart';
import 'login_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Custom color palette
    const Color cream = Color(0xFFF8F4EC);
    const Color lightPink = Color(0xFFFF8FB7);
    const Color primaryPink = Color(0xFFE83C91);
    const Color darkPurple = Color(0xFF43334C);

    return MaterialApp(
      title: 'AI Companion',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.light(
          primary: primaryPink,
          secondary: lightPink,
          surface: cream,
          background: cream,
          error: Colors.red.shade400,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: darkPurple,
          onBackground: darkPurple,
          onError: Colors.white,
        ),
        scaffoldBackgroundColor: cream,
        appBarTheme: AppBarTheme(
          backgroundColor: primaryPink,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: darkPurple.withOpacity(0.2)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: darkPurple.withOpacity(0.2)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: primaryPink, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.red.shade400),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.red.shade400, width: 2),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryPink,
            foregroundColor: Colors.white,
            elevation: 2,
            padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: primaryPink,
            side: BorderSide(color: primaryPink, width: 2),
            padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        textTheme: TextTheme(
          displayLarge: TextStyle(
            color: darkPurple,
            fontWeight: FontWeight.bold,
          ),
          displayMedium: TextStyle(
            color: darkPurple,
            fontWeight: FontWeight.bold,
          ),
          displaySmall: TextStyle(
            color: darkPurple,
            fontWeight: FontWeight.w600,
          ),
          bodyLarge: TextStyle(color: darkPurple),
          bodyMedium: TextStyle(color: darkPurple),
          bodySmall: TextStyle(color: darkPurple.withOpacity(0.7)),
        ),
      ),
      home: LoginPage(),
    );
  }
}
