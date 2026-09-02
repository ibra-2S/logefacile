import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Photo de bien pour les cartes de liste : affiche la première image si elle
/// existe, sinon un placeholder marine discret avec une icône « maison ».
class PropertyPhoto extends StatelessWidget {
  final List<String> photos;
  final double height;
  final double? width;
  final BorderRadiusGeometry borderRadius;

  const PropertyPhoto({
    super.key,
    required this.photos,
    this.height = 120,
    this.width,
    this.borderRadius = const BorderRadius.vertical(top: Radius.circular(16)),
  });

  @override
  Widget build(BuildContext context) {
    final w = width ?? double.infinity;

    if (photos.isEmpty) {
      return Container(
        height: height,
        width: w,
        decoration: BoxDecoration(
          color: AppColors.marine.withValues(alpha: 0.12),
          borderRadius: borderRadius,
        ),
        child: Center(
          child: Icon(
            Icons.home_work_outlined,
            size: height * 0.32,
            color: AppColors.marine.withValues(alpha: 0.35),
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: borderRadius.resolve(Directionality.of(context)),
      child: CachedNetworkImage(
        imageUrl: photos.first,
        height: height,
        width: w,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(
          height: height,
          width: w,
          color: AppColors.marine.withValues(alpha: 0.08),
        ),
        errorWidget: (_, __, ___) => Container(
          height: height,
          width: w,
          decoration: BoxDecoration(
            color: AppColors.marine.withValues(alpha: 0.12),
          ),
          child: Center(
            child: Icon(
              Icons.home_work_outlined,
              size: height * 0.32,
              color: AppColors.marine.withValues(alpha: 0.35),
            ),
          ),
        ),
      ),
    );
  }
}
