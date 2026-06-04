import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors
  static const Color primaryColor = Color(0xFF8B2287);
  static const Color secondaryColor = Color(0xFF4A1348);
  static const Color accentColor = Color(0xFFF72C5B);
  static const Color bgColor = Color(0xFFF9F5F9);
  static const Color textPrimary = Color(0xFF1A0B1A);
  static const Color textSecondary = Colors.black;
  static const Color successColor = Color(0xFF25D366); // WhatsApp green

  // Reusable Decorations
  static BoxDecoration cardDecoration({
    Color color = Colors.white,
    double radius = 20,
    Color? shadowColor,
  }) => BoxDecoration(
    color: color,
    borderRadius: BorderRadius.circular(radius),
    boxShadow: [
      BoxShadow(
        color: (shadowColor ?? primaryColor).withValues(alpha: 0.08),
        blurRadius: 16,
        offset: const Offset(0, 6),
      ),
    ],
  );

  static BoxDecoration get chipDecoration => BoxDecoration(
    color: const Color(0xFFF0E6F7),
    borderRadius: BorderRadius.circular(30),
    border: Border.all(color: primaryColor.withValues(alpha: 0.12)),
  );

  // Gradients
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryColor, accentColor],
  );

  static const LinearGradient bgGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFCEDF7), bgColor],
  );

  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: primaryColor,
      scaffoldBackgroundColor: bgColor,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: accentColor,
        surface: Colors.white,
      ),
      textTheme: GoogleFonts.outfitTextTheme().apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
