import 'dart:convert';
import 'package:app/models/Reserva.dart';
import 'package:app/models/Role.dart';
import 'package:app/models/UserRole.dart';
import 'package:http/http.dart' as http;

class UserRoleService {
  final String baseUrl;
  UserRoleService(this.baseUrl);

  // Método para atribuir um papel a um usuário
  Future<UserRole?> assignRoleToUser(int userId, int roleId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/userrole'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'roleId': roleId,
        }),
      );

      if (response.statusCode == 201) {
        return UserRole.fromJson(jsonDecode(response.body));
      } else {
        print('Failed to assign role: ${response.body}');
        return null;
      }
    } catch (error) {
      print('Error assigning role: $error');
      return null;
    }
  }

Future<List<Role>> getRolesByUserId(int userId) async {
  final response = await http.get(Uri.parse('$baseUrl/userrole/user/$userId'));

  if (response.statusCode == 200) {
    final Map<String, dynamic> data = jsonDecode(response.body);
    print('Resposta da API: $data'); // Adicione este print para depuração

    final List<dynamic> rolesJson = data['roles']; // Ajuste conforme a chave correta
    return rolesJson.map((roleJson) => Role.fromJson(roleJson)).toList();
  } else {
    throw Exception('Failed to load roles for user $userId');
  }
}

  // Método para obter os usuários por ID do papel
  Future<List<UserRole>?> getUsersByRoleId(int roleId) async {
    try {
      final response =
          await http.get(Uri.parse('$baseUrl/userrole/role/$roleId'));

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((userRole) => UserRole.fromJson(userRole)).toList();
      } else {
        print('Failed to fetch users: ${response.body}');
        return null;
      }
    } catch (error) {
      print('Error fetching users: $error');
      return null;
    }
  }

  // Método para remover todas as roles de um usuário
  Future<bool> removeAllRolesFromUser(int userId) async {
    try {
      final response =
          await http.delete(Uri.parse('$baseUrl/userrole/user/$userId'));

      if (response.statusCode == 200) {
        print('All roles removed successfully for user ID: $userId');
        return true;
      } else {
        print('Failed to remove roles: ${response.body}');
        return false;
      }
    } catch (error) {
      print('Error removing roles: $error');
      return false;
    }
  } 
}