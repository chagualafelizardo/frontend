import 'package:app/models/VeiculoDetails.dart';
import 'package:app/models/Veiculoimg.dart';

class Veiculo {
  final int id;
  final String matricula;
  final String marca;
  final String modelo;
  final int ano;
  final String cor;
  final String numChassi;
  final int numLugares;
  final String numMotor;
  final int numPortas;
  final String tipoCombustivel;
  final String state;
  final String imagemBase64;
  final bool rentalIncludesDriver;
  final List<VeiculoImg> imagensAdicionais;
  final List<VeiculoDetails> details; // Adicionando a lista de detalhes
  final DateTime createdAt;
  final DateTime updatedAt;

  Veiculo({
    required this.id,
    required this.matricula,
    required this.marca,
    required this.modelo,
    required this.ano,
    required this.cor,
    required this.numChassi,
    required this.numLugares,
    required this.numMotor,
    required this.numPortas,
    required this.tipoCombustivel,
    required this.state,
    required this.imagemBase64,
    required this.rentalIncludesDriver,
    required this.imagensAdicionais,
    required this.details, // Incluindo os detalhes na inicialização
    required this.createdAt,
    required this.updatedAt,
  });

  factory Veiculo.fromJson(Map<String, dynamic> json) {
    return Veiculo(
      id: json['id'],
      matricula: json['matricula'],
      marca: json['marca'],
      modelo: json['modelo'],
      ano: json['ano'],
      cor: json['cor'],
      numChassi: json['num_chassi'],
      numLugares: json['num_lugares'],
      numMotor: json['num_motor'],
      numPortas: json['num_portas'],
      tipoCombustivel: json['tipo_combustivel'],
      state: json['state'],
      imagemBase64: json['imagemBase64'] ?? '',
      rentalIncludesDriver: json['rentalIncludesDriver'] ?? false,
      imagensAdicionais: (json['imagensAdicionais'] as List<dynamic>?)
              ?.map((img) => VeiculoImg.fromJson(img))
              .toList() ??
          [],
      details: (json['details'] as List<dynamic>?)
              ?.map((detail) => VeiculoDetails.fromJson(detail))
              .toList() ??
          [],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}
