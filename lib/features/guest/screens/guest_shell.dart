// lib/features/guest/screens/guest_shell.dart
import 'package:flutter/material.dart';

import '../../../core/widgets/guest_locked_view.dart';
import '../../../core/widgets/loge_bottom_nav.dart';
import '../../tenant/screens/search_screen.dart';

/// Shell affiché à un visiteur qui n'a pas de compte : il peut consulter
/// les annonces (onglet Accueil), mais les autres onglets l'invitent à se
/// connecter pour accéder à la fonctionnalité correspondante.
class GuestShell extends StatefulWidget {
  const GuestShell({super.key});

  @override
  State<GuestShell> createState() => _GuestShellState();
}

class _GuestShellState extends State<GuestShell> {
  int _indexActuel = 0;

  static const _ecrans = [
    SearchScreen(),
    GuestLockedView(
      message:
          'Pour consulter vos favoris, vous devez avoir un compte LogeFacile.',
    ),
    GuestLockedView(
      message:
          'Pour publier et gérer vos biens, vous devez avoir un compte LogeFacile.',
    ),
    GuestLockedView(
      message:
          'Pour accéder à votre profil, vous devez avoir un compte LogeFacile.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _indexActuel, children: _ecrans),
      bottomNavigationBar: LogeBottomNav(
        currentIndex: _indexActuel,
        onTap: (index) => setState(() => _indexActuel = index),
        items: const [
          LogeNavItem(
            icone: Icons.home_outlined,
            iconeActive: Icons.home,
            label: 'Accueil',
          ),
          LogeNavItem(
            icone: Icons.favorite_outline,
            iconeActive: Icons.favorite,
            label: 'Favoris',
          ),
          LogeNavItem(
            icone: Icons.apartment_outlined,
            iconeActive: Icons.apartment,
            label: 'Mes biens',
          ),
          LogeNavItem(
            icone: Icons.person_outline,
            iconeActive: Icons.person,
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
