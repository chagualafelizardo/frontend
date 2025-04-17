class Role {
  final int id;
  final String name;
  bool? selected; // Campo para armazenar o estado selecionado
  final DateTime createdAt;
  final DateTime updatedAt;

  Role({
    required this.id,
    required this.name,
    this.selected = false, // Definindo como falso por padrão
    required this.createdAt,
    required this.updatedAt,
  });

  factory Role.fromJson(Map<String, dynamic> json) {
    return Role(
      id: json['id'],
      name: json['name'],
      selected: json['selected'] ?? false,
      createdAt: DateTime.parse(json['createdAt']), // Converte a string para DateTime
      updatedAt: DateTime.parse(json['updatedAt']), // Converte a string para DateTime
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'selected': selected,
      'createdAt': createdAt.toIso8601String(), // Converte DateTime para string
      'updatedAt': updatedAt.toIso8601String(), // Converte DateTime para string
    };
  }
}