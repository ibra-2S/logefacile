import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/firestore_service.dart';

class UsersManagementScreen extends ConsumerWidget {
  const UsersManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: StreamBuilder<List<UserModel>>(
        stream: firestoreService.tousLesUtilisateurs(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final utilisateurs = snapshot.data ?? [];

          if (utilisateurs.isEmpty) {
            return const Center(
              child: Text(
                'Aucun utilisateur trouvé',
                style: TextStyle(color: AppColors.textSecondaire),
              ),
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
        },
      ),
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
                Text(
                  user.nomComplet,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.texte,
                  ),
                ),
                Text(
                  user.email,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondaire,
                  ),
                ),
                const SizedBox(height: 4),
                _badgeRole(user.role),
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
                await firestoreService.supprimerUtilisateur(user.uid);
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
        return AppColors.avertissement;
      case UserRole.admin:
        return AppColors.erreur;
    }
  }

  Widget _badgeRole(UserRole role) {
    final labels = {
      UserRole.proprietaire: 'Propriétaire',
      UserRole.agent: 'Agent',
      UserRole.locataire: 'Locataire',
      UserRole.admin: 'Admin',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _couleurRole(role).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        labels[role]!,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _couleurRole(role),
        ),
      ),
    );
  }
}
