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
  
    factory Pagamento.fromJson(Map<String, dynamic> json) {
      return Pagamento(
        id: json['id'] as int?,
        valorTotal: json['valorTotal'] is String 
            ? double.tryParse(json['valorTotal']) ?? 0.0
            : (json['valorTotal'] as num?)?.toDouble() ?? 0.0,
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