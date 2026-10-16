import 'package:flutter/material.dart';

import 'brand_tokens.dart';

/// The app's Material theme, following brand/README.md: paper background,
/// white cards with a fine border, Marktrot for actions, pill buttons.
ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: BrandColors.red).copyWith(
    primary: BrandColors.red,
    onPrimary: BrandColors.white,
    secondary: BrandColors.ink,
    onSecondary: BrandColors.white,
    tertiary: BrandColors.gold,
    onTertiary: BrandColors.ink,
    surface: BrandColors.paper,
    onSurface: BrandColors.ink,
    onSurfaceVariant: BrandColors.inkSoft,
    surfaceContainerLowest: BrandColors.white,
    surfaceContainerLow: BrandColors.white,
    surfaceContainer: BrandColors.sand,
    surfaceContainerHigh: BrandColors.sand,
    surfaceContainerHighest: BrandColors.line,
    outline: BrandColors.inkSoft,
    outlineVariant: BrandColors.line,
  );
  const pill = StadiumBorder();
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: BrandColors.paper,
    appBarTheme: const AppBarTheme(
      backgroundColor: BrandColors.paper,
      foregroundColor: BrandColors.ink,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0.5,
    ),
    cardTheme: CardThemeData(
      color: BrandColors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: BrandColors.line),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(shape: pill)),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: pill,
        foregroundColor: BrandColors.ink,
        side: const BorderSide(color: BrandColors.ink, width: 1.5),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: pill,
        backgroundColor: BrandColors.red,
        foregroundColor: BrandColors.white,
      ),
    ),
    chipTheme: const ChipThemeData(shape: pill, side: BorderSide(color: BrandColors.line)),
    navigationBarTheme: const NavigationBarThemeData(backgroundColor: BrandColors.white),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: BrandColors.white,
      selectedItemColor: BrandColors.red,
      unselectedItemColor: BrandColors.inkSoft,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: BrandColors.white,
      surfaceTintColor: Colors.transparent,
    ),
    dialogTheme: const DialogThemeData(backgroundColor: BrandColors.white, surfaceTintColor: Colors.transparent),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: BrandColors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: BrandColors.line)),
      enabledBorder:
          OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: BrandColors.line)),
    ),
    dividerTheme: const DividerThemeData(color: BrandColors.line),
  );
}
