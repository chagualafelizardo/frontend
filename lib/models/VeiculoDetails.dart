class VeiculoDetails {
  int? id;
  String description;
  DateTime startDate;
  DateTime endDate;
  String? obs;
  int veiculoId;

  VeiculoDetails({
    this.id,
    required this.description,
    required this.startDate,
    required this.endDate,
    this.obs,
    required this.veiculoId,
  });

  // Converter de JSON para um objeto VeiculoDetails
  factory VeiculoDetails.fromJson(Map<String, dynamic> json) {
    return VeiculoDetails(
      id: json['id'],
      description: json['description'],
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      obs: json['obs'],
      veiculoId: json['veiculoId'],
    );
  }

  // Converter de VeiculoDetails para JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'obs': obs,
      'veiculoId': veiculoId,
    };
  }
}
