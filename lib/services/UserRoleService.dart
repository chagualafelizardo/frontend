// userRoleService.dart
import 'dart:convert';
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

  // Método para obter os papéis por ID do usuário
  Future<List<UserRole>?> getRolesByUserId(int userId) async {
    try {
      final response =
          await http.get(Uri.parse('$baseUrl/userrole/user/$userId'));

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((role) => UserRole.fromJson(role)).toList();
      } else {
        print('Failed to fetch roles: ${response.body}');
        return null;
      }
    } catch (error) {
      print('Error fetching roles: $error');
      return null;
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
}
