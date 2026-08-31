// lib/features/owner/screens/owner_shell.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/models/message_model.dart';
import '../../../core/models/visit_request_model.dart';
import '../../../core/services/firestore_service.dart';
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
      bottomNavigationBar:
          utilisateur == null
              ? null
              : StreamBuilder<List<ConversationModel>>(
                stream: firestoreService.conversationsUtilisateur(
                  utilisateur.uid,
                ),
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

                      return NavigationBar(
                        selectedIndex: _indexActuel,
                        onDestinationSelected:
                            (index) => setState(() => _indexActuel = index),
                        backgroundColor: Colors.white,
                        indicatorColor: AppColors.bleuClair,
                        destinations: [
                          const NavigationDestination(
                            icon: Icon(Icons.dashboard_outlined),
                            selectedIcon: Icon(
                              Icons.dashboard,
                              color: AppColors.bleuFonce,
                            ),
                            label: 'Accueil',
                          ),
                          const NavigationDestination(
                            icon: Icon(Icons.home_outlined),
                            selectedIcon: Icon(
                              Icons.home,
                              color: AppColors.bleuFonce,
                            ),
                            label: 'Mes biens',
                          ),
                          NavigationDestination(
                            icon: Badge(
                              isLabelVisible: demandesNonTraitees > 0,
                              label: Text('$demandesNonTraitees'),
                              child: const Icon(Icons.calendar_today_outlined),
                            ),
                            selectedIcon: Badge(
                              isLabelVisible: demandesNonTraitees > 0,
                              label: Text('$demandesNonTraitees'),
                              child: const Icon(
                                Icons.calendar_today,
                                color: AppColors.bleuFonce,
                              ),
                            ),
                            label: 'Demandes',
                          ),
                          NavigationDestination(
                            icon: Badge(
                              isLabelVisible: messagesNonLus > 0,
                              label: Text('$messagesNonLus'),
                              child: const Icon(Icons.chat_bubble_outline),
                            ),
                            selectedIcon: Badge(
                              isLabelVisible: messagesNonLus > 0,
                              label: Text('$messagesNonLus'),
                              child: const Icon(
                                Icons.chat_bubble,
                                color: AppColors.bleuFonce,
                              ),
                            ),
                            label: 'Messages',
                          ),
                          const NavigationDestination(
                            icon: Icon(Icons.person_outline),
                            selectedIcon: Icon(
                              Icons.person,
                              color: AppColors.bleuFonce,
                            ),
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
