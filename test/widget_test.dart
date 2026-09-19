import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fixnow/main.dart';
import 'package:fixnow/services/firebase_auth_service.dart';

void main() {
  testWidgets('App starts', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Avoid Firebase initialization in tests.
          authStateProvider.overrideWith((ref) => Stream.value(null)),
        ],
        child: const FixNowApp(),
      ),
    );
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
