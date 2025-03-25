import 'dart:convert';
import 'package:app/models/VeiculoDetails.dart';
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

 // Método para atualizar um veículo
  Future<void> updateVeiculo(VeiculoAdd veiculo) async {
    final url = Uri.parse('$baseUrl/veiculos/${veiculo.id}');
    final response = await http.put(
      url,
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

  Future<void> addVeiculoDetail(VeiculoDetails detail) async {
    final response = await http.post(
      Uri.parse('$baseUrl/veiculodetails'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(detail.toJson()),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to add vehicle detail');
    }
  }

  Future<List<VeiculoDetails>> fetchDetailsByVehicleId(int veiculoId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/veiculo/$veiculoId/details'),
    );

    if (response.statusCode == 200) {
      // Decodifica o JSON retornado
      final Map<String, dynamic> data = jsonDecode(response.body);

      // Extrai a lista de detalhes do objeto JSON
      final List<dynamic> detailsJson = data['details'];

      // Converte a lista de JSON em uma lista de VeiculoDetails
      return detailsJson.map((detail) => VeiculoDetails.fromJson(detail)).toList();
    } else {
      throw Exception('Failed to load vehicle details');
    }
  }
}
