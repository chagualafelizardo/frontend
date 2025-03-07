import 'package:app/models/Reserva.dart';

class Atendimento {
  int? id;
  DateTime? dataSaida;
  DateTime? dataChegada;
  DateTime? dataDevolucao;
  String? destino;
  double? kmInicial;
  double? kmFinal;
  int? reservaId;
  final int reserveID;
  int? userId; // Adicione o campo userId
  User? user; // Campo relacionado ao usuário
  Veiculo? veiculo; // Campo relacionado ao veículo

  Atendimento({
    this.id,
    this.dataSaida,
    this.dataChegada,
    this.dataDevolucao,
    this.destino,
    this.kmInicial,
    this.kmFinal,
    this.reservaId,
    required this.reserveID,
    this.userId, // Adicione o campo userId no construtor
    this.user,
    this.veiculo,
  });

  factory Atendimento.fromJson(Map<String, dynamic> json) {
    return Atendimento(
      id: json['id'] != null ? json['id'] as int : null,
      dataSaida: json['data_saida'] != null ? DateTime.tryParse(json['data_saida']) : null,
      dataChegada: json['data_chegada'] != null ? DateTime.tryParse(json['data_chegada']) : null,
      dataDevolucao: json['data_devolucao'] != null ? DateTime.tryParse(json['data_devolucao']) : null,
      destino: json['destino'] as String?,
      kmInicial: json['km_inicial'] != null ? json['km_inicial'] as double : null,
      kmFinal: json['km_final'] != null ? json['km_final'] as double : null,
      reservaId: json['reservaId'] != null ? json['reservaId'] as int : null,
      reserveID: json['reserveID'] ?? 0,
      userId: json['userId'] != null ? json['userId'] as int : null, // Adicione o campo userId no fromJson
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      veiculo: json['veiculo'] != null ? Veiculo.fromJson(json['veiculo']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'data_saida': dataSaida?.toIso8601String(),
      'data_chegada': dataChegada?.toIso8601String(),
      'data_devolucao': dataDevolucao?.toIso8601String(),
      'destino': destino,
      'km_inicial': kmInicial,
      'km_final': kmFinal,
      'reservaId': reservaId,
      'userId': userId, // Adicione o campo userId no toJson
      'user': user?.toJson(),
      'veiculo': veiculo?.toJson(),
    };
  }

  get state => null;
  get matricula => null;
}