import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_routes.dart';
import '../features/admin/screens/admin_dashboard.dart';
import '../features/admin/screens/reports_screen.dart';
import '../features/admin/screens/users_management_screen.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/auth/screens/role_selection_screen.dart';
import '../features/chat/screens/conversations_screen.dart';
import '../features/owner/screens/add_property_screen.dart';
import '../features/owner/screens/my_properties_screen.dart';
import '../features/owner/screens/owner_dashboard.dart';
import '../features/owner/screens/visit_requests_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/tenant/screens/alerts_screen.dart';
import '../features/tenant/screens/favorites_screen.dart';
import '../features/tenant/screens/my_requests_screen.dart';
import '../features/tenant/screens/property_detail_screen.dart';
import '../features/tenant/screens/search_screen.dart';

final routeurApp = Provider<GoRouter>((ref) {
  final etatAuth = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: AppRoutes.connexion,
    redirect: (context, state) {
      final estConnecte = etatAuth.asData?.value != null;
      final versConnexion = state.matchedLocation == AppRoutes.connexion;
      final versInscription = state.matchedLocation == AppRoutes.inscription;
      final versChoixRole = state.matchedLocation == AppRoutes.choixRole;

      if (!estConnecte &&
          !versConnexion &&
          !versInscription &&
          !versChoixRole) {
        return AppRoutes.connexion;
      }
      return null;
    },
    routes: [
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

      // routes propriétaire
      GoRoute(
        path: AppRoutes.tableauBordProprietaire,
        builder: (context, state) => const OwnerDashboard(),
      ),
      GoRoute(
        path: AppRoutes.ajouterBien,
        builder: (context, state) => const AddPropertyScreen(),
      ),
      GoRoute(
        path: AppRoutes.mesBiens,
        builder: (context, state) => const MyPropertiesScreen(),
      ),
      GoRoute(
        path: AppRoutes.demandesVisite,
        builder: (context, state) => const VisitRequestsScreen(),
      ),

      // routes locataire
      GoRoute(
        path: AppRoutes.rechercheLocataire,
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: AppRoutes.detailBien,
        builder: (context, state) => const PropertyDetailScreen(),
      ),
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

      // routes communes
      GoRoute(
        path: AppRoutes.conversations,
        builder: (context, state) => const ConversationsScreen(),
      ),
      GoRoute(
        path: AppRoutes.profil,
        builder: (context, state) => const ProfileScreen(),
      ),

      // routes admin
      GoRoute(
        path: AppRoutes.tableauBordAdmin,
        builder: (context, state) => const AdminDashboard(),
      ),
      GoRoute(
        path: AppRoutes.gestionUtilisateurs,
        builder: (context, state) => const UsersManagementScreen(),
      ),
      GoRoute(
        path: AppRoutes.signalements,
        builder: (context, state) => const ReportsScreen(),
      ),
    ],
    errorBuilder:
        (context, state) => Scaffold(
          body: Center(child: Text('Page introuvable : ${state.error}')),
        ),
  );
});
