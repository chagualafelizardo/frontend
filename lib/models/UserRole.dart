class UserRole {
  final int? userId;
  final int? roleId;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserRole({
    required this.userId,
    required this.roleId,
    required this.createdAt,
    required this.updatedAt,
  });

  // Método para converter um JSON em um objeto UserRole
  factory UserRole.fromJson(Map<String, dynamic> json) {
    return UserRole(
      userId: json['userId'],
      roleId: json['roleId'],
      createdAt:
          DateTime.parse(json['createdAt']), // Converte a string para DateTime
      updatedAt:
          DateTime.parse(json['updatedAt']), // Converte a string para DateTime
    );
  }

  // Método para converter um objeto UserRole em JSON
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'roleId': roleId,
      'createdAt': createdAt.toIso8601String(), // Converte DateTime para string
      'updatedAt': updatedAt.toIso8601String(), // Converte DateTime para string
    };
  }
}
