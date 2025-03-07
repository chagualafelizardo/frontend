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
}
