import '../../domain/entities/app_user.dart';

class AppUserModel extends AppUser {
  const AppUserModel({
    required super.name,
    required super.email,
    super.avatarUrl,
  });

  factory AppUserModel.fromJson(Map<String, dynamic> json) {
    return AppUserModel(
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      avatarUrl: json['avatar_url'],
    );
  }

  factory AppUserModel.fromEntity(AppUser user) {
    return AppUserModel(
      name: user.name,
      email: user.email,
      avatarUrl: user.avatarUrl,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        'avatar_url': avatarUrl,
      };
}

class AuthSessionModel {
  const AuthSessionModel({
    required this.user,
    required this.token,
  });

  final AppUserModel user;
  final String? token;
}

