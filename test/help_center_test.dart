import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logefacile/core/models/user_model.dart';
import 'package:logefacile/features/auth/providers/auth_provider.dart';
import 'package:logefacile/features/profile/screens/help_center_screen.dart';

UserModel _u(UserRole role) => UserModel(
  uid: 'u1',
  email: 'x@y.z',
  nomComplet: 'Test',
  role: role,
  dateCreation: DateTime(2026, 1, 1),
  derniereCo: DateTime(2026, 1, 1),
);

Future<void> _pump(WidgetTester tester, UserRole? role) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        utilisateurActuelProvider.overrideWith(
          (ref) async => role == null ? null : _u(role),
        ),
      ],
      child: const MaterialApp(home: HelpCenterScreen()),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('centre d\'aide adapté au propriétaire', (tester) async {
    await _pump(tester, UserRole.proprietaire);
    expect(find.text('Aide — Propriétaire'), findsOneWidget);
    expect(find.text('Comment publier une annonce ?'), findsOneWidget);
    expect(find.text('Comment demander une visite ?'), findsNothing);
  });

  testWidgets('centre d\'aide adapté au locataire', (tester) async {
    await _pump(tester, UserRole.locataire);
    expect(find.text('Aide — Locataire'), findsOneWidget);
    expect(find.text('Comment demander une visite ?'), findsOneWidget);
  });

  testWidgets('centre d\'aide adapté à l\'admin', (tester) async {
    await _pump(tester, UserRole.admin);
    expect(find.text('Aide — Administration'), findsOneWidget);
    expect(find.text('Comment traiter un signalement ?'), findsOneWidget);
  });

  testWidgets('centre d\'aide sans utilisateur : générique', (tester) async {
    await _pump(tester, null);
    expect(find.text('Questions fréquentes'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
