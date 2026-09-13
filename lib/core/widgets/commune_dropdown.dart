import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/communes.dart';

/// Sélecteur de commune (menu déroulant), utilisé à la fois lors de la
/// publication et de la modification d'un bien.
class CommuneDropdown extends StatelessWidget {
  final String? valeur;
  final ValueChanged<String?> onChanged;
  final Color fillColor;
  final BoxBorder? border;
  final double labelFontSize;
  final double contentPaddingHorizontal;

  const CommuneDropdown({
    super.key,
    required this.valeur,
    required this.onChanged,
    this.fillColor = Colors.white,
    this.border,
    this.labelFontSize = 13,
    this.contentPaddingHorizontal = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Commune *',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: labelFontSize,
            color: AppColors.texte,
          ),
        ),
        SizedBox(height: labelFontSize > 12 ? 6 : 4),
        Container(
          decoration: BoxDecoration(
            color: fillColor,
            borderRadius: BorderRadius.circular(10),
            border: border,
          ),
          padding: EdgeInsets.symmetric(horizontal: contentPaddingHorizontal),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: valeur,
              isExpanded: true,
              hint: const Text(
                'Choisissez une commune',
                style: TextStyle(color: AppColors.texteLeger, fontSize: 13),
              ),
              items: communesConakry
                  .map(
                    (c) => DropdownMenuItem<String>(value: c, child: Text(c)),
                  )
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
