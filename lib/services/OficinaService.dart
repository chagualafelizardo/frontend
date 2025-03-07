import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:app/models/Oficina.dart';

class OficinaService {
  final String baseUrl;

  OficinaService(this.baseUrl);

  Future<List<Oficina>> fetchOficinas(int page, int itemsPerPage) async {
    final response = await http.get(
      Uri.parse('$baseUrl/oficina'),
    );

    if (response.statusCode == 200) {
      List<dynamic> body = json.decode(response.body);
      List<Oficina> oficinas =
          body.map((dynamic item) => Oficina.fromJson(item)).toList();
      return oficinas;
    } else {
      throw Exception('Failed to load workshops');
    }
  }

  Future<void> createOficina(Oficina oficina) async {
    final response = await http.post(
      Uri.parse('$baseUrl/oficina'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(oficina.toJson()),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to create workshop');
    }
  }

  Future<void> updateOficina(Oficina oficina) async {
    final response = await http.put(
      Uri.parse('$baseUrl/oficina/${oficina.id}'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(oficina.toJson()),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update workshop');
    }
  }

  Future<void> deleteOficina(String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/oficina/$id'),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete workshop');
    }
  }
}
