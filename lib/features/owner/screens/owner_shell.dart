// lib/features/owner/screens/owner_shell.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/message_model.dart';
import '../../../core/models/visit_request_model.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/widgets/loge_bottom_nav.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../chat/screens/conversations_screen.dart';
import '../../profile/screens/profile_screen.dart';
import 'my_properties_screen.dart';
import 'owner_dashboard.dart';
import 'visit_requests_screen.dart';

class OwnerShell extends ConsumerStatefulWidget {
  const OwnerShell({super.key});

  @override
  ConsumerState<OwnerShell> createState() => _OwnerShellState();
}

class _OwnerShellState extends ConsumerState<OwnerShell> {
  int _indexActuel = 0;

  final List<Widget> _ecrans = const [
    OwnerDashboard(),
    MyPropertiesScreen(),
    VisitRequestsScreen(),
    ConversationsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final utilisateur = ref.watch(utilisateurActuelProvider).asData?.value;
    final firestoreService = FirestoreService();

    if (utilisateur == null) return const ScreenSkeleton();

    return Scaffold(
      body: IndexedStack(index: _indexActuel, children: _ecrans),
      bottomNavigationBar: StreamBuilder<List<ConversationModel>>(
        stream: firestoreService.conversationsUtilisateur(utilisateur.uid),
        builder: (context, snapshotConvs) {
          return StreamBuilder<List<VisitRequestModel>>(
            stream: firestoreService.demandesRecues(utilisateur.uid),
            builder: (context, snapshotDemandes) {
              final conversations = snapshotConvs.data ?? [];
              final demandes = snapshotDemandes.data ?? [];

              final messagesNonLus = conversations.fold<int>(
                0,
                (total, conv) =>
                    total + (conv.messagesNonLus[utilisateur.uid] ?? 0),
              );
              final demandesNonTraitees =
                  demandes.where((d) => d.estEnAttente).length;

              return LogeBottomNav(
                currentIndex: _indexActuel,
                onTap: (index) => setState(() => _indexActuel = index),
                items: [
                  const LogeNavItem(
                    icone: Icons.dashboard_outlined,
                    iconeActive: Icons.dashboard,
                    label: 'Accueil',
                  ),
                  const LogeNavItem(
                    icone: Icons.home_outlined,
                    iconeActive: Icons.home,
                    label: 'Mes biens',
                  ),
                  LogeNavItem(
                    icone: Icons.calendar_today_outlined,
                    iconeActive: Icons.calendar_today,
                    label: 'Demandes',
                    badge: demandesNonTraitees,
                  ),
                  LogeNavItem(
                    icone: Icons.chat_bubble_outline,
                    iconeActive: Icons.chat_bubble,
                    label: 'Messages',
                    badge: messagesNonLus,
                  ),
                  const LogeNavItem(
                    icone: Icons.person_outline,
                    iconeActive: Icons.person,
                    label: 'Profil',
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
