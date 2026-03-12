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
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.bleuClair,
                          child: Text(
                            conv.bienId.substring(0, 1).toUpperCase(),
                            style: const TextStyle(
                              color: AppColors.bleuFonce,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        title: Text(
                          'Bien : ${conv.bienId.substring(0, 8)}...',
                          style: TextStyle(
                            fontWeight:
                                nonLus > 0
                                    ? FontWeight.w700
                                    : FontWeight.normal,
                            color: AppColors.texte,
                          ),
                        ),
                        subtitle: Text(
                          conv.dernierMessage.isEmpty
                              ? 'Aucun message'
                              : conv.dernierMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textSecondaire,
                            fontSize: 13,
                          ),
                        ),
                        trailing:
                            nonLus > 0
                                ? Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: AppColors.bleuFonce,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '$nonLus',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                )
                                : null,
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
}
