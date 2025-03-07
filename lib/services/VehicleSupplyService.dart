import 'dart:convert';
import 'package:app/models/VehicleSupply.dart';
import 'package:http/http.dart' as http;

class VehicleSupplyService {
  final String baseUrl;

  VehicleSupplyService({required this.baseUrl});

  /// Cria um novo registro de `VehicleSupply` no backend.
  Future<VehicleSupply?> createVehicleSupply(VehicleSupply vehicleSupply) async {
  final url = Uri.parse('$baseUrl/vehiclesupply');
  try {
    final jsonBody = jsonEncode(vehicleSupply.toJson());
    print('Request Body: $jsonBody'); // Adicionado para debug
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonBody,
    );
    if (response.statusCode == 201) {
      return VehicleSupply.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create vehicle supply: ${response.body}');
    }
  } catch (e) {
    throw Exception('Error creating vehicle supply: $e');
  }
}

  /// Retorna uma lista de todos os registros de `VehicleSupply`.
Future<List<VehicleSupply>> getAllVehicleSupplies() async {
  final url = Uri.parse('$baseUrl/vehiclesupply');
  try {
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final Map<String, dynamic> responseBody = jsonDecode(response.body);
      // Acessa a lista de supplies dentro da chave 'data'
      final List<dynamic> data = responseBody['data'];
      return data.map((json) => VehicleSupply.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch vehicle supplies: ${response.body}');
    }
  } catch (e) {
    throw Exception('Error fetching vehicle supplies: $e');
  }
}

  /// Retorna um único registro de `VehicleSupply` pelo ID.
  Future<VehicleSupply?> getVehicleSupplyById(int id) async {
    final url = Uri.parse('$baseUrl/vehiclesupply/$id');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return VehicleSupply.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to fetch vehicle supply by ID: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching vehicle supply by ID: $e');
    }
  }

  /// Atualiza um registro de `VehicleSupply` existente no backend.
  Future<VehicleSupply?> updateVehicleSupply(VehicleSupply vehicleSupply) async {
    final url = Uri.parse('$baseUrl/vehiclesupply/${vehicleSupply.id}');
    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(vehicleSupply.toJson()),
      );
      if (response.statusCode == 200) {
        return VehicleSupply.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to update vehicle supply: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error updating vehicle supply: $e');
    }
  }

  /// Exclui um registro de `VehicleSupply` pelo ID.
  Future<void> deleteVehicleSupply(int id) async {
    final url = Uri.parse('$baseUrl/vehiclesupply/$id');
    try {
      final response = await http.delete(url);
      if (response.statusCode != 200) {
        throw Exception('Failed to delete vehicle supply: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error deleting vehicle supply: $e');
    }
  }
}
