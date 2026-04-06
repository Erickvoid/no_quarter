import 'package:flutter/material.dart';

/// Tema "Refugio" — Soft Dark Mode, estilo banca privada nórdica.
/// Transmite calma, control, orden y minimalismo.
class RefugioTheme {
  RefugioTheme._();

  // ── Fondos ──
  static const Color background = Color(0xFF1A1F2E);    // Azul marino oscuro cálido
  static const Color surface = Color(0xFF212737);        // Superficie elevada
  static const Color surfaceLight = Color(0xFF2A3142);   // Superficie clara
  static const Color card = Color(0xFF242B3D);           // Tarjetas
  static const Color cardBorder = Color(0xFF3A4256);     // Bordes sutiles

  // ── Colores de Acento ──
  static const Color primary = Color(0xFF7CB68E);        // Verde salvia — éxito, capital
  static const Color primaryDim = Color(0xFF5A9B6E);     // Verde salvia oscuro
  static const Color primaryMuted = Color(0xFF1E3328);   // Verde fondo sutil
  static const Color accent = Color(0xFF6B9FBF);         // Azul cobalto suave — info
  static const Color cobalt = accent;                    // Alias — fondos de ahorro/inversión
  static const Color accentDim = Color(0xFF4A7D9E);      // Azul cobalto oscuro
  static const Color amber = Color(0xFFD4A574);          // Ámbar cálido — atención
  static const Color amberDim = Color(0xFF8B6D4A);       // Ámbar oscuro
  static const Color salmon = Color(0xFFD4887A);         // Salmón suave — alerta
  static const Color salmonDim = Color(0xFF8B5A50);      // Salmón oscuro
  static const Color mint = Color(0xFF7EC8B8);           // Menta suave — secundario

  // ── Texto ──
  static const Color textPrimary = Color(0xFFE8ECF1);    // Blanco cálido
  static const Color textSecondary = Color(0xFFA0AABB);  // Gris azulado
  static const Color textMuted = Color(0xFF6B7585);      // Gris tenue
  static const Color textAccent = Color(0xFF7CB68E);     // Verde salvia

  // ── Categorías de Pasivos ──
  static const Color debtHonor = Color(0xFFD4A574);      // Ámbar — Compromisos personales
  static const Color debtLinea = Color(0xFF6B9FBF);      // Azul cobalto — Líneas estratégicas
  static const Color debtBasura = Color(0xFFD4887A);     // Salmón — Pasivos prioritarios
  static const Color debtCongeladora = Color(0xFF8B9DC3); // Azul grisáceo — Congelados

  // ── Tipografía ──
  static const String fontFamily = 'Nunito';

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      fontFamily: fontFamily,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: accent,
        surface: surface,
        error: salmon,
        onPrimary: background,
        onSecondary: background,
        onSurface: textPrimary,
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: 0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: cardBorder, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryMuted,
          foregroundColor: primary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: primary, width: 1),
          ),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accent,
          side: const BorderSide(color: accent, width: 1),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        labelStyle: const TextStyle(color: textSecondary, fontFamily: fontFamily),
        hintStyle: const TextStyle(color: textMuted, fontFamily: fontFamily),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 11,
          letterSpacing: 0.3,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: cardBorder,
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surface,
        contentTextStyle: const TextStyle(color: textPrimary, fontFamily: fontFamily),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: primary),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: cardBorder),
        ),
        titleTextStyle: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

/// Estilos de texto reutilizables — elegantes y serenos
class RefugioTextStyles {
  RefugioTextStyles._();

  static const TextStyle heading = TextStyle(
    fontFamily: RefugioTheme.fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: RefugioTheme.textPrimary,
    letterSpacing: 0.3,
  );

  static const TextStyle subtitle = TextStyle(
    fontFamily: RefugioTheme.fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: RefugioTheme.textSecondary,
    letterSpacing: 0.2,
  );

  static const TextStyle moneyLarge = TextStyle(
    fontFamily: RefugioTheme.fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w800,
    color: RefugioTheme.primary,
    letterSpacing: 0.5,
  );

  static const TextStyle moneyMedium = TextStyle(
    fontFamily: RefugioTheme.fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: RefugioTheme.textPrimary,
    letterSpacing: 0.3,
  );

  static const TextStyle label = TextStyle(
    fontFamily: RefugioTheme.fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: RefugioTheme.textMuted,
    letterSpacing: 1.2,
  );

  static const TextStyle body = TextStyle(
    fontFamily: RefugioTheme.fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: RefugioTheme.textPrimary,
    height: 1.6,
  );

  static const TextStyle alertSalmon = TextStyle(
    fontFamily: RefugioTheme.fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: RefugioTheme.salmon,
    letterSpacing: 0.3,
  );

  static const TextStyle alertAmber = TextStyle(
    fontFamily: RefugioTheme.fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: RefugioTheme.amber,
    letterSpacing: 0.3,
  );
}
