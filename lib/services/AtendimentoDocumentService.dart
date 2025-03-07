import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:app/models/AtendimentoDocument.dart';

class AtendimentoDocumentService {
  final String baseUrl;

  AtendimentoDocumentService(this.baseUrl);

  // Função para buscar uma lista de documentos de atendimento
  Future<List<AtendimentoDocument>> fetchAtendimentoDocuments(
      int atendimentoID) async {
    final response = await http
        .get(Uri.parse('$baseUrl/atendimentoDocument/$atendimentoID'));
    if (response.statusCode == 200) {
      List<dynamic> body = json.decode(response.body);
      return body
          .map((dynamic doc) => AtendimentoDocument.fromJson(doc))
          .toList();
    } else {
      throw Exception('Failed to load atendimento documents');
    }
  }

  // Função para adicionar um novo documento de atendimento
  Future<void> addAtendimentoDocument(AtendimentoDocument document) async {
    final response = await http.post(
      Uri.parse('$baseUrl/atendimentoDocument'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(document.toJson()),
    );
    if (response.statusCode != 201) {
      throw Exception('Failed to add atendimento document');
    }
  }

  // Função para atualizar um documento de atendimento existente
  Future<void> updateAtendimentoDocument(AtendimentoDocument document) async {
    final response = await http.put(
      Uri.parse('$baseUrl/atendimentoDocument/${document.id}'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(document.toJson()),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update atendimento document');
    }
  }

  // Função para deletar um documento de atendimento
  Future<void> deleteAtendimentoDocument(int documentId) async {
    final response = await http
        .delete(Uri.parse('$baseUrl/atendimentoDocument/$documentId'));
    if (response.statusCode != 204) {
      throw Exception('Failed to delete atendimento document');
    }
  }
}
