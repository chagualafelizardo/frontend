import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:app/models/Multa.dart';

class MultaService {
  final String baseUrl;

  MultaService(this.baseUrl);

  Future<List<Multa>> fetchMultas() async {
    final response = await http.get(
      Uri.parse('$baseUrl/multa'),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseBody = json.decode(response.body);
      if (responseBody['success'] == true) {
        List<dynamic> data = responseBody['data'];
        return data.map((item) => Multa.fromJson(item)).toList();
      } else {
        throw Exception(responseBody['message'] ?? 'Failed to load fines');
      }
    } else {
      throw Exception('Failed to load fines. Status code: ${response.statusCode}');
    }
  }

  Future<Multa> getMultaById(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/multa/$id'),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseBody = json.decode(response.body);
      if (responseBody['success'] == true) {
        return Multa.fromJson(responseBody['data']);
      } else {
        throw Exception(responseBody['message'] ?? 'Fine not found');
      }
    } else if (response.statusCode == 404) {
      throw Exception('Fine not found');
    } else {
      throw Exception('Failed to load fine. Status code: ${response.statusCode}');
    }
  }

  Future<List<Multa>> fetchMultasByAtendimentoId(int atendimentoId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/multa/atendimento/$atendimentoId'),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseBody = json.decode(response.body);
      if (responseBody['success'] == true) {
        List<dynamic> data = responseBody['data'];
        return data.map((item) => Multa.fromJson(item)).toList();
      } else {
        throw Exception(responseBody['message'] ?? 'No fines found for this atendimento');
      }
    } else if (response.statusCode == 404) {
      throw Exception('No fines found for atendimentoId: $atendimentoId');
    } else {
      throw Exception('Failed to fetch fines by atendimentoId. Status code: ${response.statusCode}');
    }
  }


  Future<Multa> createMulta(Multa multa) async {
    print('[API] Enviando requisição para criar multa');
    print('[API] Dados enviados:');
    print('- description: ${multa.description}');
    print('- valorpagar: ${multa.valorpagar}');
    print('- observation: ${multa.observation}');
    print('- atendimentoId: ${multa.atendimentoId}');
    print('- dataMulta: ${multa.dataMulta?.toIso8601String()}');

    final response = await http.post(
      Uri.parse('$baseUrl/multa'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'description': multa.description,
        'valorpagar': multa.valorpagar,
        'observation': multa.observation,
        'atendimentoId': multa.atendimentoId,
        'dataMulta': multa.dataMulta?.toIso8601String(), // Garante o formato ISO
      }),
    );

    print('[API] Resposta recebida:');
    print('- Status Code: ${response.statusCode}');
    print('- Body: ${response.body}');

    if (response.statusCode == 201) {
      final Map<String, dynamic> responseBody = json.decode(response.body);
      if (responseBody['success'] == true) {
        print('[API] Multa criada com sucesso');
        return Multa.fromJson(responseBody['data']);
      } else {
        print('[API] Erro na resposta: ${responseBody['message']}');
        throw Exception(responseBody['message'] ?? 'Failed to create fine');
      }
    } else if (response.statusCode == 400) {
      final Map<String, dynamic> errorBody = json.decode(response.body);
      print('[API] Erro de validação: ${errorBody['errors']}');
      throw Exception(errorBody['errors']?.join('\n') ?? 'Validation error');
    } else {
      print('[API] Erro desconhecido: ${response.statusCode}');
      throw Exception('Failed to create fine. Status code: ${response.statusCode}');
    }
  }

  Future<Multa> updateMulta(Multa multa) async {
    final response = await http.put(
      Uri.parse('$baseUrl/multa/${multa.id}'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'description': multa.description,
        'valorpagar': multa.valorpagar,
        'observation': multa.observation,
        'atendimentoId': multa.atendimentoId, // Adicionado aqui
        'dataMulta': multa.dataMulta?.toIso8601String(), // Garante o formato ISO
      }),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseBody = json.decode(response.body);
      if (responseBody['success'] == true) {
        return Multa.fromJson(responseBody['data']);
      } else {
        throw Exception(responseBody['message'] ?? 'Failed to update fine');
      }
    } else if (response.statusCode == 400) {
      final Map<String, dynamic> errorBody = json.decode(response.body);
      throw Exception(errorBody['errors']?.join('\n') ?? 'Validation error');
    } else if (response.statusCode == 404) {
      throw Exception('Fine not found');
    } else {
      throw Exception('Failed to update fine. Status code: ${response.statusCode}');
    }
  }

  Future<void> deleteMulta(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/multa/$id'),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseBody = json.decode(response.body);
      if (responseBody['success'] != true) {
        throw Exception(responseBody['message'] ?? 'Failed to delete fine');
      }
    } else if (response.statusCode == 404) {
      throw Exception('Fine not found');
    } else {
      throw Exception('Failed to delete fine. Status code: ${response.statusCode}');
    }
  }
}
