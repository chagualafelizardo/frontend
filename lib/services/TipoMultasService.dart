import 'dart:convert';
import 'package:app/models/TipoMulta.dart';
import 'package:http/http.dart' as http;

class TipoMultaService {
  final String baseUrl;

  TipoMultaService(this.baseUrl);

  Future<List<TipoMulta>> fetchAll() async {
    final response = await http.get(Uri.parse('$baseUrl/tipomulta'));
    
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body); // Decodifica diretamente para List
      return data.map((item) => TipoMulta.fromJson(item as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Failed to load fine types. Status: ${response.statusCode}');
    }
  }

  Future<TipoMulta> getById(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/tipomulta/$id'));

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseBody = json.decode(response.body);
      if (responseBody['success'] == true) {
        return TipoMulta.fromJson(responseBody['data']);
      } else {
        throw Exception(responseBody['message'] ?? 'Fine type not found');
      }
    } else if (response.statusCode == 404) {
      throw Exception('Fine type not found');
    } else {
      throw Exception('Failed to load fine type. Status: ${response.statusCode}');
    }
  }

  Future<TipoMulta> create(TipoMulta tipoMulta) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/tipomulta'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'description': tipoMulta.description,
          'valorpagar': tipoMulta.valorpagar.toStringAsFixed(2), // Converte para String com 2 decimais
        }),
      );

      print('Response status: ${response.statusCode}'); // Debug
      print('Response body: ${response.body}'); // Debug

      if (response.statusCode == 201) {
        final responseBody = json.decode(response.body) as Map<String, dynamic>;
        return TipoMulta.fromJson(responseBody['data'] ?? responseBody);
      } else if (response.statusCode == 400) {
        final errorBody = json.decode(response.body) as Map<String, dynamic>;
        throw Exception(errorBody['errors']?.join('\n') ?? errorBody['message'] ?? 'Validation error');
      } else {
        throw Exception('Failed to create fine type. Status: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      print('Error in create: $e');
      print('Stack trace: $stackTrace');
      throw Exception('Failed to create fine type: $e');
    }
  }

  Future<TipoMulta> update(TipoMulta tipoMulta) async {
    try {
      if (tipoMulta.id == null) {
        throw Exception('ID cannot be null for update');
      }

      // Simplified payload
      final body = {
        'description': tipoMulta.description,
        // Try sending as number instead of string
        'valorpagar': tipoMulta.valorpagar, 
      };

      final response = await http.put(
        Uri.parse('$baseUrl/tipomulta/${tipoMulta.id}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      final responseBody = json.decode(response.body);

      if (response.statusCode == 200) {
        return TipoMulta.fromJson(responseBody['data'] ?? responseBody);
      } else {
        // Improved error message handling
        final serverError = responseBody['error']?.toString() ?? 'No error details';
        throw Exception(
          'Server error (${response.statusCode}): ${responseBody['message']}\n'
          'Technical details: $serverError'
        );
      }
    } on FormatException catch (e) {
      throw Exception('Invalid server response format: $e');
    } catch (e) {
      throw Exception('Update failed: ${e.toString()}');
    }
  }

  Future<void> delete(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/tipomulta/$id'),
        headers: {'Accept': 'application/json'}, // Adiciona header para garantir JSON
      );

      print('Delete response status: ${response.statusCode}'); // Debug
      print('Delete response body: ${response.body}'); // Debug

      if (response.statusCode == 200 || response.statusCode == 204) {
        // Aceita tanto 200 (OK) quanto 204 (No Content)
        if (response.body.isEmpty) return; // Resposta vazia é válida para DELETE
        
        try {
          final responseBody = json.decode(response.body) as Map<String, dynamic>;
          if (responseBody['success'] == false) {
            throw Exception(responseBody['message'] ?? 'Failed to delete fine type');
          }
        } on FormatException {
          // Se não for JSON válido, mas status é 200/204, considera sucesso
          return;
        }
      } else if (response.statusCode == 404) {
        throw Exception('Fine type not found');
      } else {
        throw Exception('Failed to delete fine type. Status: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      print('Error in delete: $e');
      print('Stack trace: $stackTrace');
      throw Exception('Failed to delete fine type: $e');
    }
  }
}