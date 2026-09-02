import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/models/property_model.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/widgets/admin_charts.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../core/widgets/stats_periode_card.dart';

class AdminStatsScreen extends ConsumerWidget {
  const AdminStatsScreen({super.key});

  static const _moisCourts = [
    'janv.',
    'févr.',
    'mars',
    'avr.',
    'mai',
    'juin',
    'juil.',
    'août',
    'sept.',
    'oct.',
    'nov.',
    'déc.',
  ];

  /// 12 derniers mois : (premier jour du mois, libellé court)
  List<(DateTime, String)> _douzeMois() {
    final maintenant = DateTime.now();
    return List.generate(12, (i) {
      final d = DateTime(maintenant.year, maintenant.month - 11 + i, 1);
      return (d, _moisCourts[d.month - 1]);
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = FirestoreService();

    return Scaffold(
      backgroundColor: AppColors.fond,
      appBar: AppBar(
        backgroundColor: AppColors.bleuFonce,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Statistiques',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: StreamBuilder<List<UserModel>>(
        stream: service.tousLesUtilisateurs(),
        builder: (context, snapUsers) {
          return StreamBuilder<List<PropertyModel>>(
            stream: service.tousLesBiens(),
            builder: (context, snapBiens) {
              return StreamBuilder<List<Map<String, dynamic>>>(
                stream: service.tousLesSignalements(),
                builder: (context, snapReports) {
                  if (snapUsers.connectionState == ConnectionState.waiting ||
                      snapBiens.connectionState == ConnectionState.waiting) {
                    return const ScreenSkeleton();
                  }
                  final users = snapUsers.data ?? [];
                  final biens = snapBiens.data ?? [];
                  final reports = snapReports.data ?? [];

                  return ListView(
                    padding: const EdgeInsets.all(20),
                    children: _sections(users, biens, reports),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  List<Widget> _sections(
    List<UserModel> users,
    List<PropertyModel> biens,
    List<Map<String, dynamic>> reports,
  ) {
    final mois = _douzeMois();

    // ── taux d'occupation ──
    final dispo = biens.where((b) => b.statut == StatutBien.disponible).length;
    final occ = biens.where((b) => b.statut == StatutBien.loue).length;
    final maint = biens.where((b) => b.statut == StatutBien.suspendu).length;

    // ── types de bien ──
    int parType(TypeBien t) => biens.where((b) => b.type == t).length;

    // ── revenus locatifs estimés (cumul mensuel) ──
    final revenus =
        mois.map((m) {
          final finMois = DateTime(m.$1.year, m.$1.month + 1, 0, 23, 59, 59);
          return biens
              .where(
                (b) =>
                    b.statut == StatutBien.loue &&
                    !b.dateMiseAJour.isAfter(finMois),
              )
              .fold<double>(0, (t, b) => t + b.prix);
        }).toList();

    // ── délai moyen de location ──
    final delais =
        biens
            .where((b) => b.statut == StatutBien.loue)
            .map((b) => b.dateMiseAJour.difference(b.datePublication).inDays)
            .where((j) => j >= 0)
            .toList();
    final delaiMoyen =
        delais.isEmpty
            ? null
            : (delais.reduce((a, b) => a + b) / delais.length).round();

    // ── distribution des loyers ──
    const bornes = [500000, 1000000, 2000000, 5000000];
    const labelsLoyers = ['< 500k', '500k–1M', '1M–2M', '2M–5M', '> 5M'];
    final distLoyers = List.filled(5, 0);
    for (final b in biens) {
      var idx = bornes.indexWhere((seuil) => b.prix < seuil);
      if (idx == -1) idx = 4;
      distLoyers[idx]++;
    }

    // ── signalements ──
    final resolus = reports.where((r) => r['traite'] == true).length;
    final enAttente = reports.length - resolus;

    // ── top quartiers ──
    final parQuartier = <String, int>{};
    for (final b in biens) {
      final q = (b.quartier ?? '').trim();
      if (q.isEmpty) continue;
      parQuartier[q] = (parQuartier[q] ?? 0) + 1;
    }
    final topQuartiers =
        parQuartier.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    return [
      // 1 & 2 côte à côte
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: DonutChart(
              titre: "Taux d'occupation",
              icone: Icons.donut_large_outlined,
              couleur: AppColors.bleuFonce,
              parts: [
                (label: 'Disponible', valeur: dispo, couleur: AppColors.succes),
                (label: 'Occupé', valeur: occ, couleur: AppColors.bleuMoyen),
                (
                  label: 'Maintenance',
                  valeur: maint,
                  couleur: AppColors.avertissement,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DonutChart(
              titre: 'Types de bien',
              icone: Icons.category_outlined,
              couleur: AppColors.vertProprietaire,
              parts: [
                (
                  label: 'Maison',
                  valeur: parType(TypeBien.maison),
                  couleur: AppColors.vertProprietaire,
                ),
                (
                  label: 'Appart.',
                  valeur: parType(TypeBien.appartement),
                  couleur: AppColors.bleuMoyen,
                ),
                (
                  label: 'Chambre',
                  valeur: parType(TypeBien.chambre),
                  couleur: AppColors.tealLocataire,
                ),
                (
                  label: 'Studio',
                  valeur: parType(TypeBien.studio),
                  couleur: AppColors.violetAdmin,
                ),
              ],
            ),
          ),
        ],
      ),

      // biens publiés / inscriptions / connexions — adaptables semaine·mois·année
      StatsPeriodeCard(
        titre: 'Biens publiés',
        icone: Icons.home_work_outlined,
        couleur: AppColors.vertProprietaire,
        evenements: biens.map((b) => b.datePublication).toList(),
      ),
      StatsPeriodeCard(
        titre: 'Inscriptions des utilisateurs',
        icone: Icons.group_add_outlined,
        couleur: AppColors.bleuMoyen,
        evenements: users.map((u) => u.dateCreation).toList(),
      ),
      StatsPeriodeCard(
        titre: 'Fréquence de connexion',
        sousTitre: 'dernière connexion par compte',
        icone: Icons.login_rounded,
        couleur: AppColors.tealLocataire,
        courbe: true,
        evenements: users.map((u) => u.derniereCo).toList(),
      ),

      // revenus estimés
      CourbeAireChart(
        titre: 'Revenus locatifs estimés',
        sousTitre: 'loyers des biens occupés · cumul mensuel (GNF)',
        icone: Icons.payments_outlined,
        couleur: AppColors.vertProprietaire,
        labels: [for (final m in mois) m.$2],
        valeurs: revenus,
        formatValeur: (v) => formatNombre(v),
      ),

      // délai moyen de location
      KpiCard(
        titre: 'Délai moyen de location',
        valeur: delaiMoyen == null ? '—' : '$delaiMoyen j',
        sousTitre:
            'entre la publication et la mise en location'
            '${delais.isEmpty ? '' : ' · sur ${delais.length} bien(s)'}',
        icone: Icons.schedule_outlined,
        couleur: AppColors.bleuMoyen,
      ),

      // distribution des loyers
      HistogrammeFrequence(
        titre: 'Distribution des loyers',
        sousTitre: 'nombre de biens par tranche de prix (GNF/mois)',
        icone: Icons.bar_chart_outlined,
        couleur: AppColors.bleuFonce,
        labels: labelsLoyers,
        valeurs: distLoyers,
      ),

      // signalements
      BarresHorizontales(
        titre: 'Signalements',
        icone: Icons.flag_outlined,
        couleur: AppColors.erreur,
        items: [
          (label: 'Résolus', valeur: resolus, couleur: AppColors.succes),
          (
            label: 'En attente',
            valeur: enAttente,
            couleur: AppColors.avertissement,
          ),
        ],
      ),

      // top quartiers
      BarresHorizontales(
        titre: 'Top quartiers',
        icone: Icons.place_outlined,
        couleur: AppColors.bleuFonce,
        items: [
          for (final e in topQuartiers.take(6))
            (label: e.key, valeur: e.value, couleur: AppColors.bleuMoyen),
        ],
      ),

      const SizedBox(height: 12),
    ];
  }
}
