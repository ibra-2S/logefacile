// lib/features/tenant/screens/tenant_shell.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/message_model.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/widgets/loge_bottom_nav.dart';
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

  // Favoris est placé au centre (bouton rond surélevé) — index 2
  final List<Widget> _ecrans = const [
    SearchScreen(), // 0 Recherche
    MyRequestsScreen(), // 1 Demandes
    FavoritesScreen(), // 2 Favoris (centre)
    ConversationsScreen(), // 3 Messages
    ProfileScreen(), // 4 Profil
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
        builder: (context, snapshot) {
          final conversations = snapshot.data ?? [];
          final messagesNonLus = conversations.fold<int>(
            0,
            (total, conv) =>
                total + (conv.messagesNonLus[utilisateur.uid] ?? 0),
          );

          return LogeBottomNav(
            currentIndex: _indexActuel,
            onTap: (index) => setState(() => _indexActuel = index),
            centerIndex: 2,
            items: [
              const LogeNavItem(
                icone: Icons.search_outlined,
                iconeActive: Icons.search,
                label: 'Recherche',
              ),
              const LogeNavItem(
                icone: Icons.calendar_today_outlined,
                iconeActive: Icons.calendar_today,
                label: 'Demandes',
              ),
              const LogeNavItem(
                icone: Icons.favorite_outline,
                iconeActive: Icons.favorite,
                label: 'Favoris',
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
      ),
    );
  }
}
