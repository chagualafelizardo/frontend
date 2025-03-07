import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/Allocation.dart';

class AllocationService {
  final String baseUrl;

  AllocationService(this.baseUrl);


Future<List<dynamic>> getAllAllocations({int page = 1, int pageSize = 10}) async {
    final response = await http.get(Uri.parse('$baseUrl/allocation'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    } else {
      throw Exception('Failed to load allocations');
    }
  }

  // Método para buscar uma alocação por ID
  Future<Allocation> getAllocationById(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/allocation/$id'));

    if (response.statusCode == 200) {
      return Allocation.fromJson(json.decode(response.body));
    } else if (response.statusCode == 404) {
      throw Exception('Allocation not found');
    } else {
      throw Exception('Failed to fetch allocation');
    }
  }

  // Método para criar uma nova alocação
  Future<Allocation> createAllocation(Allocation allocation) async {
    final response = await http.post(
      Uri.parse('$baseUrl/allocation'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(allocation.toJson()),
    );

    if (response.statusCode == 201) {
      return Allocation.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to create allocation');
    }
  }

  // Método para atualizar uma alocação por ID
  Future<Allocation> updateAllocation(int id, Allocation allocation) async {
    final response = await http.put(
      Uri.parse('$baseUrl/allocation/$id'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(allocation.toJson()),
    );

    if (response.statusCode == 200) {
      return Allocation.fromJson(json.decode(response.body));
    } else if (response.statusCode == 404) {
      throw Exception('Allocation not found');
    } else {
      throw Exception('Failed to update allocation');
    }
  }

  // Método para deletar uma alocação por ID
  Future<void> deleteAllocation(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/allocation/$id'));

    if (response.statusCode == 200) {
      return;
    } else if (response.statusCode == 404) {
      throw Exception('Allocation not found');
    } else {
      throw Exception('Failed to delete allocation');
    }
  }

  // Método para buscar alocações por motorista
  Future<List<Allocation>> getAllocationsByDriver(int driverId) async {
    final response =
        await http.get(Uri.parse('$baseUrl/allocation/driver/$driverId'));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Allocation.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch allocations for driver');
    }
  }
}
