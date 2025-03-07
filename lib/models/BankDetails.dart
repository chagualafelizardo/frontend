import 'package:flutter/foundation.dart';

enum AccountType { savings, current }

class BankDetails {
  final int? id;
  final int userId; // Adicionando userId
  final String bankName;
  final String accountNumber;
  final AccountType accountType;
  final String mpesaAccountNumber;
  final String eMolaAccountNumber;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  BankDetails({
    this.id,
    required this.userId, // userId agora é obrigatório
    required this.bankName,
    required this.accountNumber,
    required this.accountType,
    required this.mpesaAccountNumber,
    required this.eMolaAccountNumber,
    this.createdAt,
    this.updatedAt,
  });

  /// Converte um mapa JSON em um objeto `BankDetails`.
  factory BankDetails.fromJson(Map<String, dynamic> json) {
    return BankDetails(
      id: json['id'] as int?,
      userId: json['userId'] as int, // Certifique-se de que o userId é recebido
      bankName: json['bankName'] as String,
      accountNumber: json['accountNumber'] as String,
      accountType: AccountType.values.firstWhere(
        (type) => describeEnum(type) == json['accountType'],
      ),
      mpesaAccountNumber: json['mpesaAccountNumber'] as String,
      eMolaAccountNumber: json['eMolaAccountNumber'] as String,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  /// Converte um objeto `BankDetails` em um mapa JSON.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId, // Enviar userId no JSON
      'bankName': bankName,
      'accountNumber': accountNumber,
      'accountType': describeEnum(accountType),
      'mpesaAccountNumber': mpesaAccountNumber,
      'eMolaAccountNumber': eMolaAccountNumber,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
