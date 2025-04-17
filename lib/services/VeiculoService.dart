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
