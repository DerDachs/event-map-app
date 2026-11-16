import 'package:flutter/material.dart';

import 'brand_tokens.dart';

/// Headline style of the brand: Bebas Neue, weight 400 (the font has no bold,
/// never fake one). The font only has capitals, so no case change is needed.
TextStyle brandDisplay(double size, {Color color = BrandColors.ink, double letterSpacing = 0.6}) => TextStyle(
      fontFamily: 'Bebas Neue',
      fontSize: size,
      fontWeight: FontWeight.w400,
      height: 1.05,
      letterSpacing: letterSpacing,
      color: color,
    );

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
    fontFamily: 'Figtree',
    colorScheme: scheme,
    scaffoldBackgroundColor: BrandColors.paper,
    appBarTheme: AppBarTheme(
      backgroundColor: BrandColors.paper,
      foregroundColor: BrandColors.ink,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0.5,
      titleTextStyle: brandDisplay(30),
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
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: pill,
        minimumSize: const Size(64, 48),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: pill,
        minimumSize: const Size(64, 48),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
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
    // Bottom navigation: white bar, the selected item sits in a soft gold pill.
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: BrandColors.white,
      surfaceTintColor: Colors.transparent,
      indicatorColor: BrandColors.goldSoft,
      height: 68,
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected) ? BrandColors.red : BrandColors.inkSoft,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontSize: 12,
          fontWeight: states.contains(WidgetState.selected) ? FontWeight.w600 : FontWeight.w400,
          color: states.contains(WidgetState.selected) ? BrandColors.ink : BrandColors.inkSoft,
        ),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: BrandColors.ink,
      contentTextStyle: const TextStyle(color: BrandColors.white, fontSize: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
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
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: BrandColors.line)),
      enabledBorder:
          OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: BrandColors.line)),
      focusedBorder:
          OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: BrandColors.red, width: 2)),
    ),
    dividerTheme: const DividerThemeData(color: BrandColors.line),
  );
}
