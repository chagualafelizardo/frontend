
class VeiculoImg {
  final int veiculoId;
  final String image;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  VeiculoImg({
    required this.veiculoId,
    required this.image,
    this.createdAt,
    this.updatedAt,
  });

  // Método para converter JSON em objeto VeiculoImg
  factory VeiculoImg.fromJson(Map<String, dynamic> json) {
    return VeiculoImg(
      veiculoId: json['veiculoId'],
      image: json['image'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  // Método para converter objeto VeiculoImg em JSON
  Map<String, dynamic> toJson() {
    return {
      'veiculoId': veiculoId,
      'image': image,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
