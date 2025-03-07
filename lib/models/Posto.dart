class Posto {
  final int id;
  final String nomePosto;
  final String endereco;
  final int telefone;
  final String obs;

  Posto({
    required this.id,
    required this.nomePosto,
    required this.endereco,
    required this.telefone,
    required this.obs,
  });

  factory Posto.fromJson(Map<String, dynamic> json) {
    return Posto(
      id: json['id'],
      nomePosto: json['nome_posto'],
      endereco: json['endereco'],
      telefone: json['telefone'],
      obs: json['obs'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome_posto': nomePosto,
      'endereco': endereco,
      'telefone': telefone,
      'obs': obs,
    };
  }
}
