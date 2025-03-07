import 'dart:convert';
import 'package:app/models/PagamentoList.dart';
import 'package:http/http.dart' as http;
import 'package:app/models/Pagamento.dart';

class PagamentoService {
  final String baseUrl;

  PagamentoService(this.baseUrl);

  // Método para buscar todos os pagamentos
  Future<List<PagamentoList>> fetchPagamentos() async {
    final response = await http.get(Uri.parse('$baseUrl/pagamento'));

    if (response.statusCode == 200) {
      List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((json) => PagamentoList.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load pagamentos');
    }
  }

  // Método para buscar um pagamento por ID
  Future<Pagamento> fetchPagamentoById(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/pagamento/$id'));

    if (response.statusCode == 200) {
      return Pagamento.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load pagamento with id $id');
    }
  }

  // Método para criar um novo pagamento
  // Future<Pagamento> createPagamento(Pagamento pagamento) async {
  //   final response = await http.post(
  //     Uri.parse('$baseUrl/pagamento'),
  //     headers: {'Content-Type': 'application/json'},
  //     body: jsonEncode(pagamento.toJson()),
  //   );

  //   if (response.statusCode == 201) {
  //     return Pagamento.fromJson(jsonDecode(response.body));
  //   } else {
  //     throw Exception('Failed to create pagamento');
  //   }
  // }

Future<Pagamento> createPagamento(Pagamento pagamento) async {
  final response = await http.post(
    Uri.parse('$baseUrl/pagamento'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(pagamento.toJson()), // Usa o toJson ajustado
  );

  if (response.statusCode == 201) {
    return Pagamento.fromJson(jsonDecode(response.body)); // Usa o fromJson ajustado
  } else {
    throw Exception('Failed to create pagamento');
  }
}

  // Método para atualizar um pagamento existente
  Future<Pagamento> updatePagamento(int id, Pagamento pagamento) async {
    final response = await http.put(
      Uri.parse('$baseUrl/pagamento/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(pagamento.toJson()),
    );

    if (response.statusCode == 200) {
      return Pagamento.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to update pagamento with id $id');
    }
  }

  // Método para excluir um pagamento
  Future<void> deletePagamento(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/pagamento/$id'));

    if (response.statusCode != 204) {
      throw Exception('Failed to delete pagamento with id $id');
    }
  }
}