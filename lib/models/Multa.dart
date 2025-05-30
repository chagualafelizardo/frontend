class Multa {
  final int? id;
  final String description;
  final double valorpagar;
  final String? observation;
  final int? atendimentoId;
  final DateTime? dataMulta;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  Multa({
    this.id,
    required this.description,
    required this.valorpagar,
    this.observation,
    this.atendimentoId,
    this.dataMulta,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  factory Multa.fromJson(Map<String, dynamic> json) {
    return Multa(
      id: json['id'] as int?,
      description: json['description'] as String,
      valorpagar: _parseValorPagar(json['valorpagar']),
      observation: json['observation'] as String?,
      atendimentoId: json['atendimentoId'] as int?,
      dataMulta: _parseDateTime(json['dataMulta']),
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
      deletedAt: _parseDateTime(json['deleted_at']),
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    
    try {
      if (value is DateTime) return value;
      if (value is String) {
        // Tenta parsear como ISO 8601 primeiro
        try {
          return DateTime.parse(value);
        } catch (_) {
          // Tenta outros formatos se necessário
          if (value.contains('/')) {
            final parts = value.split('/');
            if (parts.length == 3) {
              return DateTime(
                int.parse(parts[2]),
                int.parse(parts[1]),
                int.parse(parts[0]),
              );
            }
          }
        }
      }
      return null;
    } catch (e) {
      print('Erro ao parsear data: $e');
      return null;
    }
  }

  static double _parseValorPagar(dynamic value) {
    if (value == null) return 0.0;

    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final cleanedValue = value
          .replaceAll(RegExp(r'[^\d.]'), '')
          .replaceAll(',', '.');
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
      'atendimentoId': atendimentoId,
      'dataMulta': _formatDateTime(dataMulta),
      'created_at': _formatDateTime(createdAt),
      'updated_at': _formatDateTime(updatedAt),
      'deleted_at': _formatDateTime(deletedAt),
    };
  }

  static String? _formatDateTime(DateTime? date) {
    return date?.toIso8601String();
  }

  Multa copyWith({
    int? id,
    String? description,
    double? valorpagar,
    String? observation,
    int? atendimentoId,
    DateTime? dataMulta, // novo campo
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return Multa(
      id: id ?? this.id,
      description: description ?? this.description,
      valorpagar: valorpagar ?? this.valorpagar,
      observation: observation ?? this.observation,
      atendimentoId: atendimentoId ?? this.atendimentoId,
      dataMulta: dataMulta ?? this.dataMulta, // novo campo
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  String toString() {
    return 'Multa(id: $id, description: $description, valorpagar: $valorpagar, '
           'observation: $observation, atendimentoId: $atendimentoId, '
           'dataMulta: $dataMulta, createdAt: $createdAt)';
  }
}
