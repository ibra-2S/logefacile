import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/skeleton.dart';

class UsersManagementScreen extends ConsumerStatefulWidget {
  const UsersManagementScreen({super.key});

  @override
  ConsumerState<UsersManagementScreen> createState() =>
      _UsersManagementScreenState();
}

class _UsersManagementScreenState extends ConsumerState<UsersManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    return Scaffold(
      backgroundColor: AppColors.fond,
      appBar: AppBar(
        backgroundColor: AppColors.bleuFonce,
        elevation: 0,
        title: const Text(
          'Gestion des utilisateurs',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          isScrollable: true,
          tabs: const [
            Tab(text: '🔍 Locataires'),
            Tab(text: '🏠 Propriétaires'),
            Tab(text: '🤝 Agents'),
            Tab(text: '👑 Admins'),
          ],
        ),
      ),
      body: StreamBuilder<List<UserModel>>(
        stream: firestoreService.tousLesUtilisateurs(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const ListTileSkeleton();
          }

          final tous = snapshot.data ?? [];
          final locataires =
              tous.where((u) => u.role == UserRole.locataire).toList();
          final proprietaires =
              tous.where((u) => u.role == UserRole.proprietaire).toList();
          final agents = tous.where((u) => u.role == UserRole.agent).toList();
          final admins = tous.where((u) => u.role == UserRole.admin).toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _ListeUtilisateurs(
                utilisateurs: locataires,
                firestoreService: firestoreService,
                messageVide: 'Aucun locataire',
              ),
              _ListeUtilisateurs(
                utilisateurs: proprietaires,
                firestoreService: firestoreService,
                messageVide: 'Aucun propriétaire',
              ),
              _ListeUtilisateurs(
                utilisateurs: agents,
                firestoreService: firestoreService,
                messageVide: 'Aucun agent',
              ),
              _ListeUtilisateurs(
                utilisateurs: admins,
                firestoreService: firestoreService,
                messageVide: 'Aucun admin',
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ListeUtilisateurs extends StatelessWidget {
  final List<UserModel> utilisateurs;
  final FirestoreService firestoreService;
  final String messageVide;

  const _ListeUtilisateurs({
    required this.utilisateurs,
    required this.firestoreService,
    required this.messageVide,
  });

  @override
  Widget build(BuildContext context) {
    if (utilisateurs.isEmpty) {
      return EmptyState(
        icone: Icons.group_outlined,
        titre: messageVide,
        message: 'Aucun compte de ce type pour l\'instant.',
        couleur: AppColors.violetAdmin,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: utilisateurs.length,
      itemBuilder: (context, index) {
        final user = utilisateurs[index];
        return _CarteUtilisateur(
          user: user,
          firestoreService: firestoreService,
        );
      },
    );
  }
}

class _CarteUtilisateur extends StatelessWidget {
  final UserModel user;
  final FirestoreService firestoreService;

  const _CarteUtilisateur({required this.user, required this.firestoreService});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border:
            user.estActif
                ? null
                : Border.all(color: AppColors.erreur.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // avatar
          CircleAvatar(
            radius: 24,
            backgroundColor: _couleurRole(user.role),
            backgroundImage:
                user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
            child:
                user.photoUrl == null
                    ? Text(
                      user.nomComplet.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                    : null,
          ),
          const SizedBox(width: 12),

          // infos
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        user.nomComplet,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.texte,
                        ),
                      ),
                    ),
                    if (!user.estActif)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.erreur.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Suspendu',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.erreur,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                Text(
                  user.email,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondaire,
                  ),
                ),
                if (user.telephone != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    user.telephone!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.texteLeger,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // actions
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppColors.grisMoyen),
            onSelected: (valeur) async {
              if (valeur == 'suspendre') {
                await firestoreService.modifierStatutUtilisateur(
                  user.uid,
                  false,
                );
              } else if (valeur == 'activer') {
                await firestoreService.modifierStatutUtilisateur(
                  user.uid,
                  true,
                );
              } else if (valeur == 'supprimer') {
                final confirme = await showDialog<bool>(
                  context: context,
                  builder:
                      (ctx) => AlertDialog(
                        title: const Text('Supprimer cet utilisateur ?'),
                        content: const Text('Cette action est irréversible.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Annuler'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.erreur,
                            ),
                            child: const Text(
                              'Supprimer',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                );
                if (confirme == true) {
                  await firestoreService.supprimerUtilisateur(user.uid);
                }
              }
            },
            itemBuilder:
                (context) => [
                  if (user.estActif)
                    const PopupMenuItem(
                      value: 'suspendre',
                      child: Row(
                        children: [
                          Icon(Icons.block, color: AppColors.avertissement),
                          SizedBox(width: 8),
                          Text('Suspendre'),
                        ],
                      ),
                    )
                  else
                    const PopupMenuItem(
                      value: 'activer',
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            color: AppColors.succes,
                          ),
                          SizedBox(width: 8),
                          Text('Activer'),
                        ],
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'supprimer',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, color: AppColors.erreur),
                        SizedBox(width: 8),
                        Text(
                          'Supprimer',
                          style: TextStyle(color: AppColors.erreur),
                        ),
                      ],
                    ),
                  ),
                ],
          ),
        ],
      ),
    );
  }

  Color _couleurRole(UserRole role) {
    switch (role) {
      case UserRole.proprietaire:
        return AppColors.vertProprietaire;
      case UserRole.agent:
        return AppColors.bleuFonce;
      case UserRole.locataire:
        return AppColors.tealLocataire;
      case UserRole.admin:
        return AppColors.violetAdmin;
    }
  }
}
