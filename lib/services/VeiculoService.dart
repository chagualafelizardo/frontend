import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:app/models/Veiculo.dart';

class VeiculoService {
  final String baseUrl;

  VeiculoService(this.baseUrl);

  Future<List<Veiculo>> fetchVeiculos(int page, int itemsPerPage) async {
    final response = await http.get(
      Uri.parse('$baseUrl/veiculo'),
    );

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      print("Response body: $body"); // Adicione esta linha para depuração
      List<Veiculo> veiculos =
          body.map((dynamic item) => Veiculo.fromJson(item)).toList();
      return veiculos;
    } else {
      throw Exception('Failed to load vehicles');
    }
  }

  Future<Veiculo> getVeiculoById(int veiculoId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/veiculo/$veiculoId'),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> body = jsonDecode(response.body);
      return Veiculo.fromJson(body);
    } else {
      throw Exception('Failed to load vehicle with ID $veiculoId');
    }
  }

  Future<List<Veiculo>> getVeiculos() async {
    final response = await http.get(
      Uri.parse('$baseUrl/veiculo'),
    );

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      print("Response body: $body"); // Adicione esta linha para depuração
      List<Veiculo> veiculos =
          body.map((dynamic item) => Veiculo.fromJson(item)).toList();
      return veiculos;
    } else {
      throw Exception('Failed to load vehicles');
    }
  }

  Future<List<Veiculo>> fetchVehiclesByState(String state) async {
    final response = await http.get(Uri.parse('$baseUrl/veiculo/state/$state'));

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((json) => Veiculo.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load vehicles by state');
    }
  }

  // Atualizar o estado de um veículo
  Future<bool> updateVehicleState(int veiculoId, String newState) async {
    final url = Uri.parse('$baseUrl/veiculo/state/$veiculoId');

    print('[INFO] Iniciando atualização do estado do veículo...');
    print('[INFO] URL: $url');
    print('[INFO] Dados enviados: ${jsonEncode({'state': newState})}');

    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'state': newState}),
      );

      print('[INFO] Código de status da resposta: ${response.statusCode}');
      print('[INFO] Corpo da resposta: ${response.body}');

      if (response.statusCode == 200) {
        print('[SUCESSO] Estado do veículo atualizado com sucesso.');
        return true;
      } else {
        print('[ERRO] Falha ao atualizar estado do veículo. Resposta: ${response.body}');
        return false;
      }
    } catch (e) {
      print('[EXCEÇÃO] Ocorreu um erro ao tentar atualizar o estado do veículo: $e');
      return false;
    }
  }


// Método para apagar um veículo
  Future<bool> deleteVeiculo(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/veiculo/$id'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (response.statusCode == 200) {
      return true; // Veículo apagado com sucesso
    } else if (response.statusCode == 404) {
      throw Exception('Veículo não encontrado');
    } else {
      throw Exception('Falha ao apagar veículo. Código de status: ${response.statusCode}');
    }
  }
}
