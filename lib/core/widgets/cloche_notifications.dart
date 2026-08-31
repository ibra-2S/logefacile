import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_colors.dart';
import '../constants/app_routes.dart';
import '../models/notification_model.dart';
import '../services/firestore_service.dart';

/// Icône cloche avec pastille du nombre de notifications non lues.
class ClocheNotifications extends StatelessWidget {
  final String uid;
  final Color couleurIcone;
  const ClocheNotifications({
    super.key,
    required this.uid,
    this.couleurIcone = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    final service = FirestoreService();
    return StreamBuilder<List<NotificationModel>>(
      stream: service.notificationsUtilisateur(uid),
      builder: (context, snapshot) {
        final nonLues = (snapshot.data ?? []).where((n) => !n.lu).length;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: Icon(Icons.notifications_outlined, color: couleurIcone),
              onPressed: () => context.push(AppRoutes.notifications),
              tooltip: 'Notifications',
            ),
            if (nonLues > 0)
              Positioned(
                right: 4,
                top: 4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                  decoration: BoxDecoration(
                    color: AppColors.erreur,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: Text(
                    nonLues > 9 ? '9+' : '$nonLues',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
