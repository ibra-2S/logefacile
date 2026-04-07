import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/models/message_model.dart';
import '../../../core/services/firestore_service.dart';
import '../../../features/auth/providers/auth_provider.dart';

class ConversationsScreen extends ConsumerWidget {
  const ConversationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final utilisateur = ref.watch(utilisateurActuelProvider).asData?.value;
    final firestoreService = FirestoreService();

    return Scaffold(
      backgroundColor: AppColors.fond,
      appBar: AppBar(
        backgroundColor: AppColors.bleuFonce,
        elevation: 0,
        title: const Text(
          'Messages',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
      body:
          utilisateur == null
              ? const Center(child: CircularProgressIndicator())
              : StreamBuilder<List<ConversationModel>>(
                stream: firestoreService.conversationsUtilisateur(
                  utilisateur.uid,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final conversations = snapshot.data ?? [];

                  if (conversations.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('💬', style: TextStyle(fontSize: 64)),
                          SizedBox(height: 16),
                          Text(
                            'Aucune conversation',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.texte,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Vos échanges apparaîtront ici',
                            style: TextStyle(color: AppColors.textSecondaire),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: conversations.length,
                    itemBuilder: (context, index) {
                      final conv = conversations[index];
                      final nonLus = conv.messagesNonLus[utilisateur.uid] ?? 0;
                      final nomInter = conv.nomInterlocuteur(utilisateur.uid);
                      final photoInter = conv.photoInterlocuteur(
                        utilisateur.uid,
                      );

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: CircleAvatar(
                          radius: 26,
                          backgroundColor: AppColors.bleuClair,
                          backgroundImage:
                              photoInter != null
                                  ? NetworkImage(photoInter)
                                  : null,
                          child:
                              photoInter == null
                                  ? Text(
                                    nomInter.isNotEmpty
                                        ? nomInter[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      color: AppColors.bleuFonce,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 18,
                                    ),
                                  )
                                  : null,
                        ),
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                nomInter.isNotEmpty ? nomInter : 'Inconnu',
                                style: TextStyle(
                                  fontWeight:
                                      nonLus > 0
                                          ? FontWeight.w700
                                          : FontWeight.w600,
                                  color: AppColors.texte,
                                  fontSize: 15,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              _formaterDate(conv.dateDernierMessage),
                              style: TextStyle(
                                fontSize: 11,
                                color:
                                    nonLus > 0
                                        ? AppColors.bleuFonce
                                        : AppColors.texteLeger,
                                fontWeight:
                                    nonLus > 0
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                        subtitle: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (conv.titreBien.isNotEmpty)
                                    Text(
                                      conv.titreBien,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.bleuFonce,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  Text(
                                    conv.dernierMessage.isEmpty
                                        ? 'Démarrer la conversation'
                                        : conv.dernierMessage,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color:
                                          nonLus > 0
                                              ? AppColors.texte
                                              : AppColors.textSecondaire,
                                      fontSize: 13,
                                      fontWeight:
                                          nonLus > 0
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (nonLus > 0)
                              Container(
                                margin: const EdgeInsets.only(left: 8),
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: AppColors.bleuFonce,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '$nonLus',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        onTap:
                            () => context.push(
                              AppRoutes.chat.replaceAll(':id', conv.id),
                            ),
                      );
                    },
                  );
                },
              ),
    );
  }

  String _formaterDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Hier';
    } else if (diff.inDays < 7) {
      const jours = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
      return jours[date.weekday - 1];
    } else {
      return '${date.day}/${date.month}';
    }
  }
}
