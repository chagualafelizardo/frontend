import 'dart:convert';
import 'package:app/models/UserRole.dart';
import 'package:http/http.dart' as http;
import 'package:app/models/UserReserva.dart';

class UserServiceReserva {
  final String apiUrl;

  UserServiceReserva(this.apiUrl);

  Future<List<dynamic>> getUsers() async {
    final response = await http.get(Uri.parse('$apiUrl/user'));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data;
    } else {
      throw Exception('Failed to load users');
    }
  }

  // Future<List<User>> getClient() async {
  //   final response = await http.get(Uri.parse('$apiUrl/user'));

  //   if (response.statusCode == 200) {
  //     final List<dynamic> data = json.decode(response.body);
  //     print('Fetched users data: $data'); // Log da resposta
  //     return data.map((json) => User.fromJson(json)).toList();
  //   } else {
  //     print('Failed to fetch users: ${response.body}');
  //     throw Exception('Failed to load users');
  //   }
  // }
  
  // Método para buscar todos os clientes
  Future<List<User>> getAllClients() async {
    try {
      final response = await http.get(Uri.parse('$apiUrl/userrole/clients'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print('Fetched clients data: $data'); // Log da resposta
        return data.map((user) => User.fromJson(user)).toList();
      } else {
        print('Failed to fetch clients: ${response.body}');
        return [];
      }
    } catch (error) {
      print('Error fetching clients: $error');
      return [];
    }
  }

    Future<List<User>> getAllDrivers() async {
    try {
      final response = await http.get(Uri.parse('$apiUrl/userrole/drivers'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print('Fetched clients data: $data'); // Log da resposta
        return data.map((user) => User.fromJson(user)).toList();
      } else {
        print('Failed to fetch clients: ${response.body}');
        return [];
      }
    } catch (error) {
      print('Error fetching clients: $error');
      return [];
    }
  }


  Future<User> createUser(User user) async {
    final response = await http.post(
      Uri.parse('$apiUrl/user'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(user.toJson()),
    );

    if (response.statusCode == 201) {
      return User.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to create user');
    }
  }

  Future<User> updateUser(User user) async {
    final response = await http.put(
      Uri.parse('$apiUrl/user/${user.id}'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(user.toJson()),
    );

    if (response.statusCode == 200) {
      return User.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to update user');
    }
  }

  Future<void> deleteUser(int id) async {
    final response = await http.delete(Uri.parse('$apiUrl/user/$id'));

    if (response.statusCode != 200) {
      throw Exception('Failed to delete user');
    }
  }
}
