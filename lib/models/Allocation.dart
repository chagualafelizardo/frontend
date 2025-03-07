class Allocation {
  int? id;
  DateTime startDate;
  DateTime endDate;
  String destination;
  bool paid;

  Allocation({
    this.id,
    required this.startDate,
    required this.endDate,
    required this.destination,
    this.paid = false,
  });

  // Converte um mapa JSON em uma instância de Allocation
  factory Allocation.fromJson(Map<String, dynamic> json) {
    return Allocation(
      id: json['id'],
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      destination: json['destination'],
      paid: json['paid'] ?? false,
    );
  }

  get status => null;

  get projectName => null;

  get userName => null;

  // Converte uma instância de Allocation em um mapa JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'destination': destination,
      'paid': paid,
    };
  }
}
