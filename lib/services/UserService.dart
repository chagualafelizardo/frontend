import 'dart:convert';
import 'package:app/models/UserRenderImgBase64.dart';
import 'package:http/http.dart' as http;
import 'package:app/models/User.dart';
import 'package:app/models/Role.dart'; // Certifique-se de importar o model Role

class UserService {
  final String apiUrl;

  UserService(this.apiUrl);

  Future<List<dynamic>> getUsers() async {
    final response = await http.get(Uri.parse('$apiUrl/user'));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data;
    } else {
      throw Exception('Failed to load users');
    }
  }

  Future<List<dynamic>> getAllMotoristas() async {
    final response = await http.get(Uri.parse('$apiUrl/userrole/motorista'));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data;
    } else {
      throw Exception('Failed to load users');
    }
  }

  Future<User> createUser(User user) async {
    try {
      final url = Uri.parse('$apiUrl/user');
      final headers = {'Content-Type': 'application/json'};
      final body = json.encode(user.toJson());

      print('Enviando solicitação para criar usuário...');
      print('URL: $url');
      print('Headers: $headers');
      print('Body: $body');

      final response = await http.post(url, headers: headers, body: body);

      print('Resposta recebida: ${response.statusCode}');
      print('Corpo da resposta: ${response.body}');

      if (response.statusCode == 201) {
        final responseData = json.decode(response.body);
        print('Usuário criado com sucesso: $responseData');
        return User.fromJson(responseData);
      } else {
        print('Erro ao criar usuário: ${response.statusCode}');
        print('Mensagem de erro: ${response.body}');
        throw Exception('Failed to create user');
      }
    } catch (e, stackTrace) {
      print('Erro ao enviar solicitação de criação de usuário: $e');
      print('StackTrace: $stackTrace');
      rethrow;
    }
  }

  Future<UserBase64> updateUser(int userId, UserBase64 updatedUser) async {
    print('[DEBUG] updateUser() iniciado');
    print('[DEBUG] User ID: $userId');
    print('[DEBUG] Dados do usuário a atualizar: ${updatedUser.toJson()}');
    
    try {
      final response = await http.put(
        Uri.parse('$apiUrl/user/$userId'),  // Usando userId diretamente
        headers: {'Content-Type': 'application/json'},
        body: json.encode(updatedUser.toJson()),
      );

      print('[DEBUG] Resposta do servidor - Status: ${response.statusCode}');
      print('[DEBUG] Resposta do servidor - Body: ${response.body}');

      if (response.statusCode == 200) {
        print('[DEBUG] Usuário atualizado com sucesso');
        return UserBase64.fromJson(json.decode(response.body));
      } else {
        print('[ERROR] Falha ao atualizar usuário: ${response.body}');
        throw Exception('Failed to update user. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('[ERROR] Exceção em updateUser: $e');
      rethrow;
    }
  }

  Future<void> deleteUser(int id) async {
    final response = await http.delete(Uri.parse('$apiUrl/user/$id'));

    if (response.statusCode != 200) {
      throw Exception('Failed to delete user');
    }
  }

  Future<User> getUserByFullName(String fullName) async {
    try {
      final response = await http.get(Uri.parse('$apiUrl/user/$fullName'));

      if (response.statusCode == 200) {
        final userData = json.decode(response.body);

        if (userData['img'] != null) {
          userData['img'] = userData['img'];
        }

        return User.fromJson(userData);
      } else {
        throw Exception('User not found');
      }
    } catch (error) {
      print('Error fetching user: $error');
      rethrow;
    }
  }

  Future<dynamic> getUserById(int userId) async {
    try {
      final response = await http.get(Uri.parse('$apiUrl/user/$userId'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        throw Exception('Usuário não encontrado');
      }
    } catch (error) {
      rethrow;
    }
  }

  // Novo método para buscar roles de um usuário específico
  Future<List<Role>> getUserRoles(int userId) async {
    try {
      final response = await http.get(Uri.parse('$apiUrl/user/$userId/roles'));
      
      if (response.statusCode == 200) {
        final List<dynamic> rolesJson = json.decode(response.body);
        return rolesJson.map((json) => Role.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load roles for user $userId');
      }
    } catch (e) {
      print('Error fetching user roles: $e');
      // Retorna uma lista vazia em caso de erro, ou lança a exceção se preferir
      return [];
      // Ou se preferir propagar o erro:
      // rethrow;
    }
  }

  Future<List<User>> getAllDrivers() async {
    final url = Uri.parse('$apiUrl/userrole/motorista');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => User.fromJson(json)).toList();
      } else {
        print('Erro ao buscar motoristas: ${response.body}');
        return [];
      }
    } catch (e) {
      print('Exceção ao buscar motoristas: $e');
      return [];
    }
  }

}

