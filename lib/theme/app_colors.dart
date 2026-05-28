import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF336A29);
  static const primaryLight = Color(0xFF4CAF50);
  static const primaryDark = Color(0xFF1B5E20);

  static const darkBackground = Color(0xFF121212);
  static const darkSurface = Color(0xFF1E1E1E);
  static const darkCard = Color(0xFF2C2C2C);
  static const darkBorder = Color(0xFF3C3C3C);

  static const lightBackground = Color(0xFFF4F6F0);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightCard = Color(0xFFFFFFFF);
  static const lightBorder = Color(0xFFDDE8DC);

  static const success = Color(0xFF16A34A);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFDC2626);

  static const textPrimary = Color(0xFF1A1A1A);
  static const textSecondary = Color(0xFF6B7280);

  static const sensorTemp = Color(0xFFE53935);
  static const sensorHumidity = Color(0xFF1E88E5);
  static const sensorSoil = Color(0xFF43A047);
  static const sensorLight = Color(0xFFFB8A04);
}

class ThemeColors {
  static Color background(bool isDark) =>
      isDark ? AppColors.darkBackground : AppColors.lightBackground;

  static Color scaffoldBackground(bool isDark) =>
      isDark ? AppColors.darkBackground : AppColors.lightBackground;

  static Color appBar(bool isDark) =>
      isDark ? AppColors.darkSurface : AppColors.primary;

  static Color card(bool isDark) =>
      isDark ? AppColors.darkCard : AppColors.lightCard;

  static Color surface(bool isDark) =>
      isDark ? AppColors.darkSurface : AppColors.lightSurface;

  static Color text(bool isDark) =>
      isDark ? Colors.white : AppColors.textPrimary;

  static Color secondaryText(bool isDark) =>
      isDark ? Colors.white70 : AppColors.textSecondary;

  static Color border(bool isDark) =>
      isDark ? AppColors.darkBorder : AppColors.lightBorder;

  static Color inputFill(bool isDark) =>
      isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF7FAF8);

  static Color icon(bool isDark) =>
      isDark ? Colors.white70 : AppColors.textPrimary;

  static Color shadow(bool isDark) =>
      isDark ? Colors.black.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.07);

  static Color errorBanner(bool isDark) =>
      isDark ? const Color(0xFFFFCDD2) : const Color(0xFFFFEBEE);

  static Color errorColor(bool isDark) =>
      isDark ? const Color(0xFFEF9A9A) : const Color(0xFFC62828);
}

class AppDecorations {
  static BoxDecoration cardDecoration(bool isDark, {Color? color}) {
    return BoxDecoration(
      color: color ?? ThemeColors.card(isDark),
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: ThemeColors.shadow(isDark),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  static BoxDecoration appBarDecoration(bool isDark) {
    return BoxDecoration(
      color: ThemeColors.appBar(isDark),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.1),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }
}

class AppTextStyles {
  static TextStyle heading(bool isDark) => TextStyle(
        color: ThemeColors.text(isDark),
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      );

  static TextStyle body(bool isDark) => TextStyle(
        color: ThemeColors.text(isDark),
        fontSize: 15,
        fontWeight: FontWeight.w500,
      );

  static TextStyle secondary(bool isDark) => TextStyle(
        color: ThemeColors.secondaryText(isDark),
        fontSize: 13,
        fontWeight: FontWeight.w400,
      );

  static TextStyle caption(bool isDark) => TextStyle(
        color: ThemeColors.secondaryText(isDark),
        fontSize: 12,
      );
}