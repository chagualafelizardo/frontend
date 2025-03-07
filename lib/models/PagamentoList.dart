class PagamentoList {
    int? id;
    double valorTotal;
    DateTime data;
    int atendimentoId;
    int userId;
    int criterioPagamentoId;
  
    PagamentoList({
      this.id,
      required this.valorTotal,
      required this.data,
      required this.atendimentoId,
      required this.userId,
      required this.criterioPagamentoId,
    });
  
    factory PagamentoList.fromJson(Map<String, dynamic> json) {
      return PagamentoList(
        id: json['id'] as int?,
        valorTotal: double.parse(json['valorTotal']), // Converte String para double
        data: DateTime.parse(json['data'] as String), // Converte para DateTime
        atendimentoId: json['atendimentoId'] as int, // Converte para int
        userId: json['userId'] as int, // Converte para int
        criterioPagamentoId: json['criterioPagamentoId'] as int, // Converte para int
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