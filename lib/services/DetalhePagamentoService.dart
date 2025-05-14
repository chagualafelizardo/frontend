import 'dart:convert';
import 'package:app/services/DetalhesPagamento.dart';
import 'package:http/http.dart' as http;

class DetalhePagamentoService {
  final String baseUrl;

  DetalhePagamentoService(this.baseUrl);

  // Buscar todos os detalhes de pagamento
  // Future<List<DetalhePagamento>> fetchDetalhesPagamento() async {
  //   final response = await http.get(Uri.parse('$baseUrl/detalhespagamento'));

  //   if (response.statusCode == 200) {
  //     List<dynamic> jsonList = jsonDecode(response.body);
  //     return jsonList.map((json) => DetalhePagamento.fromJson(json)).toList();
  //   } else {
  //     throw Exception('Failed to load detalhes pagamento');
  //   }
  // }

  Future<List<DetalhePagamento>> fetchDetalhesPagamento({required int pagamentoId}) async {
      final response = await http.get(
        Uri.parse('$baseUrl/detalhespagamento?pagamentoId=$pagamentoId'),
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => DetalhePagamento.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load payment details');
      }
    }


  // Buscar um detalhe de pagamento por ID
  Future<DetalhePagamento> fetchDetalhePagamentoById(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/detalhespagamento/$id'));

    if (response.statusCode == 200) {
      return DetalhePagamento.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load detalhe pagamento with id $id');
    }
  }

  // Criar um novo detalhe de pagamento
  Future<DetalhePagamento> createDetalhePagamento(DetalhePagamento detalhe) async {
    final response = await http.post(
      Uri.parse('$baseUrl/detalhespagamento'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(detalhe.toJson()),
    );

    if (response.statusCode == 201) {
      return DetalhePagamento.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create detalhe pagamento');
    }
  }

  // Atualizar um detalhe de pagamento existente
  Future<DetalhePagamento> updateDetalhePagamento(int id, DetalhePagamento detalhe) async {
    final response = await http.put(
      Uri.parse('$baseUrl/detalhespagamento/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(detalhe.toJson()),
    );

    if (response.statusCode == 200) {
      return DetalhePagamento.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to update detalhe pagamento with id $id');
    }
  }

  // Excluir um detalhe de pagamento
  Future<void> deleteDetalhePagamento(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/detalhespagamento/$id'));

    if (response.statusCode != 204) {
      throw Exception('Failed to delete detalhe pagamento with id $id');
    }
  }
}