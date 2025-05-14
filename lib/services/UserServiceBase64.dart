import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:app/models/UserRenderImgBase64.dart';

class UserServiceBase64 {
  final String apiUrl;

  UserServiceBase64(this.apiUrl);

  Future<List<dynamic>> getUsers() async {
    final response = await http.get(Uri.parse('$apiUrl/user'));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data;
    } else {
      throw Exception('Failed to load users');
    }
  }
  

  Future<List<UserBase64>> getClient() async {
    final response = await http.get(Uri.parse('$apiUrl/user'));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      print('Fetched users data: $data'); // Log da resposta
      return data.map((json) => UserBase64.fromJson(json)).toList();
    } else {
      print('Failed to fetch users: ${response.body}');
      throw Exception('Failed to load users');
    }
  }

  Future<void> deleteUser(int id) async {
    final response = await http.delete(Uri.parse('$apiUrl/user/$id'));

    if (response.statusCode != 200) {
      throw Exception('Failed to delete user');
    }
  }

  Future<dynamic> getUserById(int userId) async {
    try {
      final response = await http.get(Uri.parse('$apiUrl/user/$userId'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data; // Retorna o usuário específico
      } else {
        throw Exception('Usuário não encontrado');
      }
    } catch (error) {
      rethrow;
    }
  }
}
