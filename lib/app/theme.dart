import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // Corner radius standards:
  // - radiusSmall / radiusDefault (4.0): Viewfinder chrome, bottom sheets, buttons, dialogs
  // - radiusLibrary (16.0): Exclusively for Pose Library grid cards for a tactile, photo-browsing aesthetic
  static const double radiusSmall = 4.0;
  static const double radiusDefault = 4.0;
  static const double radiusLibrary = 16.0;
  static final BorderRadius borderRadius = BorderRadius.circular(radiusSmall);

  // Light Mode Palette
  static const Color lightBgPrimary = Color(0xFFFFFFFF);
  static const Color lightBgElevated = Color(0xFFF5F5F5);
  static const Color lightTextPrimary = Color(0xFF0A0A0A);
  static const Color lightTextSecondary = Color(0xFF6B6B6B);
  static const Color lightBorderHairline = Color(0xFFE0E0E0);
  static const Color lightShutterFill = Color(0xFF0A0A0A);
  static const Color lightShutterRing = Color(0xFFFFFFFF);

  // Dark Mode Palette
  static const Color darkBgPrimary = Color(0xFF0A0A0A);
  static const Color darkBgElevated = Color(0xFF1A1A1A);
  static const Color darkTextPrimary = Color(0xFFFAFAFA);
  static const Color darkTextSecondary = Color(0xFF9A9A9A);
  static const Color darkBorderHairline = Color(0xFF2A2A2A);
  static const Color darkShutterFill = Color(0xFFFAFAFA);
  static const Color darkShutterRing = Color(0xFF0A0A0A);

  // Common Viewfinder Control Surface
  static final Color controlSurface = Colors.black.withValues(alpha: 0.55);

  // Grayscale matrix for pose overlays
  static const List<double> grayscaleMatrix = <double>[
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0,      0,      0,      1, 0,
  ];

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBgPrimary,
      colorScheme: const ColorScheme.light(
        surface: lightBgPrimary,
        primary: lightTextPrimary,
        onSurface: lightTextPrimary,
        onPrimary: lightBgPrimary,
        outline: lightBorderHairline,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: lightBgPrimary,
        foregroundColor: lightTextPrimary,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          color: lightTextPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: lightTextPrimary, size: 20),
      ),
      cardTheme: CardThemeData(
        color: lightBgElevated,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
          side: const BorderSide(color: lightBorderHairline, width: 1),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: lightBgElevated,
        selectedColor: lightTextPrimary,
        labelStyle: const TextStyle(
          color: lightTextPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        secondaryLabelStyle: const TextStyle(
          color: lightBgPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
          side: const BorderSide(color: lightBorderHairline, width: 1),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: lightTextPrimary,
        inactiveTrackColor: lightBorderHairline,
        thumbColor: lightTextPrimary,
        overlayColor: lightTextPrimary.withValues(alpha: 0.1),
        trackHeight: 2,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: lightBgPrimary,
        modalBackgroundColor: lightBgPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radiusSmall)),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: lightBorderHairline,
        thickness: 1,
        space: 1,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBgPrimary,
      colorScheme: const ColorScheme.dark(
        surface: darkBgPrimary,
        primary: darkTextPrimary,
        onSurface: darkTextPrimary,
        onPrimary: darkBgPrimary,
        outline: darkBorderHairline,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBgPrimary,
        foregroundColor: darkTextPrimary,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          color: darkTextPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: darkTextPrimary, size: 20),
      ),
      cardTheme: CardThemeData(
        color: darkBgElevated,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
          side: const BorderSide(color: darkBorderHairline, width: 1),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: darkBgElevated,
        selectedColor: darkTextPrimary,
        labelStyle: const TextStyle(
          color: darkTextPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        secondaryLabelStyle: const TextStyle(
          color: darkBgPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
          side: const BorderSide(color: darkBorderHairline, width: 1),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: darkTextPrimary,
        inactiveTrackColor: darkBorderHairline,
        thumbColor: darkTextPrimary,
        overlayColor: darkTextPrimary.withValues(alpha: 0.15),
        trackHeight: 2,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: darkBgPrimary,
        modalBackgroundColor: darkBgPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radiusSmall)),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: darkBorderHairline,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
