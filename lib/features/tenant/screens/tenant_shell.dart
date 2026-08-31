// lib/features/tenant/screens/tenant_shell.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/models/message_model.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../chat/screens/conversations_screen.dart';
import '../../profile/screens/profile_screen.dart';
import 'favorites_screen.dart';
import 'my_requests_screen.dart';
import 'search_screen.dart';

class TenantShell extends ConsumerStatefulWidget {
  const TenantShell({super.key});

  @override
  ConsumerState<TenantShell> createState() => _TenantShellState();
}

class _TenantShellState extends ConsumerState<TenantShell> {
  int _indexActuel = 0;

  final List<Widget> _ecrans = const [
    SearchScreen(),
    FavoritesScreen(),
    MyRequestsScreen(),
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
                builder: (context, snapshot) {
                  final conversations = snapshot.data ?? [];
                  final messagesNonLus = conversations.fold<int>(
                    0,
                    (total, conv) =>
                        total + (conv.messagesNonLus[utilisateur.uid] ?? 0),
                  );

                  return NavigationBar(
                    selectedIndex: _indexActuel,
                    onDestinationSelected:
                        (index) => setState(() => _indexActuel = index),
                    backgroundColor: Colors.white,
                    indicatorColor: AppColors.bleuClair,
                    destinations: [
                      const NavigationDestination(
                        icon: Icon(Icons.search_outlined),
                        selectedIcon: Icon(
                          Icons.search,
                          color: AppColors.bleuFonce,
                        ),
                        label: 'Recherche',
                      ),
                      const NavigationDestination(
                        icon: Icon(Icons.favorite_outline),
                        selectedIcon: Icon(
                          Icons.favorite,
                          color: AppColors.bleuFonce,
                        ),
                        label: 'Favoris',
                      ),
                      const NavigationDestination(
                        icon: Icon(Icons.calendar_today_outlined),
                        selectedIcon: Icon(
                          Icons.calendar_today,
                          color: AppColors.bleuFonce,
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
              ),
    );
  }
}
