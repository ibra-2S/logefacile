import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/firestore_service.dart';
import '../../auth/providers/auth_provider.dart';

/// Coquille de la console : barre latérale de navigation + zone de contenu.
///
/// Assure aussi le contrôle du rôle : un compte connecté qui n'est pas
/// administrateur voit un écran « Accès réservé ».
class AdminWebShell extends ConsumerWidget {
  final Widget child;

  const AdminWebShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final utilisateur = ref.watch(utilisateurActuelProvider);

    return utilisateur.when(
      loading: () => const _Plein(child: CircularProgressIndicator()),
      error: (_, __) => const _AccesRefuse(
        message: 'Impossible de charger votre profil.',
      ),
      data: (u) {
        if (u == null || u.role != UserRole.admin) {
          return const _AccesRefuse();
        }
        return Scaffold(
          body: Row(
            children: [
              _BarreLaterale(admin: u),
              const VerticalDivider(width: 1, color: AppColors.grisClair),
              Expanded(child: child),
            ],
          ),
        );
      },
    );
  }
}

// ── Barre latérale ─────────────────────────────────────────────────────────

class _ItemNav {
  final String route;
  final IconData icone;
  final IconData iconeActive;
  final String label;
  const _ItemNav(this.route, this.icone, this.iconeActive, this.label);
}

const _items = <_ItemNav>[
  _ItemNav(AppRoutes.tableauBordAdmin, Icons.dashboard_outlined,
      Icons.dashboard, 'Tableau de bord'),
  _ItemNav(AppRoutes.gestionUtilisateurs, Icons.people_outline, Icons.people,
      'Utilisateurs'),
  _ItemNav(AppRoutes.biensAdmin, Icons.home_work_outlined, Icons.home_work,
      'Biens'),
  _ItemNav(AppRoutes.signalements, Icons.flag_outlined, Icons.flag,
      'Signalements'),
  _ItemNav(AppRoutes.statistiquesAdmin, Icons.bar_chart_outlined,
      Icons.bar_chart, 'Statistiques'),
];

/// Éléments regroupés en bas de la barre, juste au-dessus du bloc profil.
/// (les Paramètres sont accessibles depuis l'écran Profil)
const _itemsBas = <_ItemNav>[
  _ItemNav(AppRoutes.profil, Icons.person_outline, Icons.person, 'Profil'),
];

class _BarreLaterale extends StatelessWidget {
  final UserModel admin;

  const _BarreLaterale({required this.admin});

  @override
  Widget build(BuildContext context) {
    final routeActuelle = GoRouterState.of(context).matchedLocation;

    return Container(
      width: 248,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 2),
            child: Align(
              alignment: Alignment.centerLeft,
              // le PNG a de grandes marges transparentes en haut/bas :
              // on ne garde que la bande centrale.
              child: ClipRect(
                child: Align(
                  alignment: Alignment.center,
                  heightFactor: 0.6,
                  child: Image.asset('assets/images/logo.png', width: 168),
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Text(
              'Administration',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
                color: AppColors.textSecondaire,
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.grisClair),
          const SizedBox(height: 8),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                for (final item in _items)
                  _LigneNav(
                    item: item,
                    actif: routeActuelle == item.route,
                    badge: item.route == AppRoutes.signalements
                        ? _badgeSignalements()
                        : null,
                    onTap: () => context.go(item.route),
                  ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.grisClair),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Column(
              children: [
                for (final item in _itemsBas)
                  _LigneNav(
                    item: item,
                    actif: routeActuelle == item.route,
                    onTap: () => context.go(item.route),
                  ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.grisClair),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  leading: CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.violetAdmin,
                    child: Text(
                      admin.nomComplet.isNotEmpty
                          ? admin.nomComplet[0].toUpperCase()
                          : 'A',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  title: Text(
                    admin.nomComplet.isEmpty ? 'Administrateur' : admin.nomComplet,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    admin.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => FirebaseAuth.instance.signOut(),
                    icon: const Icon(Icons.logout, size: 16),
                    label: const Text('Se déconnecter'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.erreur,
                      side: BorderSide(
                        color: AppColors.erreur.withValues(alpha: 0.4),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _badgeSignalements() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: FirestoreService().tousLesSignalements(),
      builder: (context, snapshot) {
        final n = (snapshot.data ?? [])
            .where((s) => s['traite'] != true)
            .length;
        if (n == 0) return const SizedBox.shrink();
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.erreur,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$n',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        );
      },
    );
  }
}

class _LigneNav extends StatelessWidget {
  final _ItemNav item;
  final bool actif;
  final Widget? badge;
  final VoidCallback onTap;

  const _LigneNav({
    required this.item,
    required this.actif,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: actif ? AppColors.bleuClair : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(
              children: [
                Icon(
                  actif ? item.iconeActive : item.icone,
                  size: 20,
                  color: actif ? AppColors.bleuFonce : AppColors.textSecondaire,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: actif ? FontWeight.w700 : FontWeight.w500,
                      color: actif ? AppColors.bleuFonce : AppColors.texte,
                    ),
                  ),
                ),
                if (badge != null) badge!,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── États plein écran ──────────────────────────────────────────────────────

class _Plein extends StatelessWidget {
  final Widget child;
  const _Plein({required this.child});

  @override
  Widget build(BuildContext context) =>
      Scaffold(body: Center(child: child));
}

class _AccesRefuse extends StatelessWidget {
  final String message;
  const _AccesRefuse({
    this.message = 'Cet espace est réservé aux administrateurs LogeFacile.',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, size: 48, color: AppColors.grisMoyen),
              const SizedBox(height: 16),
              const Text(
                'Accès réservé',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondaire,
                ),
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () => FirebaseAuth.instance.signOut(),
                icon: const Icon(Icons.logout, size: 16),
                label: const Text('Se déconnecter'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
