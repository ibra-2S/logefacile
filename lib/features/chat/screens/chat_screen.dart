import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/models/message_model.dart';
import '../../../core/services/firestore_service.dart';
import '../../../features/auth/providers/auth_provider.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String convId;
  const ChatScreen({super.key, required this.convId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _firestoreService = FirestoreService();

  @override
  void dispose() {
    _messageCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // marquer les messages non lus comme lus
  Future<void> _marquerMessagesLus(
    String monUid,
    List<MessageModel> messages,
  ) async {
    for (final msg in messages) {
      if (!msg.estLu && msg.expediteurId != monUid) {
        await _firestoreService.marquerMessageLu(widget.convId, msg.id);
      }
    }
    // réinitialiser le compteur de messages non lus
    await _firestoreService.reinitialiserMessagesNonLus(widget.convId, monUid);
  }

  Future<void> _envoyerMessage() async {
    if (_messageCtrl.text.trim().isEmpty) return;

    final utilisateur = ref.read(utilisateurActuelProvider).asData?.value;
    if (utilisateur == null) return;

    final message = MessageModel(
      id: '',
      expediteurId: utilisateur.uid,
      contenu: _messageCtrl.text.trim(),
      dateEnvoi: DateTime.now(),
      estLu: false,
    );

    _messageCtrl.clear();
    await _firestoreService.envoyerMessage(widget.convId, message);

    // scroller vers le bas
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final utilisateur = ref.watch(utilisateurActuelProvider).asData?.value;

    return Scaffold(
      backgroundColor: AppColors.fond,
      appBar: AppBar(
        backgroundColor: AppColors.bleuFonce,
        elevation: 0,
        title: const Text(
          'Conversation',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // liste des messages
          Expanded(
            child:
                utilisateur == null
                    ? const Center(child: CircularProgressIndicator())
                    : StreamBuilder<List<MessageModel>>(
                      stream: _firestoreService.messagesConversation(
                        widget.convId,
                      ),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final messages = snapshot.data ?? [];

                        // marquer les messages reçus comme lus
                        if (messages.isNotEmpty) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _marquerMessagesLus(utilisateur.uid, messages);
                          });
                        }

                        if (messages.isEmpty) {
                          return const Center(
                            child: Text(
                              'Envoyez votre premier message !',
                              style: TextStyle(color: AppColors.textSecondaire),
                            ),
                          );
                        }

                        // scroller vers le bas automatiquement
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (_scrollCtrl.hasClients) {
                            _scrollCtrl.jumpTo(
                              _scrollCtrl.position.maxScrollExtent,
                            );
                          }
                        });

                        return ListView.builder(
                          controller: _scrollCtrl,
                          padding: const EdgeInsets.all(16),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final msg = messages[index];
                            final estMoi = msg.expediteurId == utilisateur.uid;
                            // afficher "Vu" uniquement sur le dernier message envoyé
                            final estDernierMessage =
                                index == messages.length - 1;
                            return _BullMessage(
                              message: msg,
                              estMoi: estMoi,
                              afficherStatut: estMoi && estDernierMessage,
                            );
                          },
                        );
                      },
                    ),
          ),

          // champ de saisie
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageCtrl,
                    decoration: InputDecoration(
                      hintText: 'Écrire un message...',
                      hintStyle: const TextStyle(
                        color: AppColors.texteLeger,
                        fontSize: 14,
                      ),
                      filled: true,
                      fillColor: AppColors.fond,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (_) => _envoyerMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _envoyerMessage,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: AppColors.bleuFonce,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BullMessage extends StatelessWidget {
  final MessageModel message;
  final bool estMoi;
  final bool afficherStatut;

  const _BullMessage({
    required this.message,
    required this.estMoi,
    this.afficherStatut = false,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: estMoi ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        decoration: BoxDecoration(
          color: estMoi ? AppColors.bleuFonce : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(estMoi ? 16 : 4),
            bottomRight: Radius.circular(estMoi ? 4 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              estMoi ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message.contenu,
              style: TextStyle(
                fontSize: 14,
                color: estMoi ? Colors.white : AppColors.texte,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${message.dateEnvoi.hour.toString().padLeft(2, '0')}:'
                  '${message.dateEnvoi.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontSize: 11,
                    color:
                        estMoi
                            ? Colors.white.withValues(alpha: 0.7)
                            : AppColors.texteLeger,
                  ),
                ),
                // statut "Vu" ou "Envoyé" sur le dernier message
                if (estMoi && afficherStatut) ...[
                  const SizedBox(width: 4),
                  Text(
                    message.estLu ? 'Vu' : '✓',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight:
                          message.estLu ? FontWeight.w700 : FontWeight.normal,
                      color:
                          message.estLu
                              ? Colors.greenAccent
                              : Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
