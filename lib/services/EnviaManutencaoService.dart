import 'dart:convert';
import 'package:app/models/EnviaManutencao.dart';
import 'package:http/http.dart' as http;

class EnviaManutencaoService {
  final String baseUrl;

  EnviaManutencaoService(this.baseUrl);

  Future<EnviaManutencao> createEnviaManutencao(EnviaManutencao manutencao) async {
    try {
      // Log do corpo da requisição
      print('Enviando requisição para o backend...');
      print('Corpo da requisição: ${jsonEncode(manutencao.toJson())}');

      final response = await http.post(
        Uri.parse('$baseUrl/manutencao/enviamanutecao'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(manutencao.toJson()),
      );

      // Log da resposta do backend
      print('Resposta do backend:');
      print('Status Code: ${response.statusCode}');
      print('Corpo da resposta: ${response.body}');

      if (response.statusCode == 201) {
        return EnviaManutencao.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to create manutencao. Status Code: ${response.statusCode}');
      }
    } catch (e) {
      // Log de erro
      print('Erro ao enviar requisição: $e');
      rethrow; // Rejoga o erro para ser tratado no chamador
    }
  }
}