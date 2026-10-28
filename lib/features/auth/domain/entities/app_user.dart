class AppUser {
  const AppUser({
    required this.name,
    required this.email,
    this.avatarUrl,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      avatarUrl: json['avatar_url'],
    );
  }

  final String name;
  final String email;
  final String? avatarUrl;

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        'avatar_url': avatarUrl,
      };

  AppUser copyWith({
    String? name,
    String? email,
    String? avatarUrl,
  }) {
    return AppUser(
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}
