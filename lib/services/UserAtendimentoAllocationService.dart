import 'dart:convert';
import 'package:flutter/material.dart';
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

// Future<UserAtendimentoAllocation> createUserAtendimentoAllocation(UserAtendimentoAllocation allocation) async {
// // Converter para o formato esperado pelo backend
//   final adjustedData = {
//     'UserId': allocation.userId, // Note o U maiúsculo
//     'AtendimentoId': allocation.atendimentoId,
//     'AllocationId': allocation.allocationId,
//     'createdAt': allocation.createdAt?.toIso8601String(),
//     'updatedAt': allocation.updatedAt?.toIso8601String(),
//   };

//   final response = await http.post(
//     Uri.parse('$baseUrl/useratendimentoallocation'),
//     headers: {'Content-Type': 'application/json'},
//     body: jsonEncode(adjustedData), // Envie o objeto ajustado
//   );

//   if (response.statusCode == 201) {
//     return UserAtendimentoAllocation.fromJson(jsonDecode(response.body)['data']);
//   } else {
//     throw Exception('Failed to create association: ${response.body}');
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
  Future<void> deleteUserAtendimentoAllocationById(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/useratendimentoallocation/$id'),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete association: ${response.body}');
    }
  }
  
    // No UserAtendimentoAllocationService
  Future<void> deleteUserAtendimentoAllocationByUserId(int userId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/useratendimentoallocation/user/$userId'),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete association by user ID: ${response.body}');
    }
  }

  Future<List<Map<String, dynamic>>> getUserDetailsByAtendimentoId(int atendimentoId) async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/useratendimentoallocation/user/atendimento/$atendimentoId'),
    );

    if (response.statusCode == 404) {
      return [];
    }

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch driver details. Status code: ${response.statusCode}');
    }

    final Map<String, dynamic> responseData = jsonDecode(response.body);
    
    if (responseData['success'] == false) {
      return [];
    }

    final List<dynamic> usersData = responseData['data'] ?? [];
    return usersData.map<Map<String, dynamic>>((user) {
      // Nova lógica para tratamento do nome
      String nomeCompleto = 'Nome não disponível';
      
      if (user['firstName'] != null && user['lastName'] != null) {
        nomeCompleto = '${user['firstName']} ${user['lastName']}'.trim();
      } 
      else if (user['firstName'] != null) {
        nomeCompleto = user['firstName'];
      }
      else if (user['lastName'] != null) {
        nomeCompleto = user['lastName'];
      }
      else if (user['nome'] != null) {
        nomeCompleto = user['nome']; // Caso o backend já envie o nome completo
      }

      return {
        'id': user['id'],
        'nome': nomeCompleto,
        'email': user['email'] ?? 'Email não disponível',
        'telefone': user['phone1'] ?? user['telefone'] ?? 'Telefone não disponível',
        'telefoneAlternativo': user['phone2'] ?? user['telefoneAlternativo'] ?? '',
        'imagem': user['img'] ?? user['imagem'] ?? '',
      };
    }).toList();

  } catch (error) {
    // Log do erro para debug
    debugPrint('Error in getUserDetailsByAtendimentoId: $error');
    
    // Retorna lista vazia em caso de erro para não quebrar a UI
    return [];
  }
}
}
