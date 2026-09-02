import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

enum _Periode { semaine, mois, annee }

/// Carte de statistique adaptable par jour de la semaine, par mois de l'année
/// ou par année. On lui passe la liste des dates d'événements à compter.
/// `courbe: true` -> courbe + aire ; sinon histogramme.
class StatsPeriodeCard extends StatefulWidget {
  final String titre;
  final String sousTitre;
  final IconData icone;
  final Color couleur;
  final List<DateTime> evenements;
  final bool courbe;

  const StatsPeriodeCard({
    super.key,
    required this.titre,
    required this.icone,
    required this.couleur,
    required this.evenements,
    this.sousTitre = '',
    this.courbe = false,
  });

  @override
  State<StatsPeriodeCard> createState() => _StatsPeriodeCardState();
}

class _StatsPeriodeCardState extends State<StatsPeriodeCard> {
  _Periode _periode = _Periode.semaine;

  static const _jours = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
  static const _mois = [
    'Jan',
    'Fév',
    'Mar',
    'Avr',
    'Mai',
    'Juin',
    'Juil',
    'Aoû',
    'Sep',
    'Oct',
    'Nov',
    'Déc',
  ];

  ({List<String> labels, List<int> valeurs}) _serie() {
    final ev = widget.evenements;
    switch (_periode) {
      case _Periode.semaine:
        final c = List.filled(7, 0);
        for (final d in ev) {
          c[d.weekday - 1]++;
        }
        return (labels: _jours, valeurs: c);
      case _Periode.mois:
        final c = List.filled(12, 0);
        for (final d in ev) {
          c[d.month - 1]++;
        }
        return (labels: _mois, valeurs: c);
      case _Periode.annee:
        if (ev.isEmpty) return (labels: const [], valeurs: const []);
        final anneeMin = ev.map((d) => d.year).reduce((a, b) => a < b ? a : b);
        final anneeMax = DateTime.now().year;
        final labels = <String>[];
        final valeurs = <int>[];
        for (var y = anneeMin; y <= anneeMax; y++) {
          labels.add('$y');
          valeurs.add(ev.where((d) => d.year == y).length);
        }
        return (labels: labels, valeurs: valeurs);
    }
  }

  @override
  Widget build(BuildContext context) {
    final serie = _serie();
    final total = widget.evenements.length;
    final maxVal =
        serie.valeurs.isEmpty
            ? 0
            : serie.valeurs.reduce((a, b) => a > b ? a : b);
    final maxY = (maxVal == 0 ? 1 : maxVal + (maxVal / 4).ceil()).toDouble();
    final rawInterval = (maxY / 4).ceilToDouble();
    final interval = rawInterval < 1 ? 1.0 : rawInterval;
    final n = serie.labels.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(16, 16, 12, 10),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(widget.icone, color: widget.couleur, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.titre,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.texte,
                      ),
                    ),
                    Text(
                      '$total au total'
                      '${widget.sousTitre.isEmpty ? '' : ' · ${widget.sousTitre}'}',
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
          const SizedBox(height: 12),
          _selecteurPeriode(),
          const SizedBox(height: 14),
          SizedBox(
            height: 150,
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
                    : widget.courbe
                    ? _courbeAire(serie, maxY, interval, n)
                    : _histogramme(serie, maxY, interval, n),
          ),
        ],
      ),
    );
  }

  FlGridData _grille(double interval) => FlGridData(
    show: true,
    drawVerticalLine: false,
    horizontalInterval: interval,
    getDrawingHorizontalLine:
        (_) => const FlLine(color: AppColors.grisClair, strokeWidth: 1),
  );

  FlTitlesData _titres(
    ({List<String> labels, List<int> valeurs}) serie,
    double interval,
    int n,
  ) => FlTitlesData(
    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    leftTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 28,
        interval: interval,
        getTitlesWidget:
            (v, meta) => Text(
              v.toInt().toString(),
              style: const TextStyle(fontSize: 10, color: AppColors.texteLeger),
            ),
      ),
    ),
    bottomTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 24,
        getTitlesWidget: (v, meta) {
          final i = v.toInt();
          if (i < 0 || i >= n) return const SizedBox();
          final pas = n > 8 ? 2 : 1;
          if (i % pas != 0) return const SizedBox();
          return Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              serie.labels[i],
              style: const TextStyle(fontSize: 9, color: AppColors.texteLeger),
            ),
          );
        },
      ),
    ),
  );

  Widget _histogramme(
    ({List<String> labels, List<int> valeurs}) serie,
    double maxY,
    double interval,
    int n,
  ) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        minY: 0,
        maxY: maxY,
        gridData: _grille(interval),
        borderData: FlBorderData(show: false),
        titlesData: _titres(serie, interval, n),
        barGroups: [
          for (var i = 0; i < n; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: serie.valeurs[i].toDouble(),
                  color: widget.couleur,
                  width: n > 10 ? 10 : 16,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _courbeAire(
    ({List<String> labels, List<int> valeurs}) serie,
    double maxY,
    double interval,
    int n,
  ) {
    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxY,
        gridData: _grille(interval),
        borderData: FlBorderData(show: false),
        titlesData: _titres(serie, interval, n),
        lineBarsData: [
          LineChartBarData(
            isCurved: true,
            preventCurveOverShooting: true,
            color: widget.couleur,
            barWidth: 3,
            dotData: FlDotData(show: n <= 12),
            belowBarData: BarAreaData(
              show: true,
              color: widget.couleur.withValues(alpha: 0.14),
            ),
            spots: [
              for (var i = 0; i < n; i++)
                FlSpot(i.toDouble(), serie.valeurs[i].toDouble()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _selecteurPeriode() {
    Widget chip(String label, _Periode p) {
      final actif = _periode == p;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _periode = p),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            padding: const EdgeInsets.symmetric(vertical: 7),
            decoration: BoxDecoration(
              color: actif ? widget.couleur : AppColors.fond,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: actif ? Colors.white : AppColors.textSecondaire,
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        chip('Semaine', _Periode.semaine),
        chip('Mois', _Periode.mois),
        chip('Année', _Periode.annee),
      ],
    );
  }
}
