class DetalhePagamento {
  int? id;
  double valorPagamento; // Usamos double para representar DECIMAL(10, 2)
  DateTime dataPagamento;
  int pagamentoId;

  DetalhePagamento({
    this.id,
    required this.valorPagamento,
    required this.dataPagamento,
    required this.pagamentoId,
  });

  // Método para criar um objeto a partir de um JSON
  factory DetalhePagamento.fromJson(Map<String, dynamic> json) {
    return DetalhePagamento(
      id: json['id'],
      valorPagamento: double.parse(json['valorPagamento'].toString()), // Converte para double
      dataPagamento: DateTime.parse(json['dataPagamento']), // Converte para DateTime
      pagamentoId: json['pagamentoId'],
    );
  }

  // Método para converter o objeto em um JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'valorPagamento': valorPagamento,
      'dataPagamento': dataPagamento.toIso8601String(), // Converte DateTime para String
      'pagamentoId': pagamentoId,
    };
  }
}