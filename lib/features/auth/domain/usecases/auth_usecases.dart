import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';

class Login {
  const Login(this._repository);
  final AuthRepository _repository;

  Future<AppUser> call({required String email, required String password}) =>
      _repository.login(email: email.trim().toLowerCase(), password: password);
}

class RestoreSession {
  const RestoreSession(this._repository);
  final AuthRepository _repository;

  Future<AppUser?> call() => _repository.restoreSession();
}

class Logout {
  const Logout(this._repository);
  final AuthRepository _repository;

  Future<void> call() => _repository.logout();
}

class RequestPasswordReset {
  const RequestPasswordReset(this._repository);
  final AuthRepository _repository;

  Future<void> call(String email) => _repository.requestPasswordReset(email.trim().toLowerCase());
}

class SetNewPassword {
  const SetNewPassword(this._repository);
  final AuthRepository _repository;

  Future<void> call({required String token, required String newPassword}) =>
      _repository.setNewPassword(token: token, newPassword: newPassword);
}

class ChangePassword {
  const ChangePassword(this._repository);
  final AuthRepository _repository;

  Future<void> call({required String currentPassword, required String newPassword}) =>
      _repository.changePassword(currentPassword: currentPassword, newPassword: newPassword);
}
