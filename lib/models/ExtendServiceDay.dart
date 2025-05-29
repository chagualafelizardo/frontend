class ExtendServiceDay {
  final int? id;
  final DateTime date;
  final String notes;
  final int atendimentoId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ExtendServiceDay({
    this.id,
    required this.date,
    required this.notes,
    required this.atendimentoId,
    this.createdAt,
    this.updatedAt,
  });

  factory ExtendServiceDay.fromJson(Map<String, dynamic> json) {
    return ExtendServiceDay(
      id: json['id'] as int?,
      date: DateTime.parse(json['date'] as String),
      notes: json['notes'] as String,
      atendimentoId: json['atendimentoId'] as int,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'notes': notes,
      'atendimentoId': atendimentoId,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  ExtendServiceDay copyWith({
    int? id,
    DateTime? date,
    String? notes,
    int? atendimentoId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ExtendServiceDay(
      id: id ?? this.id,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      atendimentoId: atendimentoId ?? this.atendimentoId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'ExtendServiceDay(id: $id, date: $date, notes: $notes, '
           'atendimentoId: $atendimentoId)';
  }
}