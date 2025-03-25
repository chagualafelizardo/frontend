import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:app/models/Veiculoimg.dart';

class VeiculoImgService {
  final String baseUrl;

  VeiculoImgService(this.baseUrl);

  // Fetch all images for a specific vehicle by its ID
  Future<List<VeiculoImg>> fetchImagesByVehicleId(int veiculoId) async {
    final response = await http.get(Uri.parse('$baseUrl/veiculoimg/$veiculoId/images'));

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((json) => VeiculoImg.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load images');
    }
  }

  Future<List<VeiculoImg>> getVeiculoImages(int veiculoId) async {
    final response = await http.get(Uri.parse('$baseUrl/veiculo/$veiculoId/images'));

    if (response.statusCode == 200) {
      // Decodifica o JSON e mapeia para uma lista de VeiculoImg
      List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((json) => VeiculoImg.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load vehicle images');
    }
  }
  
  // Add a new image to a specific vehicle
  Future<VeiculoImg> addImageToVehicle(int veiculoId, Uint8List image) async {
    final imageString = base64Encode(image); // Convertendo para Base64

    final response = await http.post(
      Uri.parse('$baseUrl/veiculoimg/$veiculoId/image'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'image': imageString, // Enviando a imagem como Base64
      }),
    );

    if (response.statusCode == 201) {
      return VeiculoImg.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to add image');
    }
  }

  // Delete an image by its ID
  Future<void> deleteImageById(int imageId) async {
    final response = await http.delete(Uri.parse('$baseUrl/images/$imageId'));

    if (response.statusCode != 200) {
      throw Exception('Failed to delete image');
    }
  }
}