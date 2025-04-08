import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/DriveDeliver.dart';

class DriveDeliverService {
  final String? baseUrl = dotenv.env['BASE_URL'];

  Future<List<DriveDeliver>> getAllDriveDelivers() async {
    final response = await http.get(Uri.parse('$baseUrl/driverdeliver'));

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => DriveDeliver.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load drive deliveries');
    }
  }

  Future<DriveDeliver> getDriveDeliverById(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/driverdeliver/$id'));

    if (response.statusCode == 200) {
      return DriveDeliver.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Drive delivery not found');
    }
  }

  Future<DriveDeliver> createDriveDeliver(DriveDeliver driveDeliver) async {
    final response = await http.post(
      Uri.parse('$baseUrl/driverdeliver'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(driveDeliver.toJson()),
    );

    if (response.statusCode == 201) {
      return DriveDeliver.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create drive delivery');
    }
  }

  Future<DriveDeliver> updateDriveDeliver(int id, DriveDeliver driveDeliver) async {
    final response = await http.put(
      Uri.parse('$baseUrl/driverdeliver/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(driveDeliver.toJson()),
    );

    if (response.statusCode == 200) {
      return DriveDeliver.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to update drive delivery');
    }
  }

  Future<void> deleteDriveDeliver(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/driverdeliver/$id'));

    if (response.statusCode != 200) {
      throw Exception('Failed to delete drive delivery');
    }
  }
}
