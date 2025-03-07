import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:app/models/DetalhesManutencao.dart';

class DetalhesManutencaoService {
  final String baseUrl;

  // Construtor que recebe a URL base do backend
  DetalhesManutencaoService(this.baseUrl);

  // Método para buscar todos os detalhes de manutenção
  Future<List<DetalhesManutencao>> fetchDetalhesManutencao() async {
    final response = await http.get(Uri.parse('$baseUrl/detalhesmanutencao'));

    if (response.statusCode == 200) {
      // Converte o JSON recebido em uma lista de DetalhesManutencao
      List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((json) => DetalhesManutencao.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load detalhes manutenção');
    }
  }

  // Método para buscar detalhes de manutenção por ID
  Future<DetalhesManutencao> fetchDetalhesManutencaoById(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/detalhesmanutencao/$id'));

    if (response.statusCode == 200) {
      return DetalhesManutencao.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load detalhes manutenção with id $id');
    }
  }

  // Método para criar um novo detalhe de manutenção
  Future<DetalhesManutencao> createDetalhesManutencao(DetalhesManutencao detalhesManutencao) async {
    final response = await http.post(
      Uri.parse('$baseUrl/detalhesmanutencao'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(detalhesManutencao.toJson()),
    );

    if (response.statusCode == 201) {
      return DetalhesManutencao.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create detalhes manutenção');
    }
  }

  // Método para atualizar um detalhe de manutenção existente
  Future<DetalhesManutencao> updateDetalhesManutencao(int id, DetalhesManutencao detalhesManutencao) async {
    final response = await http.put(
      Uri.parse('$baseUrl/detalhesmanutencao/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(detalhesManutencao.toJson()),
    );

    if (response.statusCode == 200) {
      return DetalhesManutencao.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to update detalhes manutenção with id $id');
    }
  }

  // Método para excluir um detalhe de manutenção
  Future<void> deleteDetalhesManutencao(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/detalhesmanutencao/$id'));

    if (response.statusCode != 204) {
      throw Exception('Failed to delete detalhes manutenção with id $id');
    }
  }
}