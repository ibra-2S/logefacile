import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logefacile/core/widgets/admin_charts.dart';

void main() {
  testWidgets('DonutChart : rendu + légende + état vide', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                DonutChart(
                  titre: "Taux d'occupation",
                  icone: Icons.donut_large_outlined,
                  couleur: Color(0xFF1A237E),
                  parts: [
                    (
                      label: 'Disponible',
                      valeur: 6,
                      couleur: Color(0xFF2E7D32),
                    ),
                    (label: 'Occupé', valeur: 3, couleur: Color(0xFF1565C0)),
                    (
                      label: 'Maintenance',
                      valeur: 0,
                      couleur: Color(0xFFE65100),
                    ),
                  ],
                ),
                DonutChart(
                  titre: 'Vide',
                  icone: Icons.category_outlined,
                  couleur: Color(0xFF2E7D32),
                  parts: [(label: 'X', valeur: 0, couleur: Color(0xFF000000))],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Disponible · 6'), findsOneWidget);
    expect(find.text('Aucune donnée'), findsOneWidget);
  });

  testWidgets('CourbeAireChart + HistogrammeFrequence + BarresHorizontales', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                CourbeAireChart(
                  titre: 'Revenus',
                  sousTitre: 'GNF',
                  icone: Icons.payments_outlined,
                  couleur: const Color(0xFF2E7D32),
                  labels: const [
                    'jan',
                    'fév',
                    'mar',
                    'avr',
                    'mai',
                    'juin',
                    'juil',
                    'aoû',
                    'sep',
                    'oct',
                    'nov',
                    'déc',
                  ],
                  valeurs: List.generate(12, (i) => (i + 1) * 250000.0),
                  formatValeur: formatNombre,
                ),
                const HistogrammeFrequence(
                  titre: 'Distribution des loyers',
                  icone: Icons.bar_chart_outlined,
                  couleur: Color(0xFF1A237E),
                  labels: ['< 500k', '500k–1M', '1M–2M', '2M–5M', '> 5M'],
                  valeurs: [4, 9, 6, 2, 1],
                ),
                const BarresHorizontales(
                  titre: 'Top quartiers',
                  icone: Icons.place_outlined,
                  couleur: Color(0xFF1A237E),
                  items: [
                    (label: 'Kaloum', valeur: 12, couleur: Color(0xFF1565C0)),
                    (label: 'Ratoma', valeur: 8, couleur: Color(0xFF1565C0)),
                    (label: 'Matam', valeur: 3, couleur: Color(0xFF1565C0)),
                  ],
                ),
                const KpiCard(
                  titre: 'Délai moyen de location',
                  valeur: '17 j',
                  sousTitre: 'entre publication et occupation',
                  icone: Icons.schedule_outlined,
                  couleur: Color(0xFF1565C0),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Kaloum'), findsOneWidget);
    expect(find.text('17 j'), findsOneWidget);
    expect(find.text('Distribution des loyers'), findsOneWidget);
    expect(find.text('Revenus'), findsOneWidget);
  });
}
