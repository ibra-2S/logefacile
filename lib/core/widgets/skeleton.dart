import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Effet "shimmer" (dégradé qui balaie) sans dépendance externe.
class Shimmer extends StatefulWidget {
  final Widget child;
  const Shimmer({super.key, required this.child});

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _controleur = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _controleur.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controleur,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: const [
                Color(0xFFE7ECF1),
                Color(0xFFF5F8FB),
                Color(0xFFE7ECF1),
              ],
              stops: const [0.35, 0.5, 0.65],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              transform: _GlissementGradient(_controleur.value),
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _GlissementGradient extends GradientTransform {
  final double pourcentage;
  const _GlissementGradient(this.pourcentage);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(
      bounds.width * (pourcentage * 3 - 1.5),
      0,
      0,
    );
  }
}

/// Bloc opaque servant de base au shimmer.
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;
  final Color color;
  const SkeletonBox({
    super.key,
    this.width,
    this.height = 14,
    this.radius = 8,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Squelette plein écran (splash, chargement du profil après connexion).
class ScreenSkeleton extends StatelessWidget {
  const ScreenSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fond,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
              20,
              MediaQuery.of(context).padding.top + 20,
              20,
              22,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.bleuFonce, AppColors.tealLocataire],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Shimmer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: 150, height: 16, color: Colors.white38),
                  SizedBox(height: 8),
                  SkeletonBox(width: 210, height: 12, color: Colors.white24),
                  SizedBox(height: 18),
                  SkeletonBox(
                    height: 46,
                    radius: 12,
                    width: double.infinity,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
          const Expanded(child: PropertyListSkeleton()),
        ],
      ),
    );
  }
}

/// Liste de fausses cartes d'annonce (onglet Recherche).
class PropertyListSkeleton extends StatelessWidget {
  final int nombre;
  const PropertyListSkeleton({super.key, this.nombre = 4});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: nombre,
        itemBuilder:
            (context, index) => Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  SkeletonBox(
                    height: 160,
                    radius: 16,
                    width: double.infinity,
                  ),
                  Padding(
                    padding: EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonBox(width: 200, height: 15),
                        SizedBox(height: 10),
                        SkeletonBox(width: 140, height: 12),
                        SizedBox(height: 14),
                        SkeletonBox(width: 110, height: 14),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      ),
    );
  }
}

/// Liste de fausses lignes (favoris, demandes, messages).
class ListTileSkeleton extends StatelessWidget {
  final int nombre;
  const ListTileSkeleton({super.key, this.nombre = 6});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: nombre,
        itemBuilder:
            (context, index) => Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: const [
                  SkeletonBox(width: 56, height: 56, radius: 12),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonBox(width: 160, height: 14),
                        SizedBox(height: 8),
                        SkeletonBox(width: 100, height: 12),
                        SizedBox(height: 8),
                        SkeletonBox(width: 130, height: 12),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      ),
    );
  }
}
