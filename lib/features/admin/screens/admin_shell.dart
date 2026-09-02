// lib/features/admin/screens/admin_shell.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/firestore_service.dart';
import '../../../core/widgets/loge_bottom_nav.dart';
import '../../profile/screens/profile_screen.dart';
import 'admin_dashboard.dart';
import 'admin_properties_screen.dart';
import 'reports_screen.dart';
import 'users_management_screen.dart';

class AdminShell extends ConsumerStatefulWidget {
  const AdminShell({super.key});

  @override
  ConsumerState<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends ConsumerState<AdminShell> {
  int _indexActuel = 0;

  final List<Widget> _ecrans = const [
    AdminDashboard(),
    UsersManagementScreen(),
    AdminPropertiesScreen(),
    ReportsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    return Scaffold(
      body: IndexedStack(index: _indexActuel, children: _ecrans),
      bottomNavigationBar: StreamBuilder<List<Map<String, dynamic>>>(
        stream: firestoreService.tousLesSignalements(),
        builder: (context, snapshot) {
          final signalements = snapshot.data ?? [];
          final signalementsEnAttente =
              signalements.where((s) => s['traite'] != true).length;

          return LogeBottomNav(
            currentIndex: _indexActuel,
            onTap: (index) => setState(() => _indexActuel = index),
            items: [
              const LogeNavItem(
                icone: Icons.dashboard_outlined,
                iconeActive: Icons.dashboard,
                label: 'Dashboard',
              ),
              const LogeNavItem(
                icone: Icons.people_outline,
                iconeActive: Icons.people,
                label: 'Utilisateurs',
              ),
              const LogeNavItem(
                icone: Icons.home_work_outlined,
                iconeActive: Icons.home_work,
                label: 'Biens',
              ),
              LogeNavItem(
                icone: Icons.flag_outlined,
                iconeActive: Icons.flag,
                label: 'Signalements',
                badge: signalementsEnAttente,
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
