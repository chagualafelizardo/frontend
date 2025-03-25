import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/VeiculoDetails.dart';

class VeiculoDetailsService {
  final String baseUrl;

  VeiculoDetailsService(this.baseUrl);

  // Buscar detalhes do veículo por ID
  Future<VeiculoDetails?> fetchVeiculoDetails(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/veiculoDetails/$id'));
    
    if (response.statusCode == 200) {
      return VeiculoDetails.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load vehicle details');
    }
  }

  // Adicionar novos detalhes do veículo
  Future<void> addVeiculoDetails(VeiculoDetails veiculoDetails) async {
    final response = await http.post(
      Uri.parse('$baseUrl/veiculoDetails'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(veiculoDetails.toJson()),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to add vehicle details');
    }
  }

  // Atualizar detalhes do veículo
  Future<void> updateVeiculoDetails(VeiculoDetails veiculoDetails) async {
    final response = await http.put(
      Uri.parse('$baseUrl/veiculoDetails/${veiculoDetails.id}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(veiculoDetails.toJson()),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update vehicle details');
    }
  }

  // Deletar detalhes do veículo por ID
  Future<void> deleteVeiculoDetails(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/veiculoDetails/$id'));
    
    if (response.statusCode != 204) {
      throw Exception('Failed to delete vehicle details');
    }
  }
}
