import 'package:app/models/VeiculoDetails.dart';
import 'package:app/models/Veiculoimg.dart';

class VeiculoAdd {
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
  final bool isAvailable;
  final String smsLockCommand;
  final String smsUnLockCommand;
  final DateTime createdAt;
  final DateTime updatedAt;

  VeiculoAdd({
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
    required this.isAvailable,
    required this.smsLockCommand,
    required this.smsUnLockCommand,
    required this.createdAt,
    required this.updatedAt,
  });

  // Método toJson
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'matricula': matricula,
      'marca': marca,
      'modelo': modelo,
      'ano': ano,
      'cor': cor,
      'num_chassi': numChassi,
      'num_lugares': numLugares,
      'num_motor': numMotor,
      'num_portas': numPortas,
      'smsLockCommand': smsLockCommand,
      'smsUnLockCommand': smsUnLockCommand,
      'tipo_combustivel': tipoCombustivel,
      'state': state,
      'image': imagemBase64,
      'rentalIncludesDriver': rentalIncludesDriver, // Adicionando no toJson
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Método fromJson
  factory VeiculoAdd.fromJson(Map<String, dynamic> json) {
    return VeiculoAdd(
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
      imagemBase64: json['image'],
      rentalIncludesDriver: json['rentalIncludesDriver'] ??
          false, 
                isAvailable: json['isAvailable'] ?? false,
      smsLockCommand: json['smsLockCommand'] ?? '',
      smsUnLockCommand: json['smsUnLockCommand'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}
