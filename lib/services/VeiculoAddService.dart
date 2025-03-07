import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:app/models/VeiculoAdd.dart';

import '../models/Reserva.dart';

class VeiculoServiceAdd {
  final String baseUrl;

  VeiculoServiceAdd(this.baseUrl);

  Future<List<VeiculoAdd>> fetchVeiculos(int page, int itemsPerPage) async {
    final response = await http.get(
      Uri.parse('$baseUrl/veiculo'),
    );

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      print("Response body: $body"); // Adicione esta linha para depuração
      List<VeiculoAdd> veiculos =
          body.map((dynamic item) => VeiculoAdd.fromJson(item)).toList();
      return veiculos;
    } else {
      throw Exception('Failed to load vehicles');
    }
  }

  Future<void> createVeiculo(VeiculoAdd veiculo) async {
    final response = await http.post(
      Uri.parse('$baseUrl/veiculo'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(veiculo.toJson()),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to create vehicle');
    }
  }

  Future<void> updateVeiculo(String id, VeiculoAdd veiculo) async {
    final response = await http.put(
      Uri.parse('$baseUrl/veiculos/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(veiculo.toJson()),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update vehicle');
    }
  }

   // Método para obter o veículo pelo número de matrícula
  Future<Veiculo?> getVeiculoByMatricula(String matricula) async {
    try {
      // Enviar solicitação GET ao backend
      final response = await http.get(
        Uri.parse('$baseUrl/veiculo/veiculo/$matricula'),
        headers: {'Content-Type': 'application/json'},
      );

      // Verificar se a resposta do servidor foi bem-sucedida
      if (response.statusCode == 200) {
        // Se o veículo for encontrado, fazer o parsing da resposta JSON
        final veiculoData = json.decode(response.body);
        return Veiculo.fromJson(veiculoData);
      } else {
        // Se não encontrar o veículo, retorna null
        print('No vehicle found with matricula: $matricula');
        return null;
      }
    } catch (error) {
      print('Error while retrieving vehicle: $error');
      return null;
    }
  }

  // Método para buscar veículos que precisam de manutenção
  Future<List<Veiculo>> fetchVeiculosParaManutencao() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/veiculo/manutencao'));

      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        return body.map((dynamic item) => Veiculo.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load vehicles for maintenance');
      }
    } catch (e) {
      print('Error fetching vehicles for maintenance: $e');
      throw Exception('Error fetching vehicles for maintenance');
    }
  }
}
