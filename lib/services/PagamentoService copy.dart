import 'dart:convert';
import 'dart:io';
import 'package:app/models/PagamentoList.dart';
import 'package:http/http.dart' as http;
import 'package:app/models/Pagamento.dart';

class PagamentoService {
  final String baseUrl;

  PagamentoService(this.baseUrl);

  // Método para buscar todos os pagamentos
Future<List<PagamentoList>> fetchPagamentos() async {
    try {
      print('🟡 [PagamentoService] Iniciando fetchPagamentos...');
      print('🔵 [PagamentoService] URL: $baseUrl/pagamento');

      final response = await http.get(
        Uri.parse('$baseUrl/pagamento'),
        headers: {'Content-Type': 'application/json'},
      );

      print('🟢 [PagamentoService] Resposta recebida. Status: ${response.statusCode}');
      print('🔵 [PagamentoService] Corpo da resposta: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print('🟢 [PagamentoService] Dados decodificados: $data');

        final pagamentos = data.map((json) {
          try {
            print('🔵 [PagamentoService] Convertendo JSON: $json');
            final pagamento = PagamentoList.fromJson(json);
            print('🟢 [PagamentoService] Conversão bem-sucedida: ${pagamento.id}');
            return pagamento;
          } catch (e, stackTrace) {
            print('🔴 [PagamentoService] Erro ao converter JSON: $e');
            print('🔴 StackTrace: $stackTrace');
            print('🔴 JSON problemático: $json');
            throw FormatException('Failed to convert pagamento JSON: $e');
          }
        }).toList();

        print('🟢 [PagamentoService] Total de pagamentos carregados: ${pagamentos.length}');
        return pagamentos;
      } else {
        print('🔴 [PagamentoService] Erro na resposta: ${response.statusCode}');
        throw HttpException('Failed to load pagamentos. Status: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      print('🔴 [PagamentoService] Erro durante fetchPagamentos: $e');
      print('🔴 StackTrace: $stackTrace');
      rethrow;
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

  Future<List<Object>> fetchPagamentosPorAtendimentoId(int atendimentoId) async {
    try {
      final todosPagamentos = await fetchPagamentos();
      return todosPagamentos.where((p) => p.atendimentoId == atendimentoId).toList();
    } catch (e) {
      print('Erro ao buscar pagamentos por atendimentoId: $e');
      return [];
    }
  }
  // Método para excluir um pagamento
  // Future<void> deletePagamento(int id) async {
  //   final response = await http.delete(Uri.parse('$baseUrl/pagamento/$id'));

  //   if (response.statusCode != 204) {
  //     throw Exception('Failed to delete pagamento with id $id');
  //   }
  // }

  // No PagamentoService, atualize o método deletePagamento para:
  Future<void> deletePagamento(int id) async {
    try {
      print('🟡 [PagamentoService] Iniciando deletePagamento para ID: $id');
      print('🔵 [PagamentoService] URL: $baseUrl/pagamento/$id');

      final response = await http.delete(
        Uri.parse('$baseUrl/pagamento/$id'),
        headers: {'Content-Type': 'application/json'},
      );

      print('🟢 [PagamentoService] Resposta recebida. Status: ${response.statusCode}');

      if (response.statusCode == 204) {
        print('🟢 [PagamentoService] Pagamento com ID $id deletado com sucesso');
        return;
      } else {
        print('🔴 [PagamentoService] Erro na resposta: ${response.statusCode}');
        print('🔴 [PagamentoService] Corpo da resposta: ${response.body}');
        throw HttpException('Failed to delete pagamento. Status: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      print('🔴 [PagamentoService] Erro durante deletePagamento: $e');
      print('🔴 StackTrace: $stackTrace');
      rethrow;
    }
  }
}