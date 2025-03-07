import 'dart:convert';
import 'package:app/models/Role.dart';
import 'package:app/models/UserRole.dart';
import 'package:http/http.dart' as http;

class RoleService {
  final String baseUrl;

  RoleService(this.baseUrl);

  Future<List<Role>> getRoles() async {
    final response = await http.get(Uri.parse('$baseUrl/role'));

    if (response.statusCode == 200) {
      List<dynamic> body = json.decode(response.body);
      return body.map((dynamic item) => Role.fromJson(item)).toList();
    } else {
      throw Exception('Falha ao carregar roles');
    }
  }

  Future<bool> deleteRole(int id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/role/$id'));
      return response.statusCode == 204; // HTTP 204 No Content
    } catch (e) {
      print('Error deleting role: $e');
      return false;
    }
  }

  Future<Role?> addRole(String name) async {
    final String url = '$baseUrl/role'; // Ajuste conforme necessário

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'name': name}),
      );

      if (response.statusCode == 201) {
        return Role.fromJson(json.decode(response.body));
      } else {
        // Lidar com erro
        return null;
      }
    } catch (e) {
      // Lidar com exceções
      print('Erro: $e');
      return null;
    }
  }

  Future<void> addUserRole(UserRole userRole) async {
    final response = await http.post(
      Uri.parse('$baseUrl/userrole'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(userRole.toJson()),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to assign role to user');
    }
  }

  Future<Role?> updateRole(int id, String name) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/role/$id'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'name': name}),
      );

      if (response.statusCode == 200) {
        // HTTP 200 OK
        return Role.fromJson(json.decode(response.body));
      }
    } catch (e) {
      print('Error updating role: $e');
    }
    return null;
  }
}
