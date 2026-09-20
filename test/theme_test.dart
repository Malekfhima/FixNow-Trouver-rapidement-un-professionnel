import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fixnow/core/theme/app_theme.dart';

void main() {
  group('Dark mode', () {
    test('AppTheme.dark est un ThemeData sombre avec les mêmes composants',
        () {
      final dark = AppTheme.dark;
      final light = AppTheme.light;

      expect(dark.brightness, Brightness.dark);
      expect(dark.colorScheme.primary, AppColors.primaryLight);
      expect(dark.scaffoldBackgroundColor, AppColors.darkBackground);

      // Même structure de tokens que le thème clair.
      expect(dark.appBarTheme.elevation, light.appBarTheme.elevation);
      expect(dark.cardTheme.elevation, light.cardTheme.elevation);
      expect(
        (dark.cardTheme.shape as RoundedRectangleBorder).borderRadius,
        (light.cardTheme.shape as RoundedRectangleBorder).borderRadius,
      );
      expect(dark.inputDecorationTheme.filled, isTrue);
      expect(dark.useMaterial3, isTrue);
    });

    test('SemanticColors : extension présente dans les deux thèmes', () {
      expect(
        AppTheme.light.extension<SemanticColors>(),
        isA<SemanticColors>(),
      );
      expect(
        AppTheme.dark.extension<SemanticColors>(),
        isA<SemanticColors>(),
      );
      // Le mode sombre utilise des variantes plus claires (contraste).
      expect(
        AppTheme.dark.extension<SemanticColors>()!.success,
        isNot(AppTheme.light.extension<SemanticColors>()!.success),
      );
    });

    testWidgets('MaterialApp applique le darkTheme quand ThemeMode.dark',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: ThemeMode.dark,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: Text(
                  'FixNow',
                  style: TextStyle(color: Theme.of(context).colorScheme.primary),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final context = tester.element(find.text('FixNow'));
      expect(Theme.of(context).brightness, Brightness.dark);
    });
  });
}
