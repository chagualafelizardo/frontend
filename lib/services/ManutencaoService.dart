import 'dart:convert';
import 'package:app/models/Manutencao.dart';
import 'package:http/http.dart' as http;

class ManutencaoService {
  final String baseUrl;

  // Construtor que recebe a URL base do backend
  ManutencaoService(this.baseUrl);

  // Método para buscar todas as manutenções
  Future<List<Manutencao>> fetchManutencoes() async {
    final response = await http.get(Uri.parse('$baseUrl/manutencao'));

    if (response.statusCode == 200) {
      // Converte o JSON recebido em uma lista de Manutencao
      List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((json) => Manutencao.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load manutencoes');
    }
  }

  // Método para buscar uma manutenção por ID
  Future<Manutencao> fetchManutencaoById(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/manutencao/$id'));

    if (response.statusCode == 200) {
      return Manutencao.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load manutencao with id $id');
    }
  }

  // Método para criar uma nova manutenção
  Future<Manutencao> createManutencao(Manutencao manutencao) async {
    final response = await http.post(
      Uri.parse('$baseUrl/manutencao'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(manutencao.toJson()),
    );

    if (response.statusCode == 201) {
      return Manutencao.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create manutencao');
    }
  }

  // Método para atualizar uma manutenção existente
  Future<Manutencao> updateManutencao(int id, Manutencao manutencao) async {
    final response = await http.put(
      Uri.parse('$baseUrl/manutencao/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(manutencao.toJson()),
    );

    if (response.statusCode == 200) {
      return Manutencao.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to update manutencao with id $id');
    }
  }

  // Método para excluir uma manutenção
  Future<void> deleteManutencao(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/manutencao/$id'));

    if (response.statusCode != 204) {
      throw Exception('Failed to delete manutencao with id $id');
    }
  }
}