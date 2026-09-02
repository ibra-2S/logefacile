import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logefacile/core/widgets/loge_bottom_nav.dart';
import 'package:logefacile/core/widgets/property_photo.dart';

const _items = [
  LogeNavItem(
    icone: Icons.search_outlined,
    iconeActive: Icons.search,
    label: 'Recherche',
  ),
  LogeNavItem(
    icone: Icons.calendar_today_outlined,
    iconeActive: Icons.calendar_today,
    label: 'Demandes',
  ),
  LogeNavItem(
    icone: Icons.favorite_outline,
    iconeActive: Icons.favorite,
    label: 'Favoris',
  ),
  LogeNavItem(
    icone: Icons.chat_bubble_outline,
    iconeActive: Icons.chat_bubble,
    label: 'Messages',
    badge: 3,
  ),
  LogeNavItem(
    icone: Icons.person_outline,
    iconeActive: Icons.person,
    label: 'Profil',
  ),
];

void main() {
  testWidgets('LogeBottomNav : onglet central + tap sans déborder', (
    tester,
  ) async {
    int tapped = -1;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: LogeBottomNav(
            currentIndex: 2,
            centerIndex: 2,
            onTap: (i) => tapped = i,
            items: _items,
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Profil'));
    expect(tapped, 4);

    // onglet central (surélevé)
    await tester.tap(find.text('Favoris'));
    expect(tapped, 2);

    await tester.tap(find.text('Demandes'));
    expect(tapped, 1);
  });

  testWidgets('PropertyPhoto : placeholder quand aucune photo', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: PropertyPhoto(photos: [], height: 120)),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.byIcon(Icons.home_work_outlined), findsOneWidget);
  });
}
