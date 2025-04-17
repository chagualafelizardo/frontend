class VehicleHistoryRent {
  int? id;
  DateTime? datavalor;
  double valor;
  String? obs;
  int veiculoID;

  VehicleHistoryRent({
    this.id,
    this.datavalor,
    required this.valor,
    this.obs,
    required this.veiculoID,
  });

  factory VehicleHistoryRent.fromJson(Map<String, dynamic> json) {
    return VehicleHistoryRent(
      id: json['id'],
      datavalor: json['datavalor'] != null ? DateTime.parse(json['datavalor']) : null,
      valor: _parseDouble(json['valor']),
      obs: json['obs'],
      veiculoID: _parseInt(json['veiculoID']),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.replaceAll(',', '.')) ?? 0.0;
    }
    return 0.0;
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (datavalor != null) 'datavalor': datavalor!.toIso8601String(),
      'valor': valor,
      'obs': obs,
      'veiculoID': veiculoID,
    };
  }
}