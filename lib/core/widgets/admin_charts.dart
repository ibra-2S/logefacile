import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Part d'un donut / d'une liste de barres.
typedef PartStat = ({String label, num valeur, Color couleur});

BoxDecoration _carte() => BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(14),
  boxShadow: [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ],
);

Widget _entete(
  IconData icone,
  Color couleur,
  String titre, [
  String sous = '',
]) {
  return Row(
    children: [
      Icon(icone, color: couleur, size: 20),
      const SizedBox(width: 8),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titre,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.texte,
              ),
            ),
            if (sous.isNotEmpty)
              Text(
                sous,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.texteLeger,
                ),
              ),
          ],
        ),
      ),
    ],
  );
}

/// Nombre compact : 1 250 000 -> "1.25 M"
String formatNombre(num n) {
  if (n >= 1000000) {
    return '${(n / 1000000).toStringAsFixed(n % 1000000 == 0 ? 0 : 1)} M';
  }
  if (n >= 1000) {
    return '${(n / 1000).toStringAsFixed(n % 1000 == 0 ? 0 : 1)} k';
  }
  return n.toStringAsFixed(0);
}

// ── DONUT ─────────────────────────────────────────────────────────────────

class DonutChart extends StatelessWidget {
  final String titre;
  final IconData icone;
  final Color couleur;
  final List<PartStat> parts;

  /// texte affiché au centre (ex. total) ; sinon le total est calculé
  final String? centre;

  const DonutChart({
    super.key,
    required this.titre,
    required this.icone,
    required this.couleur,
    required this.parts,
    this.centre,
  });

  @override
  Widget build(BuildContext context) {
    final total = parts.fold<num>(0, (t, p) => t + p.valeur);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: _carte(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _entete(icone, couleur, titre),
          const SizedBox(height: 12),
          SizedBox(
            height: 130,
            child:
                total == 0
                    ? const Center(
                      child: Text(
                        'Aucune donnée',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.texteLeger,
                        ),
                      ),
                    )
                    : Stack(
                      alignment: Alignment.center,
                      children: [
                        PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 38,
                            sections: [
                              for (final p in parts)
                                if (p.valeur > 0)
                                  PieChartSectionData(
                                    value: p.valeur.toDouble(),
                                    color: p.couleur,
                                    radius: 20,
                                    showTitle: false,
                                  ),
                            ],
                          ),
                        ),
                        Text(
                          centre ?? '$total',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.texte,
                          ),
                        ),
                      ],
                    ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              for (final p in parts)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: p.couleur,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '${p.label} · ${p.valeur}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondaire,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── COURBE + AIRE ─────────────────────────────────────────────────────────

class CourbeAireChart extends StatelessWidget {
  final String titre;
  final String sousTitre;
  final IconData icone;
  final Color couleur;
  final List<String> labels;
  final List<double> valeurs;

  /// formate les valeurs de l'axe et de l'info-bulle (ex. montants)
  final String Function(double)? formatValeur;

  const CourbeAireChart({
    super.key,
    required this.titre,
    required this.icone,
    required this.couleur,
    required this.labels,
    required this.valeurs,
    this.sousTitre = '',
    this.formatValeur,
  });

  @override
  Widget build(BuildContext context) {
    final maxV =
        valeurs.isEmpty ? 0.0 : valeurs.reduce((a, b) => a > b ? a : b);
    final maxY = maxV == 0 ? 1.0 : maxV * 1.2;
    final n = valeurs.length;
    final fmt = formatValeur ?? (v) => v.toInt().toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      decoration: _carte(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _entete(icone, couleur, titre, sousTitre),
          const SizedBox(height: 16),
          SizedBox(
            height: 150,
            child:
                (n == 0 || maxV == 0)
                    ? const Center(
                      child: Text(
                        'Aucune donnée',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.texteLeger,
                        ),
                      ),
                    )
                    : LineChart(
                      LineChartData(
                        minY: 0,
                        maxY: maxY,
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: maxY / 3,
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
                              reservedSize: 38,
                              interval: maxY / 3,
                              getTitlesWidget:
                                  (v, meta) => Text(
                                    fmt(v),
                                    style: const TextStyle(
                                      fontSize: 9,
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
                                if (i < 0 || i >= n) return const SizedBox();
                                final pas = n > 8 ? 2 : 1;
                                if (i % pas != 0) return const SizedBox();
                                return Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    labels[i],
                                    style: const TextStyle(
                                      fontSize: 9,
                                      color: AppColors.texteLeger,
                                    ),
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
                            color: couleur,
                            barWidth: 3,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              color: couleur.withValues(alpha: 0.14),
                            ),
                            spots: [
                              for (var i = 0; i < n; i++)
                                FlSpot(i.toDouble(), valeurs[i]),
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
}

// ── BARRES HORIZONTALES ───────────────────────────────────────────────────

class BarresHorizontales extends StatelessWidget {
  final String titre;
  final IconData icone;
  final Color couleur;
  final List<PartStat> items;

  /// affiche la valeur formatée (ex. montants) à droite de chaque barre
  final String Function(num)? formatValeur;

  const BarresHorizontales({
    super.key,
    required this.titre,
    required this.icone,
    required this.couleur,
    required this.items,
    this.formatValeur,
  });

  @override
  Widget build(BuildContext context) {
    final maxV =
        items.isEmpty
            ? 0
            : items.map((e) => e.valeur).reduce((a, b) => a > b ? a : b);
    final fmt = formatValeur ?? (v) => v.toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: _carte(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _entete(icone, couleur, titre),
          const SizedBox(height: 14),
          if (items.isEmpty || maxV == 0)
            const Text(
              'Aucune donnée',
              style: TextStyle(fontSize: 12, color: AppColors.texteLeger),
            )
          else
            for (final it in items)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    SizedBox(
                      width: 96,
                      child: Text(
                        it.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondaire,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Stack(
                        children: [
                          Container(
                            height: 16,
                            decoration: BoxDecoration(
                              color: AppColors.grisClair,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor:
                                maxV == 0
                                    ? 0
                                    : (it.valeur / maxV)
                                        .clamp(0.02, 1)
                                        .toDouble(),
                            child: Container(
                              height: 16,
                              decoration: BoxDecoration(
                                color: it.couleur,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 44,
                      child: Text(
                        fmt(it.valeur),
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.texte,
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

// ── HISTOGRAMME DE FRÉQUENCE ──────────────────────────────────────────────

class HistogrammeFrequence extends StatelessWidget {
  final String titre;
  final String sousTitre;
  final IconData icone;
  final Color couleur;
  final List<String> labels;
  final List<int> valeurs;

  const HistogrammeFrequence({
    super.key,
    required this.titre,
    required this.icone,
    required this.couleur,
    required this.labels,
    required this.valeurs,
    this.sousTitre = '',
  });

  @override
  Widget build(BuildContext context) {
    final maxV = valeurs.isEmpty ? 0 : valeurs.reduce((a, b) => a > b ? a : b);
    final maxY = (maxV == 0 ? 1 : maxV + (maxV / 4).ceil()).toDouble();
    final raw = (maxY / 4).ceilToDouble();
    final interval = raw < 1 ? 1.0 : raw;
    final n = valeurs.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(16, 16, 12, 10),
      decoration: _carte(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _entete(icone, couleur, titre, sousTitre),
          const SizedBox(height: 16),
          SizedBox(
            height: 150,
            child:
                (n == 0 || maxV == 0)
                    ? const Center(
                      child: Text(
                        'Aucune donnée',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.texteLeger,
                        ),
                      ),
                    )
                    : BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        minY: 0,
                        maxY: maxY,
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: interval,
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
                              reservedSize: 28,
                              interval: interval,
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
                              reservedSize: 32,
                              getTitlesWidget: (v, meta) {
                                final i = v.toInt();
                                if (i < 0 || i >= n) return const SizedBox();
                                return Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    labels[i],
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 8,
                                      color: AppColors.texteLeger,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        barGroups: [
                          for (var i = 0; i < n; i++)
                            BarChartGroupData(
                              x: i,
                              barRods: [
                                BarChartRodData(
                                  toY: valeurs[i].toDouble(),
                                  color: couleur,
                                  width: 18,
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(4),
                                  ),
                                ),
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
}

// ── CARTE KPI ─────────────────────────────────────────────────────────────

class KpiCard extends StatelessWidget {
  final String titre;
  final String valeur;
  final String sousTitre;
  final IconData icone;
  final Color couleur;

  const KpiCard({
    super.key,
    required this.titre,
    required this.valeur,
    required this.icone,
    required this.couleur,
    this.sousTitre = '',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: _carte(),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: couleur.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icone, color: couleur, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titre,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondaire,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  valeur,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: couleur,
                  ),
                ),
                if (sousTitre.isNotEmpty)
                  Text(
                    sousTitre,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.texteLeger,
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
