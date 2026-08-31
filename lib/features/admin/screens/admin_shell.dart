// lib/features/admin/screens/admin_shell.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/firestore_service.dart';
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

          return NavigationBar(
            selectedIndex: _indexActuel,
            onDestinationSelected:
                (index) => setState(() => _indexActuel = index),
            backgroundColor: Colors.white,
            indicatorColor: AppColors.bleuClair,
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard, color: AppColors.bleuFonce),
                label: 'Dashboard',
              ),
              const NavigationDestination(
                icon: Icon(Icons.people_outline),
                selectedIcon: Icon(Icons.people, color: AppColors.bleuFonce),
                label: 'Utilisateurs',
              ),
              const NavigationDestination(
                icon: Icon(Icons.home_work_outlined),
                selectedIcon: Icon(Icons.home_work, color: AppColors.bleuFonce),
                label: 'Biens',
              ),
              NavigationDestination(
                icon: Badge(
                  isLabelVisible: signalementsEnAttente > 0,
                  label: Text('$signalementsEnAttente'),
                  child: const Icon(Icons.flag_outlined),
                ),
                selectedIcon: Badge(
                  isLabelVisible: signalementsEnAttente > 0,
                  label: Text('$signalementsEnAttente'),
                  child: const Icon(Icons.flag, color: AppColors.bleuFonce),
                ),
                label: 'Signalements',
              ),
              const NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person, color: AppColors.bleuFonce),
                label: 'Profil',
              ),
            ],
          );
        },
      ),
    );
  }
}
