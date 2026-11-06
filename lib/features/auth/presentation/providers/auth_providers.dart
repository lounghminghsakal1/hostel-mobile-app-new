import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/auth_usecases.dart';

// Wiring: data source → repository → use cases.
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(AuthRemoteDataSource(ref.watch(dioProvider)), ref.watch(tokenStorageProvider)),
);

final loginProvider = Provider((ref) => Login(ref.watch(authRepositoryProvider)));
final requestPasswordResetProvider = Provider((ref) => RequestPasswordReset(ref.watch(authRepositoryProvider)));
final setNewPasswordProvider = Provider((ref) => SetNewPassword(ref.watch(authRepositoryProvider)));
final changePasswordProvider = Provider((ref) => ChangePassword(ref.watch(authRepositoryProvider)));

sealed class AuthState {
  const AuthState();
}

/// Reading the saved session at app start.
class AuthChecking extends AuthState {
  const AuthChecking();
}

class Authenticated extends AuthState {
  const Authenticated(this.user);
  final AppUser user;
}

class Unauthenticated extends AuthState {
  const Unauthenticated({this.sessionExpired = false});

  /// True when the server ended the session (refresh token expired or
  /// revoked), so the login screen can explain why the user is back there.
  final bool sessionExpired;
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(AuthController.new);

/// The signed-in user. Only read this inside the signed-in parts of the app.
final currentUserProvider = Provider<AppUser?>((ref) {
  final state = ref.watch(authControllerProvider);
  return state is Authenticated ? state.user : null;
});

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    final subscription = ref.watch(sessionEventsProvider).stream.listen((_) {
      if (state is Authenticated) state = const Unauthenticated(sessionExpired: true);
    });
    ref.onDispose(subscription.cancel);
    unawaited(Future.microtask(_restore));
    return const AuthChecking();
  }

  Future<void> _restore() async {
    final user = await RestoreSession(ref.read(authRepositoryProvider))();
    state = user == null ? const Unauthenticated() : Authenticated(user);
  }

  Future<AppUser> login({required String email, required String password}) async {
    final user = await ref.read(loginProvider)(email: email, password: password);
    state = Authenticated(user);
    return user;
  }

  Future<void> logout() async {
    await Logout(ref.read(authRepositoryProvider))();
    state = const Unauthenticated();
  }
}
