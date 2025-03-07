import 'dart:convert';
import 'package:app/models/BankDetails.dart';
import 'package:http/http.dart' as http;

class BankDetailsService {
final String baseUrl;
  final int userID;
  final String username;

  BankDetailsService({
    required this.baseUrl,
    required this.userID,
    required this.username,
  });

  /// Cria um novo registro de `BankDetails` no backend.
  Future<BankDetails?> createBankDetails(BankDetails bankDetails) async {
    final url = Uri.parse('$baseUrl/userbankdetails');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(bankDetails.toJson()),
      );
      if (response.statusCode == 201) {
        return BankDetails.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to create bank details: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error creating bank details: $e');
    }
  }

  /// Retorna uma lista de todos os registros de `BankDetails`.
  Future<List<BankDetails>> getAllBankDetails() async {
    final url = Uri.parse('$baseUrl/userbankdetails');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => BankDetails.fromJson(json)).toList();
      } else {
        throw Exception('Failed to fetch bank details: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching bank details: $e');
    }
  }

  /// Retorna um único registro de `BankDetails` pelo ID.
  Future<BankDetails?> getBankDetailsById(int id) async {
    final url = Uri.parse('$baseUrl/userbankdetails/$id');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return BankDetails.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to fetch bank details by ID: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching bank details by ID: $e');
    }
  }

  /// Atualiza um registro de `BankDetails` existente no backend.
  Future<BankDetails?> updateBankDetails(BankDetails bankDetails) async {
    final url = Uri.parse('$baseUrl/userbankdetails/${bankDetails.id}');
    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(bankDetails.toJson()),
      );
      if (response.statusCode == 200) {
        return BankDetails.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to update bank details: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error updating bank details: $e');
    }
  }

  /// Exclui um registro de `BankDetails` pelo ID.
  Future<void> deleteBankDetails(int id) async {
    final url = Uri.parse('$baseUrl/userbankdetails/$id');
    try {
      final response = await http.delete(url);
      if (response.statusCode != 200) {
        throw Exception('Failed to delete bank details: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error deleting bank details: $e');
    }
  }

  Future<List<BankDetails>> getBankDetailsByUser(int userID) async {
    final response = await http.get(Uri.parse('$baseUrl/userbankdetails/user/$userID'));

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => BankDetails.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load bank details for user $userID');
    }
  }
}
