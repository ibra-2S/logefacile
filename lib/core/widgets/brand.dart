import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Marque LogeFacile — repère de lieu contenant une maison épurée.
/// Dessin vectoriel : net à toutes les tailles et adaptable au thème,
/// contrairement à l'ancien PNG.
class LogeFacileMark extends StatelessWidget {
  final double size;

  /// couleur du repère (par défaut le bleu de marque)
  final Color? pinColor;

  /// couleur de la maison ; si `null`, la maison est « découpée » dans le
  /// repère et laisse voir l'arrière-plan (utile sur fond coloré)
  final Color? houseColor;

  const LogeFacileMark({
    super.key,
    this.size = 32,
    this.pinColor,
    this.houseColor,
  });

  /// Version monochrome : tout le pictogramme dans une seule teinte,
  /// la maison est ajourée.
  const LogeFacileMark.mono({
    super.key,
    this.size = 32,
    required Color color,
  })  : pinColor = color,
        houseColor = null;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _MarkPainter(
          pinColor: pinColor ?? AppColors.bleuFonce,
          houseColor: houseColor,
        ),
      ),
    );
  }
}

class _MarkPainter extends CustomPainter {
  final Color pinColor;
  final Color? houseColor;

  _MarkPainter({required this.pinColor, this.houseColor});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    // le repère occupe toute la largeur ; on le centre verticalement
    final s = math.min(w, h / 1.28);
    final dx = (w - s) / 2;
    final dy = (h - s * 1.28) / 2;
    canvas.translate(dx, dy);

    final pin = _pinPath(s);
    final house = _housePath(s);
    final door = _doorPath(s);

    if (houseColor == null) {
      // maison + porte ajourées dans le repère (règle pair/impair)
      final combine = Path()
        ..fillType = PathFillType.evenOdd
        ..addPath(pin, Offset.zero)
        ..addPath(house, Offset.zero)
        ..addPath(door, Offset.zero);
      canvas.drawPath(combine, Paint()..color = pinColor);
    } else {
      canvas.drawPath(pin, Paint()..color = pinColor);
      canvas.drawPath(house, Paint()..color = houseColor!);
      canvas.drawPath(door, Paint()..color = pinColor);
    }
  }

  Path _pinPath(double s) {
    final r = s / 2;
    final center = Offset(r, r);
    final tip = Offset(r, s * 1.28);
    // points de tangence entre la pointe et le cercle
    final d = tip.dy - center.dy;
    final angle = math.acos(r / d); // angle au centre
    final pLeft = Offset(
      center.dx - r * math.sin(angle),
      center.dy + r * math.cos(angle),
    );
    final startAngle = math.atan2(pLeft.dy - center.dy, pLeft.dx - center.dx);
    // du point gauche, on tourne par le haut jusqu'au point droit (symétrique)
    final sweep = 3 * math.pi - 2 * startAngle;

    return Path()
      ..moveTo(pLeft.dx, pLeft.dy)
      ..arcTo(
        Rect.fromCircle(center: center, radius: r),
        startAngle,
        sweep,
        false,
      )
      ..lineTo(tip.dx, tip.dy)
      ..close();
  }

  // maison épurée logée dans le disque du repère
  Path _housePath(double s) {
    final cx = s / 2;
    final hw = s * 0.22; // demi-largeur du corps
    final bodyTop = s * 0.52; // ligne des gouttières
    final bodyBottom = s * 0.74;
    final eave = s * 0.035; // léger débord de toit
    final apex = Offset(cx, s * 0.30);

    return Path()
      ..moveTo(cx - hw - eave, bodyTop)
      ..lineTo(apex.dx, apex.dy)
      ..lineTo(cx + hw + eave, bodyTop)
      ..lineTo(cx + hw, bodyTop)
      ..lineTo(cx + hw, bodyBottom)
      ..lineTo(cx - hw, bodyBottom)
      ..lineTo(cx - hw, bodyTop)
      ..close();
  }

  Path _doorPath(double s) {
    final cx = s / 2;
    final dw = s * 0.062;
    final top = s * 0.60;
    final bottom = s * 0.74;
    return Path()
      ..addRRect(
        RRect.fromLTRBAndCorners(
          cx - dw,
          top,
          cx + dw,
          bottom,
          topLeft: Radius.circular(s * 0.025),
          topRight: Radius.circular(s * 0.025),
        ),
      );
  }

  @override
  bool shouldRepaint(_MarkPainter old) =>
      old.pinColor != pinColor || old.houseColor != houseColor;
}

/// Logo complet : pictogramme + mot « LogeFacile » (bleu + vert de marque).
class LogeFacileWordmark extends StatelessWidget {
  final double height;

  /// si fourni, tout le logo est rendu dans cette seule couleur
  /// (ex. blanc sur un fond coloré)
  final Color? monoColor;

  const LogeFacileWordmark({super.key, this.height = 40, this.monoColor});

  @override
  Widget build(BuildContext context) {
    final mono = monoColor;
    final fontSize = height * 0.62;

    TextStyle span(Color c) => TextStyle(
          color: c,
          fontWeight: FontWeight.w700,
          fontSize: fontSize,
          letterSpacing: -0.5,
        );

    // FittedBox : jamais de débordement dans un titre d'AppBar étroit
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          mono != null
              ? LogeFacileMark.mono(size: height, color: mono)
              : LogeFacileMark(size: height),
          SizedBox(width: height * 0.28),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: 'Loge', style: span(mono ?? AppColors.bleuFonce)),
                TextSpan(
                  text: 'Facile',
                  style: span(mono ?? AppColors.vertProprietaire),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
