import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/user_model.dart';
import '../../../core/services/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).etatConnexion;
});

final utilisateurActuelProvider = FutureProvider<UserModel?>((ref) async {
  final user = ref.watch(authStateProvider).asData?.value;
  if (user == null) return null;
  return ref.watch(authServiceProvider).recupererUtilisateur(user.uid);
});

class AuthNotifier extends Notifier<AsyncValue<UserModel?>> {
  @override
  AsyncValue<UserModel?> build() => const AsyncValue.data(null);

  Future<void> inscrire({
    required String email,
    required String motDePasse,
    required String nomComplet,
    required UserRole role,
    String? telephone,
  }) async {
    state = const AsyncValue.loading();
    try {
      final utilisateur = await ref
          .read(authServiceProvider)
          .inscrire(
            email: email,
            motDePasse: motDePasse,
            nomComplet: nomComplet,
            role: role,
            telephone: telephone,
          );
      state = AsyncValue.data(utilisateur);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> connecter({
    required String email,
    required String motDePasse,
  }) async {
    state = const AsyncValue.loading();
    try {
      final utilisateur = await ref
          .read(authServiceProvider)
          .connecter(email: email, motDePasse: motDePasse);
      state = AsyncValue.data(utilisateur);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // connexion avec Google
  Future<void> connecterAvecGoogle({UserRole role = UserRole.locataire}) async {
    state = const AsyncValue.loading();
    try {
      final utilisateur = await ref
          .read(authServiceProvider)
          .connecterAvecGoogle(role: role);
      state = AsyncValue.data(utilisateur);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deconnecter() async {
    await ref.read(authServiceProvider).deconnecter();
    state = const AsyncValue.data(null);
  }
}

final authNotifierProvider =
    NotifierProvider<AuthNotifier, AsyncValue<UserModel?>>(
      () => AuthNotifier(),
    );
