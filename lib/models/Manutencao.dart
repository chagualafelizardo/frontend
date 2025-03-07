import 'package:app/models/VehicleSupply.dart';

class Manutencao {
  int? id;
  DateTime dataEntrada;
  DateTime? dataSaida;
  String? obs;
  int veiculoID;
  int oficinaID;
  int atendimentoID;
  List<VehicleSupply> itens; // Adicione este campo

  // Construtor
  Manutencao({
    this.id,
    required this.dataEntrada,
    this.dataSaida,
    this.obs,
    required this.veiculoID,
    required this.oficinaID,
    required this.atendimentoID,
    this.itens = const [], // Inicialize como uma lista vazia
  });

  // Método para converter um JSON em um objeto Manutencao
  factory Manutencao.fromJson(Map<String, dynamic> json) {
    return Manutencao(
      id: json['id'],
      dataEntrada: DateTime.parse(json['data_entrada']),
      dataSaida: json['data_saida'] != null ? DateTime.parse(json['data_saida']) : null,
      obs: json['obs'],
      veiculoID: json['veiculoID'],
      oficinaID: json['oficinaID'],
      atendimentoID: json['atendimentoID'],
      itens: json['itens'] != null
          ? (json['itens'] as List).map((item) => VehicleSupply.fromJson(item)).toList()
          : [], // Converta os itens do JSON
    );
  }

  // Método para converter um objeto Manutencao em JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'data_entrada': dataEntrada.toIso8601String(),
      'data_saida': dataSaida?.toIso8601String(),
      'obs': obs,
      'veiculoID': veiculoID,
      'oficinaID': oficinaID,
      'atendimentoID': atendimentoID,
      'itens': itens.map((item) => item.toJson()).toList(), // Converta os itens para JSON
    };
  }
}