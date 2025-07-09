import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:app/models/Posto.dart';

class PostoService {
  final String baseUrl;

  PostoService(this.baseUrl);

  Future<List<Posto>> fetchPostos(int page, int itemsPerPage) async {
    final response = await http.get(Uri.parse('$baseUrl/posto'));
    if (response.statusCode == 200) {
      List<dynamic> body = json.decode(response.body);
      return body.map((dynamic item) => Posto.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load postos');
    }
  }

  Future<void> addPosto(Posto posto) async {
    final response = await http.post(
      Uri.parse('$baseUrl/posto'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(posto.toJson()),
    );
    if (response.statusCode != 201) {
      throw Exception('Failed to add posto');
    }
  }

  Future<void> updatePosto(Posto posto) async {
    final response = await http.put(
      Uri.parse('$baseUrl/posto/${posto.id}'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(posto.toJson()),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update posto');
    }
  }


   Future<void> deletePosto(int id) async {
    final url = Uri.parse('$baseUrl/posto/$id');
    try {
      final response = await http.delete(url);
      if (response.statusCode != 200) {
        throw Exception('Failed to delete Posto: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error deleting Posto: $e');
    }
  }
}
