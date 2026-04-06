import 'package:flutter/material.dart';

/// Tema militar oscuro para Cuarto de Guerra
class WarRoomTheme {
  WarRoomTheme._();

  // ── Colores Primarios ──
  static const Color background = Color(0xFF0A0A0A);
  static const Color surface = Color(0xFF141414);
  static const Color surfaceLight = Color(0xFF1E1E1E);
  static const Color card = Color(0xFF1A1A1A);
  static const Color cardBorder = Color(0xFF2A2A2A);

  // ── Colores de Acento ──
  static const Color primary = Color(0xFF00FF41);       // Verde terminal
  static const Color primaryDim = Color(0xFF00CC33);
  static const Color primaryMuted = Color(0xFF0A3D0A);
  static const Color amber = Color(0xFFFFB300);          // Amarillo alerta
  static const Color amberDim = Color(0xFF8B6914);
  static const Color red = Color(0xFFFF1744);            // Rojo peligro
  static const Color redDim = Color(0xFF8B0000);
  static const Color cyan = Color(0xFF00E5FF);           // Info / secundario
  static const Color cyanDim = Color(0xFF007B8A);

  // ── Texto ──
  static const Color textPrimary = Color(0xFFE0E0E0);
  static const Color textSecondary = Color(0xFF9E9E9E);
  static const Color textMuted = Color(0xFF616161);
  static const Color textGreen = Color(0xFF00FF41);

  // ── Categorías de Deuda ──
  static const Color debtHonor = Color(0xFFFFD600);      // Amarillo honor
  static const Color debtLinea = Color(0xFF00E5FF);      // Cyan mantenimiento
  static const Color debtBasura = Color(0xFFFF1744);     // Rojo aniquilación
  static const Color debtCongeladora = Color(0xFF536DFE); // Azul congelado

  // ── Fuente monoespaciada militar ──
  static const String fontFamily = 'RobotoMono';

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      fontFamily: 'Roboto',
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: cyan,
        surface: surface,
        error: red,
        onPrimary: background,
        onSecondary: background,
        onSurface: textPrimary,
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: primary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'RobotoMono',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: primary,
          letterSpacing: 2,
        ),
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
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
            borderRadius: BorderRadius.circular(4),
            side: const BorderSide(color: primary, width: 1),
          ),
          textStyle: const TextStyle(
            fontFamily: 'RobotoMono',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: cyan,
          side: const BorderSide(color: cyan, width: 1),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          textStyle: const TextStyle(
            fontFamily: 'RobotoMono',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        labelStyle: const TextStyle(color: textSecondary, fontFamily: 'RobotoMono'),
        hintStyle: const TextStyle(color: textMuted, fontFamily: 'RobotoMono'),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(
          fontFamily: 'RobotoMono',
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: 'RobotoMono',
          fontSize: 10,
          letterSpacing: 1,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: cardBorder,
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surface,
        contentTextStyle: const TextStyle(color: textPrimary, fontFamily: 'RobotoMono'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: const BorderSide(color: primary),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: const BorderSide(color: cardBorder),
        ),
        titleTextStyle: const TextStyle(
          fontFamily: 'RobotoMono',
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: primary,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

/// Estilos de texto reutilizables con estética militar
class WarTextStyles {
  WarTextStyles._();

  static const TextStyle terminalTitle = TextStyle(
    fontFamily: 'RobotoMono',
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: WarRoomTheme.primary,
    letterSpacing: 2,
  );

  static const TextStyle terminalSubtitle = TextStyle(
    fontFamily: 'RobotoMono',
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: WarRoomTheme.textSecondary,
    letterSpacing: 1,
  );

  static const TextStyle moneyLarge = TextStyle(
    fontFamily: 'RobotoMono',
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: WarRoomTheme.primary,
    letterSpacing: 1,
  );

  static const TextStyle moneyMedium = TextStyle(
    fontFamily: 'RobotoMono',
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: WarRoomTheme.textPrimary,
    letterSpacing: 0.5,
  );

  static const TextStyle label = TextStyle(
    fontFamily: 'RobotoMono',
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: WarRoomTheme.textMuted,
    letterSpacing: 2,
  );

  static const TextStyle body = TextStyle(
    fontFamily: 'RobotoMono',
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: WarRoomTheme.textPrimary,
    height: 1.6,
  );

  static const TextStyle alertRed = TextStyle(
    fontFamily: 'RobotoMono',
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: WarRoomTheme.red,
    letterSpacing: 1,
  );

  static const TextStyle alertAmber = TextStyle(
    fontFamily: 'RobotoMono',
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: WarRoomTheme.amber,
    letterSpacing: 1,
  );
}
