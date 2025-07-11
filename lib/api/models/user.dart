class User {
  final int id;
  final String username;
  final Roles role;
  final String? accessToken;
  final String? refreshToken;
  final String? tokenType;

  User({
    required this.id,
    required this.username,
    required this.role,
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['user']['id'],
      username: json['user']['username'],
      role: json['user']['role'] == "admin"
          ? Roles.admin
          : Roles.inspectionOfficer,
      accessToken: json['access_token'],
      refreshToken: json['refresh_token'],
      tokenType: json['token_type'],
    );
  }
}

enum Roles {
  admin,
  inspectionOfficer,
}
