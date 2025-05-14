import 'package:app/models/User.dart';

class PagamentoList {
  int? id;
  double valorTotal;
  DateTime data;
  int atendimentoId;
  int userId; // Mantemos apenas o ID do usuário
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
    // Função auxiliar para converter valorTotal com tratamento de erros
    double parseValorTotal(dynamic value) {
      try {
        if (value == null) return 0.0;
        if (value is double) return value;
        if (value is int) return value.toDouble();
        if (value is String) {
          final cleanedValue = value
              .replaceAll(RegExp(r'[^\d.,-]'), '')
              .replaceAll(',', '.');
          return double.tryParse(cleanedValue) ?? 0.0;
        }
        if (value is Map) {
          // Se for um Map, tentamos extrair um valor numérico
          final numericValue = value['value'] ?? value['amount'] ?? value['total'];
          return parseValorTotal(numericValue);
        }
        return 0.0;
      } catch (e) {
        print('Erro ao converter valorTotal: $e');
        return 0.0;
      }
    }

    // Função auxiliar para converter datas com tratamento de erros
    DateTime parseData(dynamic value) {
      try {
        if (value is String) {
          return DateTime.parse(value);
        }
        if (value is Map) {
          // Se for um Map, tentamos extrair uma string de data
          final dateString = value['date'] ?? value['data'] ?? value['timestamp'];
          if (dateString is String) {
            return DateTime.parse(dateString);
          }
        }
        return DateTime.now(); // Fallback
      } catch (e) {
        print('Erro ao converter data: $e');
        return DateTime.now(); // Fallback
      }
    }

    // Função auxiliar para converter IDs com tratamento de erros
    int parseInt(dynamic value) {
      try {
        if (value == null) return 0;
        if (value is int) return value;
        if (value is String) return int.tryParse(value) ?? 0;
        if (value is Map) {
          // Se for um Map, tentamos extrair um ID
          final idValue = value['id'] ?? value['ID'] ?? value['Id'];
          return parseInt(idValue);
        }
        return 0;
      } catch (e) {
        print('Erro ao converter ID: $e');
        return 0;
      }
    }

    return PagamentoList(
      id: parseInt(json['id']),
      valorTotal: parseValorTotal(json['valorTotal']),
      data: parseData(json['data']),
      atendimentoId: parseInt(json['atendimentoId']),
      userId: parseInt(json['userId']),
      criterioPagamentoId: parseInt(json['criterioPagamentoId']),
      user: json['user'] != null && json['user'] is Map<String, dynamic>
          ? User.fromJson(json['user'] as Map<String, dynamic>)
          : null,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'valorTotal': valorTotal,
      'data': data.toIso8601String(),
      'atendimentoId': atendimentoId,
      'userId': userId,
      'criterioPagamentoId': criterioPagamentoId,
      'user': user?.toJson(), // Inclui User no JSON se existir
    };
  }

  // Método para obter o nome do usuário (se o objeto User estiver disponível)
  String get userName {
    if (user != null) {
      return '${user?.firstName ?? ''} ${user?.lastName ?? ''}'.trim();
    }
    return 'Usuário ID: $userId'; // Fallback caso não tenha o objeto User
  }
}