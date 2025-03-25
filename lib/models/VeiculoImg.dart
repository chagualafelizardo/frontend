import 'dart:convert';
import 'dart:typed_data';

class VeiculoImg {
  final int veiculoId;
  final String imageBase64; // Alterado para Base64
  final DateTime? createdAt;
  final DateTime? updatedAt;

  VeiculoImg({
    required this.veiculoId,
    required this.imageBase64, // Alterado para Base64
    this.createdAt,
    this.updatedAt,
  });

  // Método para converter JSON em objeto VeiculoImg
factory VeiculoImg.fromJson(Map<String, dynamic> json) {
  return VeiculoImg(
    veiculoId: json['veiculoId'],
    imageBase64: json['image'] is Map
        ? (json['image']['data'] != null
            ? base64Encode(Uint8List.fromList(json['image']['data'].cast<int>()))
            : '')
        : json['image'] ?? '', // Se 'image' for uma string Base64
    createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
    updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
  );
}
}