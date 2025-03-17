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
      print('Response body: $body'); // Adicione este print para ver o JSON retornado
      return body.map((json) => VeiculoImg.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load images');
    }
  }

  // Add a new image to a specific vehicle
 Future<VeiculoImg> addImageToVehicle(int veiculoId, Uint8List image) async {
  final imageString = base64Encode(image); // Convertendo para String base64

  final response = await http.post(
    Uri.parse('$baseUrl/veiculoimg/$veiculoId/image'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'image': imageString, // Enviando a imagem como uma string base64
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
