import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:app/models/Item.dart';

class ItemService {
  final String baseUrl;

  ItemService(this.baseUrl);

  // Função para buscar uma lista de itens
  Future<List<Item>> fetchItems(int currentPage, int itemsPerPage) async {
    final response = await http.get(Uri.parse('$baseUrl/item'));
    if (response.statusCode == 200) {
      List<dynamic> body = json.decode(response.body);
      return body.map((dynamic item) => Item.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load items');
    }
  }

  // Função para adicionar um novo item
  Future<void> addItem(Item item) async {
    final response = await http.post(
      Uri.parse('$baseUrl/item'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(item.toJson()),
    );
    if (response.statusCode != 201) {
      throw Exception('Failed to add item');
    }
  }

  // Função para atualizar um item existente
  Future<void> updateItem(Item item) async {
    final response = await http.put(
      Uri.parse('$baseUrl/item/${item.item}'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(item.toJson()),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update item');
    }
  }

  // Função para deletar um item
  Future<void> deleteItem(String itemName) async {
    final response = await http.delete(Uri.parse('$baseUrl/item/$itemName'));
    if (response.statusCode != 204) {
      throw Exception('Failed to delete item');
    }
  }
}
