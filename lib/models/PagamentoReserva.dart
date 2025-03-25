class PagamentoReserva {
  int? id;
  double valorTotal;
  DateTime data;
  String? obs;
  int userId;
  int reservaId;

  PagamentoReserva({
    this.id,
    required this.valorTotal,
    required this.data,
    this.obs,
    required this.userId,
    required this.reservaId,
  });

  factory PagamentoReserva.fromJson(Map<String, dynamic> json) {
    return PagamentoReserva(
      id: json['id'],
      valorTotal: _parseDouble(json['valorTotal']),
      data: DateTime.parse(json['data']),
      obs: json['obs'],
      userId: json['userId'],
      reservaId: json['reservaId'],
    );
  }

  static double _parseDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.parse(value.replaceAll(',', '.'));
    throw Exception('Cannot parse $value to double');
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'valorTotal': valorTotal,
      'data': data.toIso8601String(),
      'obs': obs,
      'userId': userId,
      'reservaId': reservaId,
    };
  }
}