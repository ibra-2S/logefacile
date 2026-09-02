import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/models/message_model.dart';
import '../../../core/models/property_model.dart';
import '../../../core/models/visit_request_model.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/services/stats_pdf_service.dart';
import '../../../core/widgets/brand.dart';
import '../../../core/widgets/cloche_notifications.dart';
import '../../../features/auth/providers/auth_provider.dart';

class OwnerDashboard extends ConsumerWidget {
  const OwnerDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final utilisateur = ref.watch(utilisateurActuelProvider).asData?.value;
    final firestoreService = FirestoreService();

    return Scaffold(
      backgroundColor: AppColors.fond,
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.bleuFonce, AppColors.bleuMoyen],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
          ),
        ),
        title: const LogeFacileWordmark(height: 30, monoColor: Colors.white),
        actions: [
          if (utilisateur != null) ClocheNotifications(uid: utilisateur.uid),
          const SizedBox(width: 4),
        ],
      ),
      body:
          utilisateur == null
              ? const Center(child: CircularProgressIndicator())
              : StreamBuilder<List<PropertyModel>>(
                stream: firestoreService.biensDuProprietaire(utilisateur.uid),
                builder: (context, snapshotBiens) {
                  return StreamBuilder<List<VisitRequestModel>>(
                    stream: firestoreService.demandesRecues(utilisateur.uid),
                    builder: (context, snapshotDemandes) {
                      return StreamBuilder<List<ConversationModel>>(
                        stream: firestoreService.conversationsUtilisateur(
                          utilisateur.uid,
                        ),
                        builder: (context, snapshotConvs) {
                          final biens = snapshotBiens.data ?? [];
                          final demandes = snapshotDemandes.data ?? [];
                          final conversations = snapshotConvs.data ?? [];

                          final vuesTotales = biens.fold<int>(
                            0,
                            (total, b) => total + b.nombreVues,
                          );
                          final demandesTotales = demandes.length;
                          final demandesNonTraitees =
                              demandes.where((d) => d.estEnAttente).length;
                          final messagesNonLus = conversations.fold<int>(
                            0,
                            (total, conv) =>
                                total +
                                (conv.messagesNonLus[utilisateur.uid] ?? 0),
                          );
                          final favorisTotaux = biens.fold<int>(
                            0,
                            (t, b) => t + b.nombreFavoris,
                          );
                          final acceptees =
                              demandes
                                  .where(
                                    (d) => d.statut == StatutDemande.acceptee,
                                  )
                                  .length;
                          final tauxAccept =
                              demandes.isEmpty
                                  ? 0
                                  : (acceptees / demandes.length * 100).round();

                          return SingleChildScrollView(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _carteBonjour(
                                  utilisateur.nomComplet.split(' ').first,
                                ),
                                const SizedBox(height: 24),
                                const Text(
                                  'Vue d\'ensemble',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.texte,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _carteStatistique(
                                        '${biens.length}',
                                        'Biens publiés',
                                        Icons.home_outlined,
                                        AppColors.vertProprietaire,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _carteStatistique(
                                        '$demandesTotales',
                                        'Demandes reçues',
                                        Icons.calendar_today_outlined,
                                        AppColors.bleuMoyen,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _carteStatistique(
                                        '${biens.where((b) => b.statut == StatutBien.loue).length}',
                                        'Biens loués',
                                        Icons.check_circle_outline,
                                        AppColors.tealLocataire,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _carteStatistique(
                                        '$vuesTotales',
                                        'Vues totales',
                                        Icons.visibility_outlined,
                                        AppColors.violetAdmin,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _carteStatistique(
                                        '$demandesNonTraitees',
                                        'Demandes en attente',
                                        Icons.hourglass_empty_outlined,
                                        AppColors.avertissement,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Expanded(child: SizedBox()),
                                  ],
                                ),
                                const SizedBox(height: 28),

                                // ── PERFORMANCES ──
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Performances',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.texte,
                                      ),
                                    ),
                                    TextButton.icon(
                                      onPressed:
                                          biens.isEmpty
                                              ? null
                                              : () => _exporterPdf(
                                                context,
                                                utilisateur.nomComplet,
                                                biens,
                                                demandes,
                                              ),
                                      icon: const Icon(
                                        Icons.picture_as_pdf_outlined,
                                        size: 18,
                                      ),
                                      label: const Text('Exporter PDF'),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                _carteGraphe(biens),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _carteStatistique(
                                        '$favorisTotaux',
                                        'Favoris reçus',
                                        Icons.favorite_border,
                                        AppColors.erreur,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _carteStatistique(
                                        '$tauxAccept %',
                                        "Taux d'acceptation",
                                        Icons.thumb_up_outlined,
                                        AppColors.succes,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 28),
                                const Text(
                                  'Actions rapides',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.texte,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _carteAction(
                                  context,
                                  emoji: '➕',
                                  titre: 'Publier un bien',
                                  description:
                                      'Ajouter un nouveau logement à louer',
                                  couleur: AppColors.vertProprietaire,
                                  onTap:
                                      () => context.push(AppRoutes.ajouterBien),
                                ),
                                const SizedBox(height: 10),
                                _carteAction(
                                  context,
                                  emoji: '🏠',
                                  titre: 'Mes biens',
                                  description: 'Gérer vos logements publiés',
                                  couleur: AppColors.bleuMoyen,
                                  onTap: () => context.push(AppRoutes.mesBiens),
                                ),
                                const SizedBox(height: 10),
                                _carteAction(
                                  context,
                                  emoji: '📅',
                                  titre: 'Demandes de visite',
                                  description:
                                      'Voir et gérer les demandes reçues',
                                  couleur: AppColors.tealLocataire,
                                  badge: demandesNonTraitees,
                                  onTap:
                                      () => context.push(
                                        AppRoutes.demandesVisite,
                                      ),
                                ),
                                const SizedBox(height: 10),
                                _carteAction(
                                  context,
                                  emoji: '💬',
                                  titre: 'Messages',
                                  description:
                                      'Vos conversations avec les locataires',
                                  couleur: AppColors.violetAdmin,
                                  badge: messagesNonLus,
                                  onTap:
                                      () =>
                                          context.push(AppRoutes.conversations),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
    );
  }

  Widget _carteBonjour(String prenom) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.bleuFonce, AppColors.bleuMoyen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bonjour, $prenom 👋',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Gérez vos biens immobiliers',
            style: TextStyle(fontSize: 14, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  static const _joursCourts = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

  List<int> _serieVues7Jours(List<PropertyModel> biens) {
    final maintenant = DateTime.now();
    return List.generate(7, (i) {
      final jour = maintenant.subtract(Duration(days: 6 - i));
      final cle =
          '${jour.year}-${jour.month.toString().padLeft(2, '0')}-${jour.day.toString().padLeft(2, '0')}';
      return biens.fold<int>(0, (t, b) => t + (b.statsVues[cle] ?? 0));
    });
  }

  Future<void> _exporterPdf(
    BuildContext context,
    String nom,
    List<PropertyModel> biens,
    List<VisitRequestModel> demandes,
  ) async {
    try {
      await StatsPdfService.exporter(
        nomProprietaire: nom,
        biens: biens,
        demandes: demandes,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Échec de l\'export : $e'),
            backgroundColor: AppColors.erreur,
          ),
        );
      }
    }
  }

  Widget _carteGraphe(List<PropertyModel> biens) {
    final serie = _serieVues7Jours(biens);
    final maxi = serie.fold<int>(0, (m, v) => v > m ? v : m);
    final total7j = serie.fold<int>(0, (t, v) => t + v);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Vues cette semaine',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondaire,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$total7j vue${total7j > 1 ? 's' : ''} sur 7 jours',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.texte,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child:
                total7j == 0
                    ? const Center(
                      child: Text(
                        'Pas encore de vues cette semaine',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.texteLeger,
                        ),
                      ),
                    )
                    : LineChart(
                      LineChartData(
                        minY: 0,
                        maxY: (maxi + 1).toDouble(),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: (maxi / 2).clamp(1, 999).toDouble(),
                          getDrawingHorizontalLine:
                              (_) => const FlLine(
                                color: AppColors.grisClair,
                                strokeWidth: 1,
                              ),
                        ),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 26,
                              interval: (maxi / 2).clamp(1, 999).toDouble(),
                              getTitlesWidget:
                                  (v, meta) => Text(
                                    v.toInt().toString(),
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: AppColors.texteLeger,
                                    ),
                                  ),
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 22,
                              getTitlesWidget: (v, meta) {
                                final i = v.toInt();
                                if (i < 0 || i > 6) return const SizedBox();
                                return Text(
                                  _joursCourts[i],
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.texteLeger,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        lineBarsData: [
                          LineChartBarData(
                            isCurved: true,
                            preventCurveOverShooting: true,
                            color: AppColors.bleuFonce,
                            barWidth: 3,
                            dotData: const FlDotData(show: true),
                            belowBarData: BarAreaData(
                              show: true,
                              color: AppColors.bleuFonce.withValues(alpha: 0.12),
                            ),
                            spots: [
                              for (var i = 0; i < 7; i++)
                                FlSpot(i.toDouble(), serie[i].toDouble()),
                            ],
                          ),
                        ],
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _carteStatistique(
    String valeur,
    String label,
    IconData icone,
    Color couleur,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, color: couleur, size: 28),
          const SizedBox(height: 8),
          Text(
            valeur,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: couleur,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondaire,
            ),
          ),
        ],
      ),
    );
  }

  Widget _carteAction(
    BuildContext context, {
    required String emoji,
    required String titre,
    required String description,
    required Color couleur,
    required VoidCallback onTap,
    int badge = 0,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
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
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: couleur.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titre,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.texte,
                    ),
                  ),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondaire,
                    ),
                  ),
                ],
              ),
            ),
            if (badge > 0)
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: AppColors.erreur,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$badge',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            else
              Icon(Icons.arrow_forward_ios, size: 14, color: couleur),
          ],
        ),
      ),
    );
  }
}
