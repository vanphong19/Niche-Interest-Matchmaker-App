// lib/core/theme/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ─── Primary Palette (Modern Blue) ─────────────────────────────────
  static const Color primary = Color(0xFF1E88E5);       // Vivid Blue
  static const Color primaryLight = Color(0xFF42A5F5);   // Light Blue
  static const Color primaryDark = Color(0xFF1565C0);    // Deep Blue
  static const Color primarySurface = Color(0xFFE3F2FD); // Blue surface tint

  // ─── Secondary Palette ────────────────────────────────────────────
  static const Color secondary = Color(0xFF0F172A);      // Slate-900
  static const Color secondaryMedium = Color(0xFF334155); // Slate-700
  static const Color secondaryLight = Color(0xFF64748B);  // Slate-500

  // ─── Accent ───────────────────────────────────────────────────────
  static const Color accent = Color(0xFF06B6D4);         // Cyan accent
  static const Color accentLight = Color(0xFF67E8F9);    // Cyan light

  // ─── Background ───────────────────────────────────────────────────
  static const Color bgPrimary = Color(0xFFFFFFFF);
  static const Color bgSecondary = Color(0xFFF8FAFC);    // Slate-50
  static const Color bgTertiary = Color(0xFFF1F5F9);     // Slate-100

  // ─── Text ─────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF0F172A);    // Slate-900
  static const Color textSecondary = Color(0xFF64748B);  // Slate-500
  static const Color textHint = Color(0xFF94A3B8);       // Slate-400
  static const Color textInverse = Color(0xFFFFFFFF);
  static const Color textLink = Color(0xFF1E88E5);

  // ─── Semantic ─────────────────────────────────────────────────────
  static const Color success = Color(0xFF10B981);        // Emerald-500
  static const Color successLight = Color(0xFFD1FAE5);   // Emerald-100
  static const Color error = Color(0xFFEF4444);          // Red-500
  static const Color errorLight = Color(0xFFFEE2E2);    // Red-100
  static const Color warning = Color(0xFFF59E0B);        // Amber-500
  static const Color warningLight = Color(0xFFFEF3C7);   // Amber-100
  static const Color info = Color(0xFF3B82F6);           // Blue-500
  static const Color infoLight = Color(0xFFDBEAFE);      // Blue-100

  // ─── Border ───────────────────────────────────────────────────────
  static const Color borderLight = Color(0xFFE2E8F0);   // Slate-200
  static const Color borderMedium = Color(0xFFCBD5E1);  // Slate-300
  static const Color borderDark = Color(0xFF94A3B8);     // Slate-400

  // ─── Shadow ───────────────────────────────────────────────────────
  static const Color shadowLight = Color(0x0F000000);
  static const Color shadowMedium = Color(0x1A000000);
  static const Color shadowDark = Color(0x33000000);

  // ─── Event Category Colors ────────────────────────────────────────
  static const Color categorySports = Color(0xFFEF4444);  // Red
  static const Color categoryDining = Color(0xFFF59E0B);  // Amber
  static const Color categorySocial = Color(0xFF3B82F6);  // Blue
  static const Color categoryArts = Color(0xFF8B5CF6);    // Violet
  static const Color categoryOutdoors = Color(0xFF10B981);// Emerald
  static const Color categoryGaming = Color(0xFFF97316);  // Orange
  static const Color categoryMusic = Color(0xFFEC4899);   // Pink
  static const Color categoryTech = Color(0xFF06B6D4);    // Cyan

  // ─── Gradients ────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient primaryVerticalGradient = LinearGradient(
    colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// Premium hero gradient — blue → cyan/teal
  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF0D47A1), Color(0xFF1E88E5), Color(0xFF00ACC1)],
    stops: [0.0, 0.5, 1.0],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Vibrant splash gradient
  static const LinearGradient splashGradient = LinearGradient(
    colors: [Color(0xFF0D47A1), Color(0xFF1976D2), Color(0xFF00BCD4)],
    stops: [0.0, 0.4, 1.0],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFF6D365), Color(0xFFFDA085)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF06B6D4), Color(0xFF3B82F6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ─── Dark Mode Colors ─────────────────────────────────────────────
  static const Color darkBgPrimary = Color(0xFF0F172A);
  static const Color darkBgSecondary = Color(0xFF1E293B);
  static const Color darkBgTertiary = Color(0xFF334155);
  static const Color darkBgElevated = Color(0xFF475569);

  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkTextHint = Color(0xFF64748B);

  static const Color darkBorderLight = Color(0xFF334155);
  static const Color darkBorderMedium = Color(0xFF475569);

  static const Color darkCardBackground = Color(0xFF1E293B);
  static const Color darkSurface = Color(0xFF334155);

  static const Color darkPrimarySurface = Color(0xFF172554);

  // ─── Shimmer Colors ───────────────────────────────────────────────
  static const Color shimmerBase = Color(0xFFE2E8F0);
  static const Color shimmerHighlight = Color(0xFFF1F5F9);
  static const Color darkShimmerBase = Color(0xFF334155);
  static const Color darkShimmerHighlight = Color(0xFF475569);

  // ─── Match Score Colors ───────────────────────────────────────────
  static const Color matchGold = Color(0xFFFFD700);
  static const Color matchBlue = Color(0xFF1E88E5);
  static const Color matchGray = Color(0xFF94A3B8);

  // ─── Helpers ──────────────────────────────────────────────────────
  static Color withOpacity(Color color, double opacity) {
    return color.withValues(alpha: opacity);
  }

  static Color getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'sports':
        return categorySports;
      case 'dining':
      case 'food':
        return categoryDining;
      case 'social':
        return categorySocial;
      case 'arts':
      case 'art':
        return categoryArts;
      case 'outdoors':
      case 'outdoor':
        return categoryOutdoors;
      case 'gaming':
      case 'games':
        return categoryGaming;
      case 'music':
        return categoryMusic;
      case 'tech':
      case 'technology':
        return categoryTech;
      default:
        return primary;
    }
  }
}
