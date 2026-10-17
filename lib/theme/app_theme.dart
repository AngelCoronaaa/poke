import 'package:flutter/material.dart';

class AppTheme {
  static const _semilla = Color(0xFFE3350D);

  static ThemeData get claro => _base(Brightness.light);
  static ThemeData get oscuro => _base(Brightness.dark);

  static ThemeData _base(Brightness brightness) {
    final esOscuro = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: _semilla,
      brightness: brightness,
      surface: esOscuro ? const Color(0xFF0B0C12) : const Color(0xFFF4F5F9),
    );
    final texto = esOscuro ? Colors.white : const Color(0xFF12131A);

    return ThemeData(
      colorScheme: scheme,
      brightness: brightness,
      scaffoldBackgroundColor: Colors.transparent,
      splashFactory: InkSparkle.splashFactory,
      textTheme: Typography.material2021(platform: TargetPlatform.iOS).black
          .apply(bodyColor: texto, displayColor: texto),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: esOscuro ? 0.06 : 0.6),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: esOscuro ? 0.1 : 0.9),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: scheme.error.withValues(alpha: 0.7)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: scheme.error, width: 1.5),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        backgroundColor: esOscuro
            ? const Color(0xFF23252F)
            : const Color(0xFF12131A),
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: esOscuro ? const Color(0xFF23252F) : const Color(0xFF12131A),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}
