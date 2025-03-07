import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:app/models/AtendimentoItem.dart';

class AtendimentoItemService {
  final String baseUrl;

  AtendimentoItemService(this.baseUrl);

  // Função para adicionar um novo item de atendimento
  Future<void> addAtendimentoItem(AtendimentoItem item) async {
    final response = await http.post(
      Uri.parse('$baseUrl/atendimentoItem'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(item.toJson()),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to add atendimento item: ${response.body}');
    }
  }

  // Função para buscar itens de atendimento por atendimentoID
  Future<List<AtendimentoItem>> fetchAtendimentoItems(int atendimentoID) async {
    final response =
        await http.get(Uri.parse('$baseUrl/atendimentoItem/$atendimentoID'));

    if (response.statusCode == 200) {
      List<dynamic> body = json.decode(response.body);
      return body
          .map((dynamic item) => AtendimentoItem.fromJson(item))
          .toList();
    } else {
      throw Exception('Failed to load atendimento items');
    }
  }
}
