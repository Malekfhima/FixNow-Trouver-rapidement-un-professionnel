import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fixnow/core/widgets/star_rating.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: Center(child: child)));

  group('StarRating — affichage', () {
    testWidgets('4.3 → 4 étoiles pleines + 1 demi-étoile', (tester) async {
      await tester.pumpWidget(wrap(const StarRating(rating: 4.3)));

      expect(find.byIcon(Icons.star_rounded), findsNWidgets(4));
      expect(find.byIcon(Icons.star_half_rounded), findsOneWidget);
      expect(find.byIcon(Icons.star_outline_rounded), findsNothing);
    });

    testWidgets('2.0 → 2 pleines + 3 vides, sans label', (tester) async {
      await tester.pumpWidget(wrap(const StarRating(rating: 2.0)));

      expect(find.byIcon(Icons.star_rounded), findsNWidgets(2));
      expect(find.byIcon(Icons.star_outline_rounded), findsNWidgets(3));
      expect(find.text('2.0'), findsNothing,
          reason: 'label masqué par défaut (showLabel: false)');
    });

    testWidgets('showLabel affiche la note et le nombre d’avis', (tester) async {
      await tester.pumpWidget(
        wrap(const StarRating(rating: 4.5, showLabel: true, reviewCount: 12)),
      );

      expect(find.text('4.5 (12 avis)'), findsOneWidget);
    });

    testWidgets('note bornée 0..5 (pas d’exception)', (tester) async {
      await tester.pumpWidget(wrap(const StarRating(rating: 5)));
      expect(find.byIcon(Icons.star_rounded), findsNWidgets(5));
    });

    testWidgets('lecture seule : aucune zone tactile interactive',
        (tester) async {
      await tester.pumpWidget(wrap(const StarRating(rating: 3)));

      expect(find.byType(IconButton), findsNothing,
          reason: 'affichage = non interactif');
      expect(
        tester.getSemantics(find.byType(StarRating)),
        matchesSemantics(label: 'Note : 3.0 sur 5'),
      );
    });
  });

  group('StarRating — saisie (interactif)', () {
    testWidgets('un tap sur la 4e étoile émet 4', (tester) async {
      double? received;
      await tester.pumpWidget(wrap(StarRating(
        rating: 0,
        onRatingChanged: (v) => received = v,
      )));

      expect(find.byType(IconButton), findsNWidgets(5));
      await tester.tap(find.byType(IconButton).at(3));
      expect(received, 4);
    });
  });
}
