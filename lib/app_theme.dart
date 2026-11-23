import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(
    0xFFE91E63,
  ); // লগইন পেজের মূল রোজ-পিংক কালার
  static const Color primaryDark = Color(
    0xFF9C1449,
  ); // ডিপ বেরি শেড (Gradient-এর জন্য)
  static const Color secondary = Color(0xFFF06292); // হালকা পিংক শেড
  static const Color background = Color(
    0xFFF8F9FA,
  ); // পরিচ্ছন্ন হালকা ব্যাকগ্রাউন্ড
  static const Color surface = Colors.white; // কার্ডের সাদা রঙ
  static const Color textDark = Color(0xFF1E293B); // গাঢ় লেখার রঙ
  static const Color textMuted = Color(0xFF64748B); // হালকা লেখার রঙ
  static const Color danger = Color(0xFFD32F2F); // Out of stock লাল রঙ

  // লগইন পেজের মতো হুবহু গ্র্যাডিয়েন্ট
  static const LinearGradient brandGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
      ),

      // পুরো অ্যাপের AppBar ডিজাইন
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),

      // পুরো অ্যাপের ElevatedButton ডিজাইন
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),

      // পুরো অ্যাপের OutlinedButton ডিজাইন
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // পুরো অ্যাপের TextField / Input Box ডিজাইন
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
        ),
      ),
    );
  }
}
