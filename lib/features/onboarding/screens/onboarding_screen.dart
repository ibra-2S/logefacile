import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/services/prefs_service.dart';

class _Slide {
  final IconData icone;
  final Color couleur;
  final String titre;
  final String texte;
  const _Slide(this.icone, this.couleur, this.titre, this.texte);
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controleur = PageController();
  int _page = 0;

  static const _slides = <_Slide>[
    _Slide(
      Icons.search_outlined,
      AppColors.tealLocataire,
      'Trouvez votre logement',
      'Des centaines d\'annonces à Conakry et ses communes, filtrées selon '
          'votre budget et vos besoins.',
    ),
    _Slide(
      Icons.event_available_outlined,
      AppColors.bleuFonce,
      'Visitez en toute confiance',
      'Demandez une visite en un tap et suivez l\'état de vos rendez-vous '
          'directement dans l\'application.',
    ),
    _Slide(
      Icons.forum_outlined,
      AppColors.bleuMoyen,
      'Échangez directement',
      'Discutez avec les propriétaires et les agents, sans intermédiaire et '
          'sans frais cachés.',
    ),
    _Slide(
      Icons.analytics_outlined,
      AppColors.vertProprietaire,
      'Propriétaire ? Publiez gratuitement',
      'Mettez vos biens en ligne et suivez leurs performances : vues, '
          'favoris, demandes de visite.',
    ),
  ];

  @override
  void dispose() {
    _controleur.dispose();
    super.dispose();
  }

  Future<void> _terminer() async {
    await PrefsService.marquerOnboardingVu();
    if (mounted) context.go(AppRoutes.connexion);
  }

  @override
  Widget build(BuildContext context) {
    final dernier = _page == _slides.length - 1;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: dernier ? null : _terminer,
                child: Text(
                  dernier ? '' : 'Passer',
                  style: const TextStyle(color: AppColors.texteLeger),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controleur,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, index) {
                  final s = _slides[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                s.couleur.withValues(alpha: 0.18),
                                s.couleur.withValues(alpha: 0.03),
                              ],
                            ),
                          ),
                          child: Icon(s.icone, size: 76, color: s.couleur),
                        ),
                        const SizedBox(height: 40),
                        Text(
                          s.titre,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.texte,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          s.texte,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.6,
                            color: AppColors.textSecondaire,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _slides.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _page == i ? 22 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color:
                        _page == i
                            ? AppColors.bleuFonce
                            : AppColors.grisClair,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(28),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    if (dernier) {
                      _terminer();
                    } else {
                      _controleur.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.bleuFonce,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    dernier ? 'Commencer' : 'Suivant',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
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
