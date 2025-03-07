class Pagamento {
    int? id;
    double valorTotal;
    DateTime data;
    int atendimentoId;
    int userId;
    int criterioPagamentoId;
  
    Pagamento({
      this.id,
      required this.valorTotal,
      required this.data,
      required this.atendimentoId,
      required this.userId,
      required this.criterioPagamentoId,
    });
  
    // factory Pagamento.fromJson(Map<String, dynamic> json) {
    //   return Pagamento(
    //     id: json['id'] as int?,
    //     valorTotal: double.parse(json['valorTotal']), // Converte String para double
    //     data: DateTime.parse(json['data'] as String), // Converte para DateTime
    //     atendimentoId: json['atendimentoId'] as int, // Converte para int
    //     userId: json['userId'] as int, // Converte para int
    //     criterioPagamentoId: json['criterioPagamentoId'] as int, // Converte para int
    //   );
    // }

    factory Pagamento.fromJson(Map<String, dynamic> json) {
      return Pagamento(
        id: json['id'] as int?,
        valorTotal: (json['valorTotal'] is int) 
            ? (json['valorTotal'] as int).toDouble() 
            : json['valorTotal'] as double, // Trata valores int ou double
        data: DateTime.parse(json['data'] as String),
        atendimentoId: json['atendimentoId'] as int,
        userId: json['userId'] as int,
        criterioPagamentoId: json['criterioPagamentoId'] as int,
      );
    }

      
    // Método para converter o objeto em um JSON
    Map<String, dynamic> toJson() {
      return {
        'id': id,
        'valorTotal': valorTotal,
        'data': data.toIso8601String(),
        'atendimentoId': atendimentoId,
        'userId': userId,
        'criterioPagamentoId': criterioPagamentoId,
      };
    }
  }