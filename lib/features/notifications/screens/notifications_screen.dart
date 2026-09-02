import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/models/notification_model.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../features/auth/providers/auth_provider.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  final _service = FirestoreService();

  @override
  void initState() {
    super.initState();
    // à l'ouverture : purge les notifications lues depuis plus de 24 h
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = ref.read(utilisateurActuelProvider).asData?.value?.uid;
      if (uid != null) _service.nettoyerNotificationsExpirees(uid);
    });
  }

  @override
  Widget build(BuildContext context) {
    final utilisateur = ref.watch(utilisateurActuelProvider).asData?.value;
    final service = _service;

    return Scaffold(
      backgroundColor: AppColors.fond,
      appBar: AppBar(
        backgroundColor: AppColors.bleuFonce,
        foregroundColor: Colors.white,
        title: const Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          if (utilisateur != null)
            TextButton(
              onPressed:
                  () => service.marquerToutesNotificationsLues(utilisateur.uid),
              child: const Text(
                'Tout lire',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body:
          utilisateur == null
              ? const ListTileSkeleton()
              : StreamBuilder<List<NotificationModel>>(
                stream: service.notificationsUtilisateur(utilisateur.uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const ListTileSkeleton();
                  }
                  final notifs = snapshot.data ?? [];
                  if (notifs.isEmpty) {
                    return const EmptyState(
                      icone: Icons.notifications_none,
                      titre: 'Aucune notification',
                      message:
                          'Les demandes de visite, réponses et messages '
                          's\'afficheront ici.',
                      couleur: AppColors.bleuFonce,
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: notifs.length,
                    separatorBuilder:
                        (_, __) => const Divider(height: 1, indent: 72),
                    itemBuilder: (context, index) {
                      final n = notifs[index];
                      return Dismissible(
                        key: ValueKey(n.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: AppColors.erreur,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(
                            Icons.delete_outline,
                            color: Colors.white,
                          ),
                        ),
                        onDismissed: (_) => service.supprimerNotification(n.id),
                        child: ListTile(
                          tileColor:
                              n.lu ? Colors.transparent : AppColors.bleuClair,
                          leading: CircleAvatar(
                            backgroundColor: n.couleur.withValues(alpha: 0.12),
                            child: Icon(n.icone, color: n.couleur, size: 20),
                          ),
                          title: Text(
                            n.titre,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight:
                                  n.lu ? FontWeight.w600 : FontWeight.w700,
                              color: AppColors.texte,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                n.corps,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondaire,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _dateRelative(n.dateCreation),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.texteLeger,
                                ),
                              ),
                            ],
                          ),
                          isThreeLine: true,
                          onTap: () {
                            service.marquerNotificationLue(n.id);
                            if (n.lien.isNotEmpty) context.push(n.lien);
                          },
                        ),
                      );
                    },
                  );
                },
              ),
    );
  }

  String _dateRelative(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return "À l'instant";
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours} h';
    if (diff.inDays < 7) return 'Il y a ${diff.inDays} j';
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
