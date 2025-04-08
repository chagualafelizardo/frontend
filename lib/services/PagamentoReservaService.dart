import 'dart:convert';
import 'package:app/models/PagamentoReserva.dart';
import 'package:app/models/User.dart' as user_model; // Adicione prefixo
import 'package:app/models/Reserva.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class PagamentoReservaService {
  final String? baseUrl = dotenv.env['BASE_URL'];

  Future<PagamentoReserva> createPagamentoReserva(PagamentoReserva pagamento) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/pagamentoreserva'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(pagamento.toJson()),
      );

      if (response.statusCode == 201) {
        return PagamentoReserva.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to create payment: ${response.statusCode}');
      }
    } catch (error) {
      throw Exception('Error creating payment: $error');
    }
  }

  Future<List<PagamentoReserva>> fetchAllPagamentosReservas() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/pagamentoreserva'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonResponse = json.decode(response.body);
        return jsonResponse.map((json) => PagamentoReserva.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load all payments: ${response.statusCode}');
      }
    } catch (error) {
      throw Exception('Error loading all payments: $error');
    }
  }

  Future<List<PagamentoReserva>> fetchPagamentosByReserva(int reservaId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/pagamentoreserva/reserva/$reservaId'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonResponse = json.decode(response.body);
        return jsonResponse.map((json) => PagamentoReserva.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load payments: ${response.statusCode}');
      }
    } catch (error) {
      throw Exception('Error loading payments: $error');
    }
  }

  Future<List<PagamentoReserva>> fetchPagamentosByUser(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/pagamentoreserva/user/$userId'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonResponse = json.decode(response.body);
        return jsonResponse.map((json) => PagamentoReserva.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load user payments: ${response.statusCode}');
      }
    } catch (error) {
      throw Exception('Error loading user payments: $error');
    }
  }

  Future<PagamentoReserva> getPagamentoById(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/pagamentoreserva/$id'),
      );

      if (response.statusCode == 200) {
        return PagamentoReserva.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to load payment: ${response.statusCode}');
      }
    } catch (error) {
      throw Exception('Error loading payment: $error');
    }
  }

  Future<void> deletePagamento(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/pagamentoreserva/$id'),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete payment: ${response.statusCode}');
      }
    } catch (error) {
      throw Exception('Error deleting payment: $error');
    }
  }

  Future<Map<String, dynamic>> fetchPagamentoDetails(int pagamentoId) async {
    try {
      // Buscar detalhes do pagamento
      final responsePagamento = await http.get(
        Uri.parse('$baseUrl/pagamentoreserva/$pagamentoId'),
      );

      if (responsePagamento.statusCode == 200) {
        final Map<String, dynamic> pagamentoData = jsonDecode(responsePagamento.body);

        // Buscar informações do usuário
        final user_model.User user = await _fetchUserDetails(pagamentoData['userId']); // Usando o prefixo

        // Buscar informações da reserva
        final Reserva reserva = await _fetchReservaDetails(pagamentoData['reservaId']);

        return {
          'pagamento': pagamentoData,
          'user': user.toJson(),
          'reserva': reserva.toJson(),
        };
      } else {
        throw Exception('Failed to fetch payment details: ${responsePagamento.statusCode}');
      }
    } catch (error) {
      throw Exception('Error fetching payment details: $error');
    }
  }

  Future<user_model.User> _fetchUserDetails(int userId) async { // Usando o prefixo
    final response = await http.get(
      Uri.parse('$baseUrl/users/$userId'),
    );

    if (response.statusCode == 200) {
      return user_model.User.fromJson(jsonDecode(response.body)); // Usando o prefixo
    } else {
      throw Exception('Failed to fetch user details');
    }
  }

  Future<Reserva> _fetchReservaDetails(int reservaId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/reservas/$reservaId'),
    );

    if (response.statusCode == 200) {
      return Reserva.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to fetch reservation details');
    }
  }
}