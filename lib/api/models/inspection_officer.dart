class InspectionOfficer {
  final int id;
  final String username;
  final String role;
  final String profilePicture;
  final DateTime createdAt;

  InspectionOfficer({
    required this.id,
    required this.username,
    required this.role,
    required this.profilePicture,
    required this.createdAt,
  });

  factory InspectionOfficer.fromJson(Map<String, dynamic> json) {
    return InspectionOfficer(
      id: json["id"],
      username: json['username'],
      role: json['role'],
      profilePicture: json["profile_picture"],
      createdAt: DateTime.parse(json["created_at"]),
    );
  }
}
