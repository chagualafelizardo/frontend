class Oficina {
  final int id;
  final String nomeOficina;
  final String endereco;
  final int telefone; // Mantendo como int
  final String obs;

  Oficina({
    required this.id,
    required this.nomeOficina,
    required this.endereco,
    required this.telefone,
    required this.obs,
  });

  factory Oficina.fromJson(Map<String, dynamic> json) {
    return Oficina(
      id: json['id'],
      nomeOficina: json['nome_oficina'],
      endereco: json['endereco'],
      telefone: json['telefone'], // Garantir que o valor seja tratado como int
      obs: json['obs'] ?? '', // Caso obs seja null
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome_oficina': nomeOficina,
      'endereco': endereco,
      'telefone': telefone, // Garantir que o valor seja tratado como int
      'obs': obs,
    };
  }
}
