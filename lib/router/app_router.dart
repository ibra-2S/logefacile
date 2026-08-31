import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_routes.dart';
import '../features/admin/screens/admin_shell.dart';
import '../features/admin/screens/reports_screen.dart';
import '../features/admin/screens/users_management_screen.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/auth/screens/role_selection_screen.dart';
import '../features/chat/screens/chat_screen.dart';
import '../features/chat/screens/conversations_screen.dart';
import '../features/notifications/screens/notifications_screen.dart';
import '../features/onboarding/screens/onboarding_screen.dart';
import '../features/owner/screens/add_property_screen.dart';
import '../features/owner/screens/my_properties_screen.dart';
import '../features/owner/screens/owner_shell.dart';
import '../features/owner/screens/visit_requests_screen.dart';
import '../features/profile/screens/contact_screen.dart';
import '../features/profile/screens/help_center_screen.dart';
import '../features/profile/screens/legal_screen.dart';
import '../features/profile/screens/settings_screen.dart';
import '../features/splash/screens/splash_screen.dart';
import '../features/tenant/screens/alerts_screen.dart';
import '../features/tenant/screens/favorites_screen.dart';
import '../features/tenant/screens/my_requests_screen.dart';
import '../features/tenant/screens/property_detail_screen.dart';
import '../features/tenant/screens/tenant_shell.dart';

final routeurApp = Provider<GoRouter>((ref) {
  final etatAuth = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final estConnecte = etatAuth.asData?.value != null;
      final loc = state.matchedLocation;

      final routesPubliques = [
        AppRoutes.connexion,
        AppRoutes.inscription,
        AppRoutes.choixRole,
        AppRoutes.onboarding,
        '/',
      ];

      if (!estConnecte && !routesPubliques.contains(loc)) {
        return AppRoutes.connexion;
      }
      return null;
    },
    routes: [
      // splash
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),

      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),

      // auth
      GoRoute(
        path: AppRoutes.connexion,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.inscription,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.choixRole,
        builder: (context, state) => const RoleSelectionScreen(),
      ),

      // ── SHELL LOCATAIRE ──
      GoRoute(
        path: AppRoutes.rechercheLocataire,
        builder: (context, state) => const TenantShell(),
      ),

      // ── SHELL PROPRIÉTAIRE / AGENT ──
      GoRoute(
        path: AppRoutes.tableauBordProprietaire,
        builder: (context, state) => const OwnerShell(),
      ),

      // ── SHELL ADMIN ──
      GoRoute(
        path: AppRoutes.tableauBordAdmin,
        builder: (context, state) => const AdminShell(),
      ),

      // routes partagées (hors shell)
      GoRoute(
        path: AppRoutes.ajouterBien,
        builder: (context, state) => const AddPropertyScreen(),
      ),
      GoRoute(
        path: AppRoutes.detailBien,
        builder:
            (context, state) =>
                PropertyDetailScreen(bienId: state.pathParameters['id'] ?? ''),
      ),
      GoRoute(
        path: AppRoutes.chat,
        builder:
            (context, state) =>
                ChatScreen(convId: state.pathParameters['id'] ?? ''),
      ),
      GoRoute(
        path: AppRoutes.conversations,
        builder: (context, state) => const ConversationsScreen(),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (context, state) => const NotificationsScreen(),
      ),

      // locataire (accès direct hors shell)
      GoRoute(
        path: AppRoutes.mesFavoris,
        builder: (context, state) => const FavoritesScreen(),
      ),
      GoRoute(
        path: AppRoutes.mesDemandesVisite,
        builder: (context, state) => const MyRequestsScreen(),
      ),
      GoRoute(
        path: AppRoutes.mesAlertes,
        builder: (context, state) => const AlertsScreen(),
      ),

      // propriétaire (accès direct hors shell)
      GoRoute(
        path: AppRoutes.mesBiens,
        builder: (context, state) => const MyPropertiesScreen(),
      ),
      GoRoute(
        path: AppRoutes.demandesVisite,
        builder: (context, state) => const VisitRequestsScreen(),
      ),

      // admin (accès direct hors shell)
      GoRoute(
        path: AppRoutes.gestionUtilisateurs,
        builder: (context, state) => const UsersManagementScreen(),
      ),
      GoRoute(
        path: AppRoutes.signalements,
        builder: (context, state) => const ReportsScreen(),
      ),

      // profil - paramètres et support
      GoRoute(
        path: AppRoutes.parametres,
        builder: (context, state) => const SettingsScreen(),
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
        builder:
            (context, state) => const LegalScreen(
              titre: 'Politique de confidentialité',
              majAJour: 'août 2026',
              sections: confidentialiteSections,
            ),
      ),
      GoRoute(
        path: AppRoutes.conditions,
        builder:
            (context, state) => const LegalScreen(
              titre: "Conditions d'utilisation",
              majAJour: 'août 2026',
              sections: conditionsSections,
            ),
      ),
    ],
    errorBuilder:
        (context, state) => Scaffold(
          body: Center(child: Text('Page introuvable : ${state.error}')),
        ),
  );
});
