import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logefacile/core/widgets/stats_periode_card.dart';

void main() {
  final maintenant = DateTime.now();
  final dates = <DateTime>[
    for (var i = 0; i < 40; i++) maintenant.subtract(Duration(days: i * 3)),
    for (var i = 0; i < 10; i++)
      DateTime(maintenant.year - 1, 1 + (i % 12), 1 + i),
  ];

  testWidgets('StatsPeriodeCard : rendu + bascule semaine/mois/année', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: StatsPeriodeCard(
              titre: 'Biens publiés',
              icone: Icons.home_work_outlined,
              couleur: const Color(0xFF2E7D32),
              evenements: dates,
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Biens publiés'), findsOneWidget);
    expect(find.text('${dates.length} au total'), findsOneWidget);

    await tester.tap(find.text('Mois'));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('Jan'), findsOneWidget);

    await tester.tap(find.text('Année'));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('${maintenant.year}'), findsOneWidget);

    await tester.tap(find.text('Semaine'));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('StatsPeriodeCard : mode courbe + bascule', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: StatsPeriodeCard(
              titre: 'Fréquence de connexion',
              icone: Icons.login_rounded,
              couleur: const Color(0xFF00695C),
              courbe: true,
              evenements: dates,
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    for (final p in ['Mois', 'Année', 'Semaine']) {
      await tester.tap(find.text(p));
      await tester.pump();
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('StatsPeriodeCard : état vide', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StatsPeriodeCard(
            titre: 'Connexions',
            icone: Icons.login_rounded,
            couleur: Color(0xFF00695C),
            evenements: [],
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Aucune donnée'), findsOneWidget);
  });
}
