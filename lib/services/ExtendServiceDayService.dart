import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:app/models/ExtendServiceDay.dart';

class ExtendServiceDayService {
  final String baseUrl;

  ExtendServiceDayService(this.baseUrl);

  Future<List<ExtendServiceDay>> fetchAll() async {
    final response = await http.get(Uri.parse('$baseUrl/extendserviceday'));

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => ExtendServiceDay.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load extended service days');
    }
  }

  Future<ExtendServiceDay> fetchById(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/extendserviceday/$id'));

    if (response.statusCode == 200) {
      return ExtendServiceDay.fromJson(json.decode(response.body));
    } else if (response.statusCode == 404) {
      throw Exception('Extended service day not found');
    } else {
      throw Exception('Failed to load extended service day');
    }
  }

  Future<List<ExtendServiceDay>> fetchByAtendimentoId(int atendimentoId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/extendserviceday/atendimento/$atendimentoId'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => ExtendServiceDay.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load extended service days by atendimento');
    }
  }

  Future<ExtendServiceDay> create(ExtendServiceDay extendServiceDay) async {
    final response = await http.post(
      Uri.parse('$baseUrl/extendserviceday'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(extendServiceDay.toJson()),
    );

    if (response.statusCode == 201) {
      return ExtendServiceDay.fromJson(json.decode(response.body));
    } else if (response.statusCode == 400) {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Validation error');
    } else {
      throw Exception('Failed to create extended service day');
    }
  }

  Future<ExtendServiceDay> update(ExtendServiceDay extendServiceDay) async {
    if (extendServiceDay.id == null) {
      throw Exception('ID cannot be null for update');
    }

    final response = await http.put(
      Uri.parse('$baseUrl/extendserviceday/${extendServiceDay.id}'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(extendServiceDay.toJson()),
    );

    if (response.statusCode == 200) {
      return ExtendServiceDay.fromJson(json.decode(response.body));
    } else if (response.statusCode == 400) {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Validation error');
    } else if (response.statusCode == 404) {
      throw Exception('Extended service day not found');
    } else {
      throw Exception('Failed to update extended service day');
    }
  }

  Future<void> delete(int id) async {
    debugPrint('Sending DELETE request for extension ID: $id');
    final response = await http.delete(
      Uri.parse('$baseUrl/extendserviceday/$id'),
    );

    debugPrint('Delete response status: ${response.statusCode}');
    debugPrint('Delete response body: ${response.body}');

    if (response.statusCode == 204) {
      debugPrint('Extension deleted successfully on server');
    } else {
      debugPrint('Failed to delete extension. Status code: ${response.statusCode}');
      throw Exception('Failed to delete extended service day. Server responded with status: ${response.statusCode}');
    }
  }
}