class EnviaManutencao {
  int? id; // ID da manutenção (pode ser nulo se ainda não foi persistido no banco)
  final String? obs;
  final int veiculoID;
  final int? oficinaID;
  final int atendimentoID;

  EnviaManutencao({
    this.id,
    this.obs,
    required this.veiculoID,
    this.oficinaID,
    required this.atendimentoID,
  });

  // Método para converter o objeto em um Map (JSON)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'obs': obs,
      'veiculoID': veiculoID,
      'oficinaID': oficinaID,
      'atendimentoID': atendimentoID,
    };
  }

    factory EnviaManutencao.fromJson(Map<String, dynamic> json) {
    return EnviaManutencao(
      id: json['id'],
      obs: json['obs'],
      veiculoID: json['veiculoID'],
      oficinaID: json['oficinaID'],
      atendimentoID: json['atendimentoID'],
    );
  }
}