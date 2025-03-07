import 'dart:convert';
import 'package:app/models/ItensEntrega.dart';
import 'package:http/http.dart' as http;

class ItensEntregaService {

  final String baseUrl;
  ItensEntregaService(this.baseUrl);

  // Função para buscar todos os itens de entrega
  Future<List<ItensEntrega>> getAllItensEntrega() async {
  try {
    final response = await http.get(Uri.parse('$baseUrl/itensentrega'));
    if (response.statusCode == 200) {
      // Decodifica a resposta JSON
      final Map<String, dynamic> jsonResponse = json.decode(response.body);

      // Verifica se o campo "data" existe e é uma lista
      if (jsonResponse['data'] is List) {
        final List<dynamic> data = jsonResponse['data'];
        return data.map((json) => ItensEntrega.fromJson(json)).toList();
      } else {
        throw Exception('Formato inválido na resposta do servidor');
      }
    } else {
      throw Exception('Falha ao buscar itens de entrega');
    }
  } catch (e) {
    print('Erro ao buscar os itens de entrega: $e');
    rethrow;
  }
}
  // Função para buscar um item de entrega por ID
  Future<ItensEntrega> getItensEntregaById(int id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/itensentrega/$id'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return ItensEntrega.fromJson(data);
      } else {
        throw Exception('Item de entrega não encontrado');
      }
    } catch (e) {
      rethrow;
    }
  }

Future<ItensEntrega> createItensEntrega(String item, String? obs) async {
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/itensentrega'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'item': item,
        'obs': obs,
      }),
    );

    if (response.statusCode == 201) {
      final Map<String, dynamic> data = json.decode(response.body);
      return ItensEntrega.fromJson(data);
    } else {
      throw Exception('Failed to add delivery item');
    }
  } catch (e) {
    rethrow;
  }
}

  // Função para atualizar um item de entrega
  Future<ItensEntrega> updateItensEntrega(int id, Map<String, String?> data) async {
  try {
    final response = await http.put(
      Uri.parse('$baseUrl/itensentrega/$id'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      return ItensEntrega.fromJson(responseData);
    } else {
      throw Exception('Failed to update delivery item');
    }
  } catch (e) {
    rethrow;
  }
}


  // Função para deletar um item de entrega por ID
  Future<void> deleteItensEntrega(int id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/itensentrega/$id'));

      if (response.statusCode != 200) {
        throw Exception('Falha ao deletar item de entrega');
      }
    } catch (e) {
      rethrow;
    }
  }
}
