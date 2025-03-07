import 'dart:convert';
import 'package:app/models/PaymentCriteria.dart';
import 'package:http/http.dart' as http;

class PaymentCriteriaService {
  final String baseUrl;

  PaymentCriteriaService({required this.baseUrl});

  Future<List<PaymentCriteria>> getAllPaymentCriteria() async {
  final response = await http.get(Uri.parse('$baseUrl/paymentcriteria'));
  if (response.statusCode == 200) {
    final json = jsonDecode(response.body);

    // Acessar a lista dentro da chave "data"
    final List<dynamic> data = json['data']; // Use a chave correta conforme a resposta da API

    return data.map((item) => PaymentCriteria.fromJson(item)).toList();
  } else {
    throw Exception('Failed to load payment criteria');
  }
}


  // Obter um critério de pagamento pelo ID
  Future<PaymentCriteria> getPaymentCriteriaById(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/paymentcriteria/$id'));

    if (response.statusCode == 200) {
      return PaymentCriteria.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to fetch payment criteria with ID $id');
    }
  }

  // Criar um novo critério de pagamento
  Future<void> createPaymentCriteria(PaymentCriteria paymentCriteria) async {
    final response = await http.post(
      Uri.parse('$baseUrl/paymentcriteria'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(paymentCriteria.toJson()),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to create payment criteria');
    }
  }

  // Atualizar um critério de pagamento
  Future<void> updatePaymentCriteria(PaymentCriteria paymentCriteria) async {
    final response = await http.put(
      Uri.parse('$baseUrl/paymentcriteria/${paymentCriteria.id}'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(paymentCriteria.toJson()),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update payment criteria');
    }
  }

  // Excluir um critério de pagamento pelo ID
  Future<void> deletePaymentCriteria(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/paymentcriteria/$id'));

    if (response.statusCode != 200) {
      throw Exception('Failed to delete payment criteria');
    }
  }
}
