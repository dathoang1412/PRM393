import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// App-wide light theme with a scholarly "ink & paper" look: serif (Lora)
/// display/headline/title text over a warm paper background, Inter for body
/// and labels, deep ink-blue primary with a reserved bronze accent.
class AppTheme {
  const AppTheme._();

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      primary: AppColors.primary,
      secondary: AppColors.series1Blue,
      tertiary: AppColors.accent,
      surface: AppColors.surface,
      onPrimary: Colors.white,
      onSurface: AppColors.ink,
      error: AppColors.danger,
    );

    final serif = GoogleFonts.frauncesTextTheme();
    final sans = GoogleFonts.interTextTheme();
    final textTheme = sans
        .copyWith(
          displayLarge: serif.displayLarge,
          displayMedium: serif.displayMedium,
          displaySmall: serif.displaySmall,
          headlineLarge: serif.headlineLarge,
          headlineMedium: serif.headlineMedium,
          headlineSmall: serif.headlineSmall,
          titleLarge: serif.titleLarge,
        )
        .apply(
          bodyColor: AppColors.ink,
          displayColor: AppColors.primaryDark,
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.paper,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.primaryDark,
        surfaceTintColor: Colors.transparent,
        shadowColor: const Color(0x14000000),
        titleTextStyle: GoogleFonts.fraunces(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.primaryDark,
          letterSpacing: -0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border),
        ),
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        hintStyle: TextStyle(
          color: AppColors.inkSecondary.withValues(alpha: 0.7),
          fontSize: 14,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            letterSpacing: 0.1,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.wash,
        selectedColor: AppColors.primary,
        labelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.ink,
        contentTextStyle: GoogleFonts.inter(
          fontSize: 13,
          color: Colors.white,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 62,
        indicatorColor: AppColors.primary.withValues(alpha: 0.1),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return GoogleFonts.inter(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? AppColors.primary : AppColors.inkSecondary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? AppColors.primary : AppColors.inkMuted,
            size: 22,
          );
        }),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primary.withValues(alpha: 0.1),
        selectedIconTheme:
            const IconThemeData(color: AppColors.primary, size: 22),
        unselectedIconTheme:
            const IconThemeData(color: AppColors.inkMuted, size: 22),
        selectedLabelTextStyle: GoogleFonts.inter(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
        unselectedLabelTextStyle: GoogleFonts.inter(
          color: AppColors.inkSecondary,
          fontWeight: FontWeight.w500,
          fontSize: 11,
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelStyle: GoogleFonts.inter(
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontWeight: FontWeight.w400,
          fontSize: 13,
        ),
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.inkSecondary,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: AppColors.border,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        space: 1,
        thickness: 1,
      ),
    );
  }
}
