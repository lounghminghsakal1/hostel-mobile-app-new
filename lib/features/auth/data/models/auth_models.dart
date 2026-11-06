import '../../../../core/models/account_status.dart';
import '../../../../core/utils/json.dart';
import '../../domain/entities/app_user.dart';

class AppUserModel extends AppUser {
  const AppUserModel({required super.id, required super.email, required super.status, required super.role});

  /// Login returns `role` as a string; the splash endpoints return
  /// `role: {roleName}`. Both are accepted.
  factory AppUserModel.fromJson(Map<String, dynamic> json) {
    final rawRole = json['role'];
    final roleName = rawRole is Map ? rawRole['roleName'] : rawRole;
    final role = UserRole.fromApi(roleName);
    if (role == null) throw FormatException('Unknown role: $roleName');
    return AppUserModel(
      id: JsonRead.integer(json['id']),
      email: JsonRead.string(json['email']),
      status: AccountStatus.fromApi(json['status']),
      role: role,
    );
  }

  Map<String, Object> toJson() => {'id': id, 'email': email, 'status': status.apiValue, 'role': role.apiValue};
}

/// `POST /auth/login` → `data: {user, tokens: {accessToken, refreshToken}}`.
class LoginResponseModel {
  const LoginResponseModel({required this.user, required this.accessToken, required this.refreshToken});

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    final tokens = json['tokens'] as Map<String, dynamic>;
    return LoginResponseModel(
      user: AppUserModel.fromJson(json['user'] as Map<String, dynamic>),
      accessToken: tokens['accessToken'] as String,
      refreshToken: tokens['refreshToken'] as String,
    );
  }

  final AppUserModel user;
  final String accessToken;
  final String refreshToken;
}
