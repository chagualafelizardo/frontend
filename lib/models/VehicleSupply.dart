class VehicleSupply {
  final int? id;
  final String name;
  final String? description;
  final int stock;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  bool selected; // Adicione este campo


  VehicleSupply({
    this.id,
    required this.name,
    this.description,
    required this.stock,
    this.createdAt,
    this.updatedAt,
    this.selected = false
  });

  /// Converte um JSON em uma instância de `VehicleSupply`
  factory VehicleSupply.fromJson(Map<String, dynamic> json) {
    return VehicleSupply(
      id: json['id'] as int?,
      name: json['name'] as String,
      description: json['description'] as String?,
      stock: json['stock'] as int,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
      selected: json['selected'] ?? false, // Inicialize como false se não estiver presente
    );
  }

  get obs => null;

  /// Converte uma instância de `VehicleSupply` em JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'stock': stock,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'selected': selected, // Inclua o campo selected
    };
  }
}
