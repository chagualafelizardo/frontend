class TipoMulta {
  final int? id;
  final String description;
  final double valorpagar;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  TipoMulta({
    this.id,
    required this.description,
    required this.valorpagar,
    this.createdAt,
    this.updatedAt,
  });

  factory TipoMulta.fromJson(Map<String, dynamic> json) {
    return TipoMulta(
      id: json['id'] as int?,
      description: json['description'] as String,
      valorpagar: double.parse(json['valorpagar'].toString()), // Conversão segura
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'valorpagar': valorpagar,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  TipoMulta copyWith({
    int? id,
    String? description,
    double? valorpagar,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TipoMulta(
      id: id ?? this.id,
      description: description ?? this.description,
      valorpagar: valorpagar ?? this.valorpagar,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'TipoMulta(id: $id, description: $description, valorpagar: $valorpagar)';
  }
}