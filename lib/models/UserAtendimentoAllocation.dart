class UserAtendimentoAllocation {
  final int? id;
  final int userId;
  final int atendimentoId;
  final int allocationId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserAtendimentoAllocation({
    this.id,
    required this.userId,
    required this.atendimentoId,
    required this.allocationId,
    this.createdAt,
    this.updatedAt,
  });

  // Método para converter JSON em um objeto UserAtendimentoAllocation
  factory UserAtendimentoAllocation.fromJson(Map<String, dynamic> json) {
      return UserAtendimentoAllocation(
        id: json['id'],
        userId: json['userId'],
        atendimentoId: json['atendimentoId'],
        allocationId: json['allocationId'],
        createdAt: json['createdAt'] != null 
            ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
            : null,
        updatedAt: json['updatedAt'] != null 
            ? DateTime.tryParse(json['updatedAt']) ?? DateTime.now()
            : null,
      );
    }

  // Método para converter um objeto UserAtendimentoAllocation em JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'atendimentoId': atendimentoId,
      'allocationId': allocationId,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}

