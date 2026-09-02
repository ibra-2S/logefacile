import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Un onglet de la barre de navigation.
class LogeNavItem {
  final IconData icone;
  final IconData iconeActive;
  final String label;
  final int badge;

  const LogeNavItem({
    required this.icone,
    required this.iconeActive,
    required this.label,
    this.badge = 0,
  });
}

/// Barre de navigation basse — style « Guinée Dorée » :
/// fond blanc, icônes outlined puis remplies à l'activation, libellés sous
/// l'icône (gris si inactif, marine si actif), et un onglet central mis en
/// avant dans un bouton rond marine surélevé.
class LogeBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<LogeNavItem> items;

  /// index de l'onglet affiché dans le bouton rond surélevé (ou `null`)
  final int? centerIndex;

  const LogeBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.centerIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 70,
            child: Row(
              children: List.generate(items.length, (i) {
                final estCentre = i == centerIndex;
                return Expanded(
                  child: estCentre
                      ? _CentreTab(
                          item: items[i],
                          actif: currentIndex == i,
                          onTap: () => onTap(i),
                        )
                      : _Tab(
                          item: items[i],
                          actif: currentIndex == i,
                          onTap: () => onTap(i),
                        ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final LogeNavItem item;
  final bool actif;
  final VoidCallback onTap;

  const _Tab({required this.item, required this.actif, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final couleur = actif ? AppColors.marine : AppColors.labelInactif;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _IconeBadge(
            icone: actif ? item.iconeActive : item.icone,
            couleur: couleur,
            badge: item.badge,
          ),
          const SizedBox(height: 4),
          Text(
            item.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: actif ? FontWeight.w700 : FontWeight.w500,
              color: couleur,
            ),
          ),
        ],
      ),
    );
  }
}

class _CentreTab extends StatelessWidget {
  final LogeNavItem item;
  final bool actif;
  final VoidCallback onTap;

  const _CentreTab({
    required this.item,
    required this.actif,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Transform.translate(
            offset: const Offset(0, -12),
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.marine,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.marine.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: _IconeBadge(
                icone: actif ? item.iconeActive : item.icone,
                couleur: Colors.white,
                badge: item.badge,
              ),
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -10),
            child: Text(
              item.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: actif ? FontWeight.w700 : FontWeight.w500,
                color: actif ? AppColors.marine : AppColors.labelInactif,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IconeBadge extends StatelessWidget {
  final IconData icone;
  final Color couleur;
  final int badge;

  const _IconeBadge({
    required this.icone,
    required this.couleur,
    required this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final icon = Icon(icone, size: 24, color: couleur);
    if (badge <= 0) return icon;
    return Badge(
      label: Text('$badge'),
      child: icon,
    );
  }
}
