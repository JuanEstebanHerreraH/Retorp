// services/tema.dart - Tema oscuro y constantes de diseño para NetMonitor

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NetMonitorTema {
  // ─── Colores principales ──────────────────────────────────────────────────
  static const Color azulElectrico = Color(0xFF0A84FF);
  static const Color azulOscuro = Color(0xFF0066CC);
  static const Color azulClaro = Color(0xFF40A9FF);

  static const Color fondoPrincipal = Color(0xFF0D0D0D);
  static const Color fondoSecundario = Color(0xFF1A1A2E);
  static const Color fondoCard = Color(0xFF16213E);
  static const Color fondoCardHover = Color(0xFF1E2A4A);

  static const Color textoPrimario = Color(0xFFFFFFFF);
  static const Color textoSecundario = Color(0xFFB0B8CC);
  static const Color textoTerciario = Color(0xFF6B7A99);

  static const Color verdeActivo = Color(0xFF00E676);
  static const Color verdeClaro = Color(0xFF00C853);
  static const Color amarilloLatencia = Color(0xFFFFD600);
  static const Color rojoAlerta = Color(0xFFFF1744);
  static const Color rojoClaro = Color(0xFFFF5252);
  static const Color grisInactivo = Color(0xFF4A5568);

  static const Color bordeCard = Color(0xFF2A3A5C);

  // ─── Tema Material ────────────────────────────────────────────────────────
  static ThemeData get tema {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: fondoPrincipal,
      colorScheme: const ColorScheme.dark(
        primary: azulElectrico,
        secondary: azulClaro,
        surface: fondoCard,
        error: rojoAlerta,
        onPrimary: textoPrimario,
        onSecondary: textoPrimario,
        onSurface: textoPrimario,
      ),
      textTheme: GoogleFonts.poppinsTextTheme(
        const TextTheme(
          displayLarge: TextStyle(color: textoPrimario, fontWeight: FontWeight.w700),
          displayMedium: TextStyle(color: textoPrimario, fontWeight: FontWeight.w600),
          headlineLarge: TextStyle(color: textoPrimario, fontWeight: FontWeight.w700),
          headlineMedium: TextStyle(color: textoPrimario, fontWeight: FontWeight.w600),
          headlineSmall: TextStyle(color: textoPrimario, fontWeight: FontWeight.w600),
          titleLarge: TextStyle(color: textoPrimario, fontWeight: FontWeight.w600),
          titleMedium: TextStyle(color: textoPrimario, fontWeight: FontWeight.w500),
          titleSmall: TextStyle(color: textoSecundario, fontWeight: FontWeight.w500),
          bodyLarge: TextStyle(color: textoPrimario),
          bodyMedium: TextStyle(color: textoSecundario),
          bodySmall: TextStyle(color: textoTerciario),
          labelLarge: TextStyle(color: textoPrimario, fontWeight: FontWeight.w600),
          labelMedium: TextStyle(color: textoSecundario),
          labelSmall: TextStyle(color: textoTerciario),
        ),
      ),
      cardTheme: CardThemeData(
        color: fondoCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: bordeCard, width: 1),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: fondoSecundario,
        elevation: 0,
        titleTextStyle: GoogleFonts.poppins(
          color: textoPrimario,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: const IconThemeData(color: textoPrimario),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: fondoSecundario,
        indicatorColor: azulElectrico.withOpacity(0.2),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.poppins(
              color: azulElectrico,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            );
          }
          return GoogleFonts.poppins(
            color: textoTerciario,
            fontSize: 12,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: azulElectrico);
          }
          return const IconThemeData(color: grisInactivo);
        }),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: azulElectrico,
          foregroundColor: textoPrimario,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: bordeCard,
        thickness: 1,
      ),
    );
  }

  // ─── Helpers de color por latencia ────────────────────────────────────────
  static Color colorLatencia(double? latenciaMs) {
    if (latenciaMs == null) return grisInactivo;
    if (latenciaMs < 20) return verdeActivo;
    if (latenciaMs < 80) return verdeClaro;
    if (latenciaMs < 200) return amarilloLatencia;
    return rojoAlerta;
  }

  static String textoLatencia(double? latenciaMs) {
    if (latenciaMs == null) return 'Sin respuesta';
    return '${latenciaMs.toStringAsFixed(1)} ms';
  }

  // ─── Gradientes ───────────────────────────────────────────────────────────
  static const LinearGradient gradientePrincipal = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [azulElectrico, Color(0xFF6B31FF)],
  );

  static const LinearGradient gradienteFondo = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [fondoPrincipal, fondoSecundario],
  );

  // ─── Sombras ──────────────────────────────────────────────────────────────
  static List<BoxShadow> get sombraCard => [
    BoxShadow(
      color: Colors.black.withOpacity(0.3),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get sombraBotonAzul => [
    BoxShadow(
      color: azulElectrico.withOpacity(0.4),
      blurRadius: 20,
      offset: const Offset(0, 6),
    ),
  ];
}
