import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_routes.dart';
import '../../auth/providers/auth_provider.dart';
import '../../notifications/screens/notifications_screen.dart';
import '../../profile/screens/contact_screen.dart';
import '../../profile/screens/help_center_screen.dart';
import '../../profile/screens/legal_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../profile/screens/settings_screen.dart';
import '../screens/admin_dashboard.dart';
import '../screens/admin_properties_screen.dart';
import '../screens/admin_stats_screen.dart';
import '../screens/reports_screen.dart';
import '../screens/users_management_screen.dart';
import 'admin_login_screen.dart';
import 'admin_web_shell.dart';

/// Routeur de la console web d'administration.
///
/// Il reprend les mêmes chemins que l'app mobile (`/admin`, `/admin/utilisateurs`…)
/// pour que les boutons de navigation des écrans admin existants fonctionnent
/// tels quels.
final adminRouteurProvider = Provider<GoRouter>((ref) {
  final etatAuth = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: AppRoutes.tableauBordAdmin,
    redirect: (context, state) {
      final connecte = etatAuth.asData?.value != null;
      final surConnexion = state.matchedLocation == AppRoutes.connexion;

      if (!connecte) return surConnexion ? null : AppRoutes.connexion;
      if (surConnexion) return AppRoutes.tableauBordAdmin;
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.connexion,
        builder: (context, state) => const AdminLoginScreen(),
      ),

      // Toutes les pages admin vivent dans le shell (barre latérale + contenu).
      ShellRoute(
        builder: (context, state, child) => AdminWebShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.tableauBordAdmin,
            builder: (context, state) => const AdminDashboard(),
          ),
          GoRoute(
            path: AppRoutes.gestionUtilisateurs,
            builder: (context, state) => const UsersManagementScreen(),
          ),
          GoRoute(
            path: AppRoutes.biensAdmin,
            builder: (context, state) => const AdminPropertiesScreen(),
          ),
          GoRoute(
            path: AppRoutes.signalements,
            builder: (context, state) => const ReportsScreen(),
          ),
          GoRoute(
            path: AppRoutes.statistiquesAdmin,
            builder: (context, state) => const AdminStatsScreen(),
          ),
          GoRoute(
            path: AppRoutes.notifications,
            builder: (context, state) => const NotificationsScreen(),
          ),
          GoRoute(
            path: AppRoutes.parametres,
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: AppRoutes.profil,
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: AppRoutes.centreAide,
            builder: (context, state) => const HelpCenterScreen(),
          ),
          GoRoute(
            path: AppRoutes.contact,
            builder: (context, state) => const ContactScreen(),
          ),
          GoRoute(
            path: AppRoutes.confidentialite,
            builder: (context, state) => const LegalScreen(
              titre: 'Politique de confidentialité',
              majAJour: 'août 2026',
              sections: confidentialiteSections,
            ),
          ),
          GoRoute(
            path: AppRoutes.conditions,
            builder: (context, state) => const LegalScreen(
              titre: "Conditions d'utilisation",
              majAJour: 'août 2026',
              sections: conditionsSections,
            ),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Page introuvable : ${state.error}')),
    ),
  );
});
