import 'package:app/models/User.dart';

class PagamentoList {
    int? id;
    double valorTotal;
    DateTime data;
    int atendimentoId;
    int userId;
    int criterioPagamentoId;
    User? user; // Adicionamos a referência ao objeto User (opcional)

  
    PagamentoList({
      this.id,
      required this.valorTotal,
      required this.data,
      required this.atendimentoId,
      required this.userId,
      required this.criterioPagamentoId,
      this.user, // Parâmetro opcional
    });
  

    factory PagamentoList.fromJson(Map<String, dynamic> json) {
      // Função auxiliar para converter valorTotal de qualquer formato
      double parseValorTotal(dynamic value) {
        if (value == null) return 0.0;
        
        if (value is double) return value;
        if (value is int) return value.toDouble();
        
        if (value is String) {
          // Remove caracteres não numéricos e converte vírgula para ponto
          final cleanedValue = value
              .replaceAll(RegExp(r'[^\d.-]'), '')
              .replaceAll(',', '.');
          return double.tryParse(cleanedValue) ?? 0.0;
        }
        
        return 0.0; // Fallback para tipos não reconhecidos
      }

      return PagamentoList(
        id: json['id'] as int?,
        valorTotal: parseValorTotal(json['valorTotal']), // Usa a função auxiliar
        data: DateTime.parse(json['data'] as String),
        atendimentoId: json['atendimentoId'] as int,
        userId: json['userId'] as int,
        criterioPagamentoId: json['criterioPagamentoId'] as int,
        user: json['user'] != null 
          ? _parseUser(json['user'])
          : null,
      );
    }


  static User? _parseUser(dynamic userData) {
    try {
      if (userData is Map<String, dynamic>) {
        return User.fromJson(userData);
      }
      return null;
    } catch (e) {
      print('⚠️ Failed to parse user: $e');
      return null;
    }
  }
      
    // Método para converter o objeto em um JSON
    Map<String, dynamic> toJson() {
      String safeDateToJson(DateTime? date) {
        if (date == null) return DateTime.now().toUtc().toIso8601String();
        try {
          return date.toUtc().toIso8601String();
        } catch (e) {
          return DateTime.now().toUtc().toIso8601String();
        }
      }

      return {
        'id': id,
        'valorTotal': valorTotal,
        'data': safeDateToJson(data),
        'atendimentoId': atendimentoId,
        'userId': userId,
        'criterioPagamentoId': criterioPagamentoId,
        // Removido: 'user': user?.toJson()
      };
    }


    String get userName {
    if (user != null) {
      return '${user?.firstName ?? ''} ${user?.lastName ?? ''}'.trim();
    }
    return 'Usuário ID: $userId'; // Fallback caso não tenha o objeto User
  }
}