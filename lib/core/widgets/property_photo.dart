import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Photo de bien pour les cartes de liste : affiche un carrousel défilable
/// quand il y a plusieurs photos, sinon la photo unique, ou un placeholder
/// marine discret avec une icône « maison » si le bien n'a aucune photo.
class PropertyPhoto extends StatefulWidget {
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
  State<PropertyPhoto> createState() => _PropertyPhotoState();
}

class _PropertyPhotoState extends State<PropertyPhoto> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _placeholder() => Container(
    height: widget.height,
    width: widget.width ?? double.infinity,
    decoration: BoxDecoration(
      color: AppColors.marine.withValues(alpha: 0.12),
      borderRadius: widget.borderRadius,
    ),
    child: Center(
      child: Icon(
        Icons.home_work_outlined,
        size: widget.height * 0.32,
        color: AppColors.marine.withValues(alpha: 0.35),
      ),
    ),
  );

  Widget _image(String url) {
    final w = widget.width ?? double.infinity;
    return CachedNetworkImage(
      imageUrl: url,
      height: widget.height,
      width: w,
      fit: BoxFit.cover,
      placeholder: (_, __) => Container(
        height: widget.height,
        width: w,
        color: AppColors.marine.withValues(alpha: 0.08),
      ),
      errorWidget: (_, __, ___) => Container(
        height: widget.height,
        width: w,
        decoration: BoxDecoration(color: AppColors.marine.withValues(alpha: 0.12)),
        child: Center(
          child: Icon(
            Icons.home_work_outlined,
            size: widget.height * 0.32,
            color: AppColors.marine.withValues(alpha: 0.35),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final photos = widget.photos;
    final w = widget.width ?? double.infinity;

    if (photos.isEmpty) return _placeholder();

    if (photos.length == 1) {
      return ClipRRect(
        borderRadius: widget.borderRadius.resolve(Directionality.of(context)),
        child: _image(photos.first),
      );
    }

    return ClipRRect(
      borderRadius: widget.borderRadius.resolve(Directionality.of(context)),
      child: SizedBox(
        height: widget.height,
        width: w,
        child: Stack(
          children: [
            PageView.builder(
              controller: _controller,
              itemCount: photos.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, i) => _image(photos[i]),
            ),
            Positioned(
              bottom: 8,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  photos.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    width: _index == i ? 14 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _index == i ? Colors.white : Colors.white54,
                      borderRadius: BorderRadius.circular(3),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 2),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
