class UserModel {
  final int id;
  final String fullName;
  final String username;
  final bool isActive;

  UserModel({
    required this.id,
    required this.fullName,
    required this.username,
    required this.isActive,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      fullName: json['full_name'],
      username: json['username'],
      isActive: json['is_active'] ?? true,
    );
  }
}
