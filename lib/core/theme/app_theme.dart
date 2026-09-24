import 'package:flutter/material.dart';

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// DESIGN TOKENS — FixNow Design System (Material 3)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// Centralized color tokens for FixNow.
///
/// Naming follows Material 3 conventions: primary, secondary/tertiary,
/// surface hierarchy (surface → surfaceContainer → …), semantic colors.
class AppColors {
  AppColors._();

  // ── Primary palette ──────────────────────────────────────────────
  static const Color primary = Color(0xFF2F6BFF);
  static const Color primaryLight = Color(0xFF6B9AFF);
  static const Color primaryDark = Color(0xFF1A4FD9);
  static const Color primaryContainer = Color(0xFFDDE6FF);
  static const Color onPrimaryContainer = Color(0xFF001A4A);

  // ── Secondary (accent) palette ───────────────────────────────────
  static const Color accent = Color(0xFFFF6B3D);
  static const Color accentLight = Color(0xFFFF9466);
  static const Color accentDark = Color(0xFFE85A2F);
  static const Color secondaryContainer = Color(0xFFFFF0E8);
  static const Color onSecondaryContainer = Color(0xFF3D1600);

  // ── Tertiary palette ─────────────────────────────────────────────
  static const Color tertiary = Color(0xFF7C5800);
  static const Color tertiaryLight = Color(0xFFFFBF00);
  static const Color tertiaryContainer = Color(0xFFFFF3D6);

  // ── Neutrals ─────────────────────────────────────────────────────
  static const Color white = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF7F8FB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceDim = Color(0xFFF0F2F5);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF7F8FB);
  static const Color surfaceContainer = Color(0xFFF0F2F5);
  static const Color surfaceContainerHigh = Color(0xFFE8EAEE);
  static const Color surfaceContainerHighest = Color(0xFFE0E2E6);
  static const Color border = Color(0xFFE2E5EA);
  static const Color borderLight = Color(0xFFEEF0F4);
  static const Color outline = Color(0xFFC4C8CE);
  static const Color outlineVariant = Color(0xFFDFE1E6);
  static const Color textPrimary = Color(0xFF1A1D26);
  static const Color textSecondary = Color(0xFF5F6577);
  static const Color textTertiary = Color(0xFF8B90A0);
  static const Color textHint = Color(0xFF9CA3AF);
  static const Color divider = Color(0xFFECEDF1);
  static const Color disabled = Color(0xFFD1D5DB);
  static const Color onDisabled = Color(0xFF9CA3AF);

  // ── Semantic ─────────────────────────────────────────────────────
  static const Color success = Color(0xFF22C55E);
  static const Color successLight = Color(0xFFDCFCE7);
  static const Color warning = Color(0xFFFBBF24);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFFDBEAFE);

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

  // ── Dark mode ────────────────────────────────────────────────────
  static const Color darkBackground = Color(0xFF0F1118);
  static const Color darkSurface = Color(0xFF161820);
  static const Color darkSurfaceDim = Color(0xFF12141B);
  static const Color darkSurfaceContainerLowest = Color(0xFF0D0F15);
  static const Color darkSurfaceContainerLow = Color(0xFF161820);
  static const Color darkSurfaceContainer = Color(0xFF1C1F28);
  static const Color darkSurfaceContainerHigh = Color(0xFF22252F);
  static const Color darkSurfaceContainerHighest = Color(0xFF2A2D38);
  static const Color darkBorder = Color(0xFF2A2D38);
  static const Color darkOutline = Color(0xFF3A3D48);
  static const Color darkTextPrimary = Color(0xFFF0F2F7);
  static const Color darkTextSecondary = Color(0xFF9BA1B5);
  static const Color darkTextTertiary = Color(0xFF6B7285);
  static const Color darkTextHint = Color(0xFF5A6178);
  static const Color darkDivider = Color(0xFF252830);
  static const Color darkPrimaryContainer = Color(0xFF1E2D4D);
}

/// Spacing tokens — consistent 4px grid.
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

/// Border radius tokens — softer radii for modern Material 3 feel.
class AppRadius {
  AppRadius._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double full = 999;

  static BorderRadius get xsAll => BorderRadius.circular(xs);
  static BorderRadius get smAll => BorderRadius.circular(sm);
  static BorderRadius get mdAll => BorderRadius.circular(md);
  static BorderRadius get lgAll => BorderRadius.circular(lg);
  static BorderRadius get xlAll => BorderRadius.circular(xl);
  static BorderRadius get xxlAll => BorderRadius.circular(xxl);
  static BorderRadius get fullAll => BorderRadius.circular(full);
}

/// Typography — Poppins with clear hierarchy.
///
/// Scale: display(36) → h1(28) → h2(22) → h3(18) → h4(16)
///        → bodyLarge(16) → bodyMedium(14) → bodySmall(12) → caption(11)
class AppTextStyles {
  AppTextStyles._();

  static const String _fontFamily = 'Poppins';

  // ── Display (hero / splash) ──────────────────────────────────────
  static const TextStyle displayLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 36,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    height: 1.15,
    letterSpacing: -0.5,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.15,
    letterSpacing: -0.3,
  );

  // ── Headings ─────────────────────────────────────────────────────
  static const TextStyle h1 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.2,
    letterSpacing: -0.3,
  );

  static const TextStyle h2 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.25,
    letterSpacing: -0.2,
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
    height: 1.35,
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
    height: 1.45,
  );

  // ── Labels / Captions ────────────────────────────────────────────
  static const TextStyle label = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
    height: 1.3,
    letterSpacing: 0.1,
  );

  static const TextStyle labelLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
    height: 1.3,
    letterSpacing: 0.1,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: AppColors.textTertiary,
    height: 1.35,
    letterSpacing: 0.1,
  );

  // ── Buttons ──────────────────────────────────────────────────────
  static const TextStyle buttonLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: 0.1,
  );

  static const TextStyle buttonMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: 0.1,
  );

  static const TextStyle buttonSmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: 0.1,
  );
}

/// Elevation & shadow tokens — softer, more diffused.
class AppShadows {
  AppShadows._();

  /// Subtle resting shadow (cards at rest).
  static List<BoxShadow> get sm => [
        BoxShadow(
          color: AppColors.textPrimary.withValues(alpha: 0.04),
          blurRadius: 6,
          offset: const Offset(0, 1),
        ),
        BoxShadow(
          color: AppColors.textPrimary.withValues(alpha: 0.03),
          blurRadius: 12,
          offset: const Offset(0, 2),
        ),
      ];

  /// Hover / elevated shadow.
  static List<BoxShadow> get md => [
        BoxShadow(
          color: AppColors.textPrimary.withValues(alpha: 0.06),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: AppColors.textPrimary.withValues(alpha: 0.03),
          blurRadius: 20,
          offset: const Offset(0, 2),
        ),
      ];

  /// Floating / prominent shadow.
  static List<BoxShadow> get lg => [
        BoxShadow(
          color: AppColors.textPrimary.withValues(alpha: 0.08),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: AppColors.textPrimary.withValues(alpha: 0.04),
          blurRadius: 40,
          offset: const Offset(0, 4),
        ),
      ];
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// THEMES
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// App themes (light + dark) — Material 3 with custom extensions.
class AppTheme {
  AppTheme._();

  // ────────────────────────────────────────────────────────────────
  //  LIGHT
  // ────────────────────────────────────────────────────────────────
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        fontFamily: AppTextStyles._fontFamily,
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.light(
          primary: AppColors.primary,
          onPrimary: AppColors.white,
          primaryContainer: AppColors.primaryContainer,
          onPrimaryContainer: AppColors.onPrimaryContainer,
          secondary: AppColors.accent,
          onSecondary: AppColors.white,
          secondaryContainer: AppColors.secondaryContainer,
          onSecondaryContainer: AppColors.onSecondaryContainer,
          tertiary: AppColors.tertiary,
          tertiaryContainer: AppColors.tertiaryContainer,
          surface: AppColors.surface,
          onSurface: AppColors.textPrimary,
          onSurfaceVariant: AppColors.textSecondary,
          surfaceContainerLowest: AppColors.surfaceContainerLowest,
          surfaceContainerLow: AppColors.surfaceContainerLow,
          surfaceContainer: AppColors.surfaceContainer,
          surfaceContainerHigh: AppColors.surfaceContainerHigh,
          surfaceContainerHighest: AppColors.surfaceContainerHighest,
          outline: AppColors.outline,
          outlineVariant: AppColors.outlineVariant,
          error: AppColors.error,
          onError: AppColors.white,
          errorContainer: AppColors.errorLight,
          shadow: Color(0x1A000000),
        ),
        extensions: const [SemanticColors.light],

        // ── AppBar ────────────────────────────────────────────────
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          scrolledUnderElevation: 0.5,
          centerTitle: false,
          titleTextStyle: AppTextStyles.h3,
          systemOverlayStyle: null, // inherits from brightness
        ),

        // ── Cards ─────────────────────────────────────────────────
        cardTheme: CardThemeData(
          color: AppColors.surface,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.lgAll,
            side: const BorderSide(
              color: AppColors.borderLight,
              width: 1,
            ),
          ),
          margin: EdgeInsets.zero,
        ),

        // ── Elevated button ───────────────────────────────────────
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.38),
            disabledForegroundColor: AppColors.white.withValues(alpha: 0.6),
            textStyle: AppTextStyles.buttonLarge,
            elevation: 0,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.lg,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: AppRadius.lgAll,
            ),
          ),
        ),

        // ── Outlined button ───────────────────────────────────────
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            backgroundColor: AppColors.white,
            disabledForegroundColor: AppColors.disabled,
            disabledBackgroundColor: AppColors.surfaceDim,
            textStyle: AppTextStyles.buttonLarge,
            elevation: 0,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.lg,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: AppRadius.lgAll,
            ),
            side: const BorderSide(color: AppColors.border, width: 1.5),
          ),
        ),

        // ── Text button ───────────────────────────────────────────
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            textStyle: AppTextStyles.buttonMedium,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: AppRadius.mdAll,
            ),
          ),
        ),

        // ── Filled button ─────────────────────────────────────────
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            textStyle: AppTextStyles.buttonMedium,
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

        // ── Input decoration ──────────────────────────────────────
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surfaceContainerLowest,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md + 2,
          ),
          hintStyle: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textTertiary,
          ),
          labelStyle: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
          prefixIconColor: AppColors.textTertiary,
          suffixIconColor: AppColors.textTertiary,
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
            borderSide: const BorderSide(
              color: AppColors.primary,
              width: 1.5,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: AppRadius.lgAll,
            borderSide: const BorderSide(color: AppColors.error),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: AppRadius.lgAll,
            borderSide: const BorderSide(
              color: AppColors.error,
              width: 1.5,
            ),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: AppRadius.lgAll,
            borderSide: const BorderSide(color: AppColors.disabled),
          ),
        ),

        // ── Chip ──────────────────────────────────────────────────
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.surfaceContainer,
          disabledColor: AppColors.surfaceDim,
          selectedColor: AppColors.primaryContainer,
          side: const BorderSide(color: AppColors.borderLight),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.smAll,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          labelStyle: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textPrimary,
          ),
          checkmarkColor: AppColors.primary,
          iconTheme: const IconThemeData(
            color: AppColors.textSecondary,
            size: 18,
          ),
        ),

        // ── Dialog ────────────────────────────────────────────────
        dialogTheme: DialogThemeData(
          backgroundColor: AppColors.surface,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.xlAll,
            side: const BorderSide(color: AppColors.borderLight),
          ),
          titleTextStyle: AppTextStyles.h3,
          contentTextStyle: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),

        // ── Bottom sheet ──────────────────────────────────────────
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: AppColors.surface,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppRadius.xxl),
            ),
          ),
          showDragHandle: true,
          dragHandleColor: AppColors.outlineVariant,
          modalBarrierColor: Color(0x80000000),
        ),

        // ── Snackbar ──────────────────────────────────────────────
        snackBarTheme: SnackBarThemeData(
          backgroundColor: AppColors.textPrimary,
          contentTextStyle: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.white,
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.mdAll,
          ),
          elevation: 4,
        ),

        // ── Divider ───────────────────────────────────────────────
        dividerTheme: const DividerThemeData(
          color: AppColors.divider,
          thickness: 1,
          space: 1,
          indent: 0,
          endIndent: 0,
        ),

        // ── Navigation bar (Material 3) ──────────────────────────
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: AppColors.surface,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          shadowColor: Colors.transparent,
          indicatorColor: AppColors.primary.withValues(alpha: 0.12),
          height: 64,
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppTextStyles.caption.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              );
            }
            return AppTextStyles.caption;
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(
                color: AppColors.primary,
                size: 24,
              );
            }
            return const IconThemeData(
              color: AppColors.textTertiary,
              size: 24,
            );
          }),
        ),

        // ── Tab bar ───────────────────────────────────────────────
        tabBarTheme: TabBarThemeData(
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textTertiary,
          indicatorColor: AppColors.primary,
          labelStyle: AppTextStyles.buttonMedium,
          unselectedLabelStyle: AppTextStyles.buttonMedium.copyWith(
            fontWeight: FontWeight.w500,
          ),
          indicatorSize: TabBarIndicatorSize.label,
          dividerColor: AppColors.divider,
          dividerHeight: 1,
          labelPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
          ),
        ),

        // ── ListTile ──────────────────────────────────────────────
        listTileTheme: ListTileThemeData(
          contentPadding: EdgeInsets.zero,
          titleTextStyle: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textPrimary,
          ),
          subtitleTextStyle: AppTextStyles.bodySmall,
          iconColor: AppColors.textTertiary,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.mdAll,
          ),
        ),

        // ── Switch ────────────────────────────────────────────────
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.white;
            }
            return AppColors.white;
          }),
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.primary;
            }
            return AppColors.disabled;
          }),
        ),

        // ── Progress indicator ────────────────────────────────────
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: AppColors.primary,
          linearTrackColor: AppColors.surfaceContainerHigh,
          circularTrackColor: AppColors.surfaceContainerHigh,
          strokeWidth: 3,
        ),

        // ── Slider ────────────────────────────────────────────────
        sliderTheme: SliderThemeData(
          activeTrackColor: AppColors.primary,
          inactiveTrackColor: AppColors.surfaceContainerHigh,
          thumbColor: AppColors.primary,
          overlayColor: AppColors.primary.withValues(alpha: 0.1),
          trackHeight: 4,
          thumbShape: const RoundSliderThumbShape(
            enabledThumbRadius: 8,
          ),
          overlayShape: const RoundSliderOverlayShape(
            overlayRadius: 20,
          ),
        ),
      );

  // ────────────────────────────────────────────────────────────────
  //  DARK
  // ────────────────────────────────────────────────────────────────
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        fontFamily: AppTextStyles._fontFamily,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.darkBackground,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primaryLight,
          onPrimary: AppColors.white,
          primaryContainer: AppColors.darkPrimaryContainer,
          onPrimaryContainer: AppColors.primaryLight,
          secondary: AppColors.accentLight,
          onSecondary: AppColors.white,
          secondaryContainer: Color(0xFF3D1A0A),
          onSecondaryContainer: AppColors.accentLight,
          tertiary: AppColors.tertiaryLight,
          tertiaryContainer: Color(0xFF2E2200),
          surface: AppColors.darkSurface,
          onSurface: AppColors.darkTextPrimary,
          onSurfaceVariant: AppColors.darkTextSecondary,
          surfaceContainerLowest: AppColors.darkSurfaceContainerLowest,
          surfaceContainerLow: AppColors.darkSurfaceContainerLow,
          surfaceContainer: AppColors.darkSurfaceContainer,
          surfaceContainerHigh: AppColors.darkSurfaceContainerHigh,
          surfaceContainerHighest: AppColors.darkSurfaceContainerHighest,
          outline: AppColors.darkOutline,
          outlineVariant: AppColors.darkBorder,
          error: AppColors.error,
          onError: AppColors.white,
          errorContainer: Color(0xFF5C1A1A),
          shadow: Color(0x66000000),
        ),
        extensions: const [SemanticColors.dark],

        // ── AppBar ────────────────────────────────────────────────
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.darkBackground,
          foregroundColor: AppColors.darkTextPrimary,
          elevation: 0,
          scrolledUnderElevation: 0.5,
          centerTitle: false,
          titleTextStyle: TextStyle(
            fontFamily: AppTextStyles._fontFamily,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.darkTextPrimary,
            height: 1.3,
          ),
        ),

        // ── Cards ─────────────────────────────────────────────────
        cardTheme: CardThemeData(
          color: AppColors.darkSurfaceContainerLow,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.lgAll,
            side: const BorderSide(
              color: AppColors.darkBorder,
              width: 1,
            ),
          ),
          margin: EdgeInsets.zero,
        ),

        // ── Elevated button ───────────────────────────────────────
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryLight,
            foregroundColor: AppColors.darkTextPrimary,
            disabledBackgroundColor:
                AppColors.primaryLight.withValues(alpha: 0.3),
            disabledForegroundColor:
                AppColors.darkTextPrimary.withValues(alpha: 0.4),
            textStyle: AppTextStyles.buttonLarge.copyWith(
              color: AppColors.darkTextPrimary,
            ),
            elevation: 0,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.lg,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: AppRadius.lgAll,
            ),
          ),
        ),

        // ── Outlined button ───────────────────────────────────────
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primaryLight,
            backgroundColor: Colors.transparent,
            disabledForegroundColor:
                AppColors.darkTextSecondary.withValues(alpha: 0.4),
            disabledBackgroundColor:
                AppColors.darkSurfaceContainerHigh.withValues(alpha: 0.3),
            textStyle: AppTextStyles.buttonLarge.copyWith(
              color: AppColors.primaryLight,
            ),
            elevation: 0,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.lg,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: AppRadius.lgAll,
            ),
            side: const BorderSide(
              color: AppColors.darkOutline,
              width: 1.5,
            ),
          ),
        ),

        // ── Text button ───────────────────────────────────────────
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primaryLight,
            textStyle: AppTextStyles.buttonMedium.copyWith(
              color: AppColors.primaryLight,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: AppRadius.mdAll,
            ),
          ),
        ),

        // ── Filled button ─────────────────────────────────────────
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primaryLight,
            foregroundColor: AppColors.darkTextPrimary,
            textStyle: AppTextStyles.buttonMedium.copyWith(
              color: AppColors.darkTextPrimary,
            ),
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

        // ── Input decoration ──────────────────────────────────────
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.darkSurfaceContainerLow,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md + 2,
          ),
          hintStyle: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.darkTextHint,
          ),
          labelStyle: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.darkTextSecondary,
          ),
          prefixIconColor: AppColors.darkTextHint,
          suffixIconColor: AppColors.darkTextHint,
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
            borderSide: const BorderSide(
              color: AppColors.primaryLight,
              width: 1.5,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: AppRadius.lgAll,
            borderSide: const BorderSide(color: AppColors.error),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: AppRadius.lgAll,
            borderSide: const BorderSide(
              color: AppColors.error,
              width: 1.5,
            ),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: AppRadius.lgAll,
            borderSide: BorderSide(
              color: AppColors.darkBorder.withValues(alpha: 0.5),
            ),
          ),
        ),

        // ── Chip ──────────────────────────────────────────────────
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.darkSurfaceContainer,
          disabledColor: AppColors.darkSurfaceContainerHigh,
          selectedColor: AppColors.darkPrimaryContainer,
          side: const BorderSide(color: AppColors.darkBorder),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.smAll,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          labelStyle: AppTextStyles.bodySmall.copyWith(
            color: AppColors.darkTextPrimary,
          ),
          checkmarkColor: AppColors.primaryLight,
          iconTheme: const IconThemeData(
            color: AppColors.darkTextSecondary,
            size: 18,
          ),
        ),

        // ── Dialog ────────────────────────────────────────────────
        dialogTheme: DialogThemeData(
          backgroundColor: AppColors.darkSurfaceContainer,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.xlAll,
            side: const BorderSide(color: AppColors.darkBorder),
          ),
          titleTextStyle: AppTextStyles.h3.copyWith(
            color: AppColors.darkTextPrimary,
          ),
          contentTextStyle: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.darkTextSecondary,
          ),
        ),

        // ── Bottom sheet ──────────────────────────────────────────
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: AppColors.darkSurfaceContainerLow,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppRadius.xxl),
            ),
          ),
          showDragHandle: true,
          dragHandleColor: AppColors.darkOutline,
          modalBarrierColor: Color(0x80000000),
        ),

        // ── Snackbar ──────────────────────────────────────────────
        snackBarTheme: SnackBarThemeData(
          backgroundColor: AppColors.darkSurfaceContainerHighest,
          contentTextStyle: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.darkTextPrimary,
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.mdAll,
          ),
          elevation: 4,
        ),

        // ── Divider ───────────────────────────────────────────────
        dividerTheme: const DividerThemeData(
          color: AppColors.darkDivider,
          thickness: 1,
          space: 1,
          indent: 0,
          endIndent: 0,
        ),

        // ── Navigation bar (Material 3) ──────────────────────────
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: AppColors.darkSurfaceContainerLow,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          shadowColor: Colors.transparent,
          indicatorColor: AppColors.primaryLight.withValues(alpha: 0.15),
          height: 64,
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppTextStyles.caption.copyWith(
                color: AppColors.primaryLight,
                fontWeight: FontWeight.w600,
              );
            }
            return AppTextStyles.caption.copyWith(
              color: AppColors.darkTextTertiary,
            );
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(
                color: AppColors.primaryLight,
                size: 24,
              );
            }
            return const IconThemeData(
              color: AppColors.darkTextTertiary,
              size: 24,
            );
          }),
        ),

        // ── Tab bar ───────────────────────────────────────────────
        tabBarTheme: TabBarThemeData(
          labelColor: AppColors.primaryLight,
          unselectedLabelColor: AppColors.darkTextTertiary,
          indicatorColor: AppColors.primaryLight,
          labelStyle: AppTextStyles.buttonMedium.copyWith(
            color: AppColors.primaryLight,
          ),
          unselectedLabelStyle: AppTextStyles.buttonMedium.copyWith(
            fontWeight: FontWeight.w500,
            color: AppColors.darkTextTertiary,
          ),
          indicatorSize: TabBarIndicatorSize.label,
          dividerColor: AppColors.darkDivider,
          dividerHeight: 1,
          labelPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
          ),
        ),

        // ── ListTile ──────────────────────────────────────────────
        listTileTheme: ListTileThemeData(
          contentPadding: EdgeInsets.zero,
          titleTextStyle: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.darkTextPrimary,
          ),
          subtitleTextStyle: AppTextStyles.bodySmall.copyWith(
            color: AppColors.darkTextSecondary,
          ),
          iconColor: AppColors.darkTextTertiary,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.mdAll,
          ),
        ),

        // ── Switch ────────────────────────────────────────────────
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.white;
            }
            return AppColors.darkTextSecondary;
          }),
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.primaryLight;
            }
            return AppColors.darkSurfaceContainerHighest;
          }),
        ),

        // ── Progress indicator ────────────────────────────────────
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: AppColors.primaryLight,
          linearTrackColor: AppColors.darkSurfaceContainerHigh,
          circularTrackColor: AppColors.darkSurfaceContainerHigh,
          strokeWidth: 3,
        ),

        // ── Slider ────────────────────────────────────────────────
        sliderTheme: SliderThemeData(
          activeTrackColor: AppColors.primaryLight,
          inactiveTrackColor: AppColors.darkSurfaceContainerHigh,
          thumbColor: AppColors.primaryLight,
          overlayColor: AppColors.primaryLight.withValues(alpha: 0.1),
          trackHeight: 4,
          thumbShape: const RoundSliderThumbShape(
            enabledThumbRadius: 8,
          ),
          overlayShape: const RoundSliderOverlayShape(
            overlayRadius: 20,
          ),
        ),
      );
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// EXTENSIONS
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// Semantic colors that adapt to brightness.
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
