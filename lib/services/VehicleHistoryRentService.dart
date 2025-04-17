import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:app/models/VehicleHistoryRent.dart';

class VehicleHistoryRentService {
  final String baseUrl;

  VehicleHistoryRentService(this.baseUrl);

  // Buscar todos os históricos
  Future<List<VehicleHistoryRent>> getAll() async {
    final response = await http.get(Uri.parse('$baseUrl/vehiclehistoryrent'));
    
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => VehicleHistoryRent.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load history');
    }
  }

  // Buscar por ID
  Future<VehicleHistoryRent> getById(int id) async {
    final response =
        await http.get(Uri.parse('$baseUrl/vehiclehistoryrent/$id'));

    if (response.statusCode == 200) {
      return VehicleHistoryRent.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load vehicle rent history by ID');
    }
  }

Future<VehicleHistoryRent> create(VehicleHistoryRent history) async {
  final response = await http.post(
    Uri.parse('$baseUrl/vehiclehistoryrent'),
    headers: {'Content-Type': 'application/json'},
    body: json.encode({
      'datavalor': history.datavalor?.toIso8601String(),
      'valor': history.valor, // Já é double
      'obs': history.obs,
      'veiculoID': history.veiculoID,
    }),
  );

  if (response.statusCode == 201) {
    return VehicleHistoryRent.fromJson(json.decode(response.body));
  } else {
    throw Exception('Failed to create vehicle history');
  }
}

  // Atualizar histórico existente
  Future<VehicleHistoryRent> update(int id, VehicleHistoryRent history) async {
    final response = await http.put(
      Uri.parse('$baseUrl/vehiclehistoryrent/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(history.toJson()),
    );

    if (response.statusCode == 200) {
      return VehicleHistoryRent.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to update vehicle rent history');
    }
  }

  // Deletar histórico
  Future<bool> delete(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/vehiclehistoryrent/$id'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      return true;
    } else if (response.statusCode == 404) {
      throw Exception('Vehicle rent history not found');
    } else {
      throw Exception(
          'Failed to delete vehicle rent history. Status code: ${response.statusCode}');
    }
  }

  Future<List<VehicleHistoryRent>> getHistoryByVehicleId(int vehicleId) async {
  final response = await http.get(
    Uri.parse('$baseUrl/vehiclehistoryrent/byvehicle/$vehicleId'),
  );

  if (response.statusCode == 200) {
    final List<dynamic> data = json.decode(response.body);
    return data.map((json) => VehicleHistoryRent.fromJson(json)).toList();
  } else if (response.statusCode == 404) {
    return []; // Retorna lista vazia se não encontrar
  } else {
    throw Exception('Failed to load vehicle history');
  }
}

Future<double?> getLatestRentValue(int veiculoId) async {
  final response = await http.get(Uri.parse('$baseUrl/vehiclehistoryrent/last/$veiculoId'));

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    final valor = data['valor'];
    return valor != null ? double.parse(valor.toString()) : null;
  } else {
    throw Exception('Failed to fetch latest rent value');
  }
}

}
