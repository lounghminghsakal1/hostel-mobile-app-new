import '../entities/app_user.dart';

abstract interface class AuthRepository {
  /// Signs in and stores the access and refresh tokens.
  Future<AppUser> login({required String email, required String password});

  /// The user saved from the last sign-in, or null if there is no session.
  Future<AppUser?> restoreSession();

  /// Revokes the session on the server (best effort) and clears local tokens.
  Future<void> logout();

  /// Emails a link that opens the set-new-password screen.
  Future<void> requestPasswordReset(String email);

  /// Completes first-time activation or a reset, using the emailed token.
  Future<void> setNewPassword({required String token, required String newPassword});

  Future<void> changePassword({required String currentPassword, required String newPassword});
}
