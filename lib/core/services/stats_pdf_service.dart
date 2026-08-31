import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/property_model.dart';
import '../models/visit_request_model.dart';

/// Génère et propose au partage/impression un rapport PDF des statistiques
/// des biens d'un propriétaire.
class StatsPdfService {
  static const _jours = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];

  static String _cleJour(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static String _dateCourte(DateTime d) =>
      '${_jours[d.weekday - 1]} ${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';

  static String _dateLongue(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  static String _milliers(num v) {
    final s = v.toStringAsFixed(0);
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(' ');
      b.write(s[i]);
    }
    return b.toString();
  }

  static Future<void> exporter({
    required String nomProprietaire,
    required List<PropertyModel> biens,
    required List<VisitRequestModel> demandes,
  }) async {
    final doc = pw.Document();

    final vuesTotales = biens.fold<int>(0, (t, b) => t + b.nombreVues);
    final favorisTotaux = biens.fold<int>(0, (t, b) => t + b.nombreFavoris);
    final acceptees =
        demandes.where((d) => d.statut == StatutDemande.acceptee).length;
    final tauxAccept =
        demandes.isEmpty
            ? 0
            : (acceptees / demandes.length * 100).round();

    // vues des 7 derniers jours (tous biens confondus)
    final jours = List.generate(
      7,
      (i) => DateTime.now().subtract(Duration(days: 6 - i)),
    );
    final serie =
        jours.map((j) {
          final cle = _cleJour(j);
          final total = biens.fold<int>(
            0,
            (t, b) => t + (b.statsVues[cle] ?? 0),
          );
          return (j, total);
        }).toList();
    final maxSerie = serie.fold<int>(1, (m, e) => e.$2 > m ? e.$2 : m);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build:
            (context) => [
              pw.Header(
                level: 0,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'LogeFacile — Rapport de performances',
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      '$nomProprietaire · généré le ${_dateLongue(DateTime.now())}',
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 12),
              pw.Text(
                'Synthèse',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _kpi('Biens publiés', '${biens.length}'),
                  _kpi('Vues totales', _milliers(vuesTotales)),
                  _kpi('Favoris', _milliers(favorisTotaux)),
                  _kpi('Demandes reçues', '${demandes.length}'),
                  _kpi("Taux d'acceptation", '$tauxAccept %'),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'Vues des 7 derniers jours',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      _cell('Jour', bold: true),
                      _cell('Vues', bold: true),
                      _cell('Répartition', bold: true),
                    ],
                  ),
                  for (final e in serie)
                    pw.TableRow(
                      children: [
                        _cell(_dateCourte(e.$1)),
                        _cell('${e.$2}'),
                        _cell('#' * ((e.$2 / maxSerie) * 20).round()),
                      ],
                    ),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'Détail par bien',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                columnWidths: const {
                  0: pw.FlexColumnWidth(3),
                  1: pw.FlexColumnWidth(1.4),
                  2: pw.FlexColumnWidth(1),
                  3: pw.FlexColumnWidth(1),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      _cell('Titre', bold: true),
                      _cell('Prix (GNF)', bold: true),
                      _cell('Vues', bold: true),
                      _cell('Favoris', bold: true),
                    ],
                  ),
                  for (final b in biens)
                    pw.TableRow(
                      children: [
                        _cell(b.titre),
                        _cell(_milliers(b.prix)),
                        _cell('${b.nombreVues}'),
                        _cell('${b.nombreFavoris}'),
                      ],
                    ),
                ],
              ),
              pw.SizedBox(height: 24),
              pw.Text(
                'Document généré automatiquement par LogeFacile.',
                style: const pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.grey600,
                ),
              ),
            ],
      ),
    );

    await Printing.sharePdf(
      bytes: await doc.save(),
      filename:
          'logefacile_stats_${_cleJour(DateTime.now())}.pdf',
    );
  }

  static pw.Widget _kpi(String label, String valeur) {
    return pw.Container(
      width: 150,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            valeur,
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            label,
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
        ],
      ),
    );
  }

  static pw.Widget _cell(String texte, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        texte,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }
}
