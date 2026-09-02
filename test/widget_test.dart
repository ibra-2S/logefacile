import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logefacile/core/widgets/brand.dart';

// Note : un test de bout en bout de `LogeFacile` nécessiterait de simuler
// Firebase ; on vérifie ici le rendu de la marque de l'app.
void main() {
  testWidgets('le logo LogeFacile s\'affiche', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: LogeFacileWordmark())),
      ),
    );

    expect(find.textContaining('Loge'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
