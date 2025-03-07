import 'dart:convert';
import 'package:app/models/User.dart';
import 'package:app/models/UserRenderImgBase64.dart';
import 'package:http/http.dart' as http;
import '../models/UserAtendimentoAllocation.dart'; // Atualize o caminho conforme necessário

class UserAtendimentoAllocationService {
  String baseUrl;

  UserAtendimentoAllocationService({required this.baseUrl});

  // Criar uma nova associação
  Future<UserAtendimentoAllocation> createUserAtendimentoAllocation(
      UserAtendimentoAllocation allocation) async {
    final response = await http.post(
      Uri.parse('$baseUrl/useratendimentoallocation'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(allocation.toJson()),
    );

    if (response.statusCode == 201) {
      return UserAtendimentoAllocation.fromJson(jsonDecode(response.body)['data']);
    } else {
      throw Exception('Failed to create association: ${response.body}');
    }
  }

// Future<UserBase64> getDriverForAtendimento(int atendimentoId) async {
//   try {
//     var response = await http.get(Uri.parse('$baseUrl/useratendimentoallocation/user/atendimento/$atendimentoId'));

//     if (response.statusCode == 200) {
//       final Map<String, dynamic> data = json.decode(response.body);
//       return UserBase64.fromJson(data);
//     } else {
//       throw Exception('Erro ao buscar motorista');
//     }
//   } catch (error) {
//     rethrow;
//   }
// }

Future<int> getDriverForAtendimento(int atendimentoId) async {
  try {
    var response = await http.get(Uri.parse('$baseUrl/useratendimentoallocation/user/atendimento/$atendimentoId'));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      
      // Extrai o userId do JSON
      final int userId = data['userId'];
      
      return userId;
    } else {
      throw Exception('Erro ao buscar motorista');
    }
  } catch (error) {
    rethrow;
  }
}

  // Listar todas as associações
  Future<List<UserAtendimentoAllocation>> getAllUserAtendimentoAllocations() async {
    final response = await http.get(
      Uri.parse('$baseUrl/useratendimentoallocation'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body)['data'];
      return data.map((json) => UserAtendimentoAllocation.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch associations: ${response.body}');
    }
  }

  // Obter uma associação pelo ID
  Future<UserAtendimentoAllocation> getUserAtendimentoAllocationById(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/useratendimentoallocation/$id'),
    );

    if (response.statusCode == 200) {
      return UserAtendimentoAllocation.fromJson(jsonDecode(response.body)['data']);
    } else {
      throw Exception('Failed to fetch association: ${response.body}');
    }
  }

  // Atualizar uma associação pelo ID
  Future<UserAtendimentoAllocation> updateUserAtendimentoAllocation(
      int id, UserAtendimentoAllocation allocation) async {
    final response = await http.put(
      Uri.parse('$baseUrl/useratendimentoallocation/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(allocation.toJson()),
    );

    if (response.statusCode == 200) {
      return UserAtendimentoAllocation.fromJson(jsonDecode(response.body)['data']);
    } else {
      throw Exception('Failed to update association: ${response.body}');
    }
  }

  // Excluir uma associação pelo ID
  Future<void> deleteUserAtendimentoAllocation(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/useratendimentoallocation/$id'),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete association: ${response.body}');
    }
  }
}
