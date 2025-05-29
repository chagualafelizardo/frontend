class Multa {
  final int? id;
  final String description;
  final double valorpagar;
  final String? observation;
  final int? atendimentoId; // NOVO CAMPO
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  Multa({
    this.id,
    required this.description,
    required this.valorpagar,
    this.observation,
    this.atendimentoId, // novo campo
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  factory Multa.fromJson(Map<String, dynamic> json) {
    return Multa(
      id: json['id'] as int?,
      description: json['description'] as String,
      // Safe conversion for monetary value
      valorpagar: _parseValorPagar(json['valorpagar']),
      observation: json['observation'] as String?,
      atendimentoId: json['atendimentoId'] as int?, // novo campo
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'])
          : null,
    );
  }

  // Helper method for safe valorpagar conversion
  static double _parseValorPagar(dynamic value) {
    if (value == null) return 0.0;
    
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      // Handle string with possible currency symbols or commas
      final cleanedValue = value
          .replaceAll(RegExp(r'[^\d.]'), '') // Remove non-numeric except dots
          .replaceAll(',', '.'); // Handle comma as decimal separator
      return double.tryParse(cleanedValue) ?? 0.0;
    }
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'valorpagar': valorpagar,
      'observation': observation,
      'atendimentoId': atendimentoId, // novo campo
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }

  Multa copyWith({
    int? id,
    String? description,
    double? valorpagar,
    String? observation,
    int? atendimentoId, // novo campo
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return Multa(
      id: id ?? this.id,
      description: description ?? this.description,
      valorpagar: valorpagar ?? this.valorpagar,
      observation: observation ?? this.observation,
      atendimentoId: atendimentoId ?? this.atendimentoId, // novo campo
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  String toString() {
    return 'Multa(id: $id, description: $description, valorpagar: $valorpagar, '
           'observation: $observation, atendimentoId: $atendimentoId, createdAt: $createdAt)';
  }
}