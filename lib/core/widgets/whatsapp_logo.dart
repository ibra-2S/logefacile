import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Logo officiel WhatsApp (glyphe simple-icons), teintable.
class WhatsAppLogo extends StatelessWidget {
  final double size;
  final Color color;

  /// Vert de marque WhatsApp
  static const vert = Color(0xFF25D366);

  const WhatsAppLogo({super.key, this.size = 20, this.color = vert});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/icons/whatsapp.svg',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}
