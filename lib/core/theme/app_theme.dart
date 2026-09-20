import 'package:flutter/material.dart';

/// Centralized design tokens for FixNow.
/// All colors, text styles, radius, and spacing live here.
class AppColors {
  AppColors._();

  // ── Primary palette ──────────────────────────────────────────────
  static const Color primary = Color(0xFF2F6BFF);
  static const Color primaryLight = Color(0xFF6B9AFF);
  static const Color primaryDark = Color(0xFF1A4FD9);
  static const Color primaryContainer = Color(0xFFDDE6FF);

  // ── Accent palette ───────────────────────────────────────────────
  static const Color accent = Color(0xFFFF6B3D);
  static const Color accentLight = Color(0xFFFF9466);
  static const Color accentDark = Color(0xFFE85A2F);

  // ── Neutrals ─────────────────────────────────────────────────────
  static const Color white = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF8F9FC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE8ECF2);
  static const Color textPrimary = Color(0xFF1A1D26);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textHint = Color(0xFF9CA3AF);
  static const Color divider = Color(0xFFF1F3F6);

  // ── Semantic ─────────────────────────────────────────────────────
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFFBBF24);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // ── Service category colors (pastel) ─────────────────────────────
  static const Color plomberie = Color(0xFF3B82F6);
  static const Color electricite = Color(0xFFFBBF24);
  static const Color menuiserie = Color(0xFF8B5CF6);
  static const Color peinture = Color(0xFFEC4899);
  static const Color maconnerie = Color(0xFFF97316);
  static const Color soudure = Color(0xFF6B7280);
  static const Color couverture = Color(0xFF14B8A6);
  static const Color menage = Color(0xFF22C55E);
  static const Color serrurerie = Color(0xFF6366F1);
  static const Color mecanique = Color(0xFFEF4444);

  // ── Pastel backgrounds for category icons ────────────────────────
  static const Color plomberieLight = Color(0xFFDBEAFE);
  static const Color electriciteLight = Color(0xFFFEF3C7);
  static const Color menuiserieLight = Color(0xFFEDE9FE);
  static const Color peintureLight = Color(0xFFFCE7F3);
  static const Color maconnerieLight = Color(0xFFFFF7ED);
  static const Color soudureLight = Color(0xFFF3F4F6);
  static const Color couvertureLight = Color(0xFFCCFBF1);
  static const Color menageLight = Color(0xFFDCFCE7);
  static const Color serrurerieLight = Color(0xFFE0E7FF);
  static const Color mecaniqueLight = Color(0xFFFEE2E2);

  // ── Dark mode tokens (used by ThemeData dark) ────────────────────
  static const Color darkBackground = Color(0xFF12141B);
  static const Color darkSurface = Color(0xFF1B1E28);
  static const Color darkBorder = Color(0xFF2A2E3C);
  static const Color darkTextPrimary = Color(0xFFF2F4F9);
  static const Color darkTextSecondary = Color(0xFF9CA3B5);
  static const Color darkTextHint = Color(0xFF6B7285);
  static const Color darkPrimaryContainer = Color(0xFF23324F);
}

/// Spacing tokens — multiples of 4px for consistency.
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double xxxxl = 40;
  static const double xxxxxl = 48;
}

/// Border radius tokens.
class AppRadius {
  AppRadius._();

  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double full = 999;

  static BorderRadius get smAll => BorderRadius.circular(sm);
  static BorderRadius get mdAll => BorderRadius.circular(md);
  static BorderRadius get lgAll => BorderRadius.circular(lg);
  static BorderRadius get xlAll => BorderRadius.circular(xl);
  static BorderRadius get xxlAll => BorderRadius.circular(xxl);
  static BorderRadius get fullAll => BorderRadius.circular(full);
}

/// Text styles using the Poppins font.
class AppTextStyles {
  AppTextStyles._();

  static const String _fontFamily = 'Poppins';

  // ── Headings ─────────────────────────────────────────────────────
  static const TextStyle h1 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.2,
  );

  static const TextStyle h2 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static const TextStyle h3 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static const TextStyle h4 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  // ── Body ─────────────────────────────────────────────────────────
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  // ── Labels / Captions ────────────────────────────────────────────
  static const TextStyle label = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
    height: 1.3,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: AppColors.textHint,
    height: 1.3,
  );

  // ── Buttons ──────────────────────────────────────────────────────
  static const TextStyle buttonLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );

  static const TextStyle buttonMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );

  static const TextStyle buttonSmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );
}

/// Elevation & shadow tokens.
class AppShadows {
  AppShadows._();

  static List<BoxShadow> get sm => [
        BoxShadow(
          color: AppColors.textPrimary.withValues(alpha: 0.05),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get md => [
        BoxShadow(
          color: AppColors.textPrimary.withValues(alpha: 0.08),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get lg => [
        BoxShadow(
          color: AppColors.textPrimary.withValues(alpha: 0.12),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];
}

/// The full light theme. Dark theme can be added later.
class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        fontFamily: AppTextStyles._fontFamily,
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.light(
          primary: AppColors.primary,
          onPrimary: AppColors.white,
          secondary: AppColors.accent,
          onSecondary: AppColors.white,
          surface: AppColors.surface,
          onSurface: AppColors.textPrimary,
          error: AppColors.error,
          onError: AppColors.white,
        ),
        extensions: const [SemanticColors.light],
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          scrolledUnderElevation: 1,
          centerTitle: false,
          titleTextStyle: AppTextStyles.h3,
        ),
        cardTheme: CardThemeData(
          color: AppColors.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.lgAll,
            side: const BorderSide(color: AppColors.border, width: 1),
          ),
          margin: EdgeInsets.zero,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            textStyle: AppTextStyles.buttonLarge,
            elevation: 0,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.lg,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: AppRadius.lgAll,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            backgroundColor: AppColors.white,
            textStyle: AppTextStyles.buttonLarge,
            elevation: 0,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.lg,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: AppRadius.lgAll,
            ),
            side: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          hintStyle: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textHint,
          ),
          border: OutlineInputBorder(
            borderRadius: AppRadius.lgAll,
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: AppRadius.lgAll,
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: AppRadius.lgAll,
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: AppColors.white,
          indicatorColor: AppColors.primary.withValues(alpha: 0.1),
          elevation: 0,
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppTextStyles.caption.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              );
            }
            return AppTextStyles.caption;
          }),
        ),
      );

  // Dark theme — same structure/tokens as light, dark palette.
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        fontFamily: AppTextStyles._fontFamily,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.darkBackground,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primaryLight,
          onPrimary: AppColors.white,
          secondary: AppColors.accentLight,
          onSecondary: AppColors.white,
          surface: AppColors.darkSurface,
          onSurface: AppColors.darkTextPrimary,
          error: AppColors.error,
          onError: AppColors.white,
          primaryContainer: AppColors.darkPrimaryContainer,
          onPrimaryContainer: AppColors.darkTextPrimary,
        ),
        extensions: const [SemanticColors.dark],
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.darkBackground,
          foregroundColor: AppColors.darkTextPrimary,
          elevation: 0,
          scrolledUnderElevation: 1,
          centerTitle: false,
          titleTextStyle: TextStyle(
            fontFamily: AppTextStyles._fontFamily,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.darkTextPrimary,
            height: 1.3,
          ),
        ),
        cardTheme: CardThemeData(
          color: AppColors.darkSurface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.lgAll,
            side: const BorderSide(color: AppColors.darkBorder, width: 1),
          ),
          margin: EdgeInsets.zero,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            textStyle: AppTextStyles.buttonLarge,
            elevation: 0,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.lg,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: AppRadius.lgAll,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primaryLight,
            backgroundColor: Colors.transparent,
            textStyle: AppTextStyles.buttonLarge,
            elevation: 0,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.lg,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: AppRadius.lgAll,
            ),
            side: const BorderSide(color: AppColors.primaryLight, width: 1.5),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.darkSurface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          hintStyle: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.darkTextHint,
          ),
          border: OutlineInputBorder(
            borderRadius: AppRadius.lgAll,
            borderSide: const BorderSide(color: AppColors.darkBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: AppRadius.lgAll,
            borderSide: const BorderSide(color: AppColors.darkBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: AppRadius.lgAll,
            borderSide:
                const BorderSide(color: AppColors.primaryLight, width: 1.5),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: AppColors.darkSurface,
          indicatorColor: AppColors.primaryLight.withValues(alpha: 0.15),
          elevation: 0,
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppTextStyles.caption.copyWith(
                color: AppColors.primaryLight,
                fontWeight: FontWeight.w600,
              );
            }
            return AppTextStyles.caption;
          }),
        ),
      );
}

/// Semantic colors that adapt to brightness (success, warning, info…).
/// Access via `context.semanticColors.success`.
class SemanticColors extends ThemeExtension<SemanticColors> {
  final Color success;
  final Color warning;
  final Color info;
  final Color accent;
  final Color neutral;

  const SemanticColors({
    required this.success,
    required this.warning,
    required this.info,
    required this.accent,
    required this.neutral,
  });

  static const light = SemanticColors(
    success: Color(0xFF16A34A),
    warning: Color(0xFFD97706),
    info: Color(0xFF2563EB),
    accent: Color(0xFFE85A2F),
    neutral: Color(0xFF6B7280),
  );

  static const dark = SemanticColors(
    success: Color(0xFF4ADE80),
    warning: Color(0xFFFBBF24),
    info: Color(0xFF60A5FA),
    accent: Color(0xFFFF9466),
    neutral: Color(0xFF9CA3B5),
  );

  @override
  SemanticColors copyWith({
    Color? success,
    Color? warning,
    Color? info,
    Color? accent,
    Color? neutral,
  }) {
    return SemanticColors(
      success: success ?? this.success,
      warning: warning ?? this.warning,
      info: info ?? this.info,
      accent: accent ?? this.accent,
      neutral: neutral ?? this.neutral,
    );
  }

  @override
  SemanticColors lerp(SemanticColors? other, double t) {
    if (other == null) return this;
    return SemanticColors(
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      info: Color.lerp(info, other.info, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      neutral: Color.lerp(neutral, other.neutral, t)!,
    );
  }
}

/// Extension on BuildContext for semantic colors.
extension SemanticColorsX on BuildContext {
  SemanticColors get semanticColors =>
      Theme.of(this).extension<SemanticColors>() ?? SemanticColors.light;
}
