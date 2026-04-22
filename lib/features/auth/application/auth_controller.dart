import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/router.dart';
import '../../../core/auth/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.watch(firebaseAuthProvider));
});

final authControllerProvider = AsyncNotifierProvider<AuthController, void>(
  AuthController.new,
);

class AuthController extends AsyncNotifier<void> {
  AuthService get _service => ref.read(authServiceProvider);

  @override
  Future<void> build() async {
    return;
  }

  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();

    try {
      await _service.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      state = const AsyncData(null);
      return null;
    } on FirebaseAuthException catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return _messageFor(error.code);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return 'No se pudo iniciar sesión. Intenta nuevamente.';
    }
  }

  Future<void> signOut() => _service.signOut();

  String _messageFor(String code) {
    switch (code) {
      case 'invalid-email':
        return 'El correo no tiene un formato válido.';
      case 'user-disabled':
        return 'El usuario está deshabilitado.';
      case 'user-not-found':
      case 'wrong-password':
        return 'Correo o contraseña incorrectos.';
      case 'too-many-requests':
        return 'Demasiados intentos. Intenta más tarde.';
      default:
        return 'No se pudo iniciar sesión. Intenta nuevamente.';
    }
  }
}
