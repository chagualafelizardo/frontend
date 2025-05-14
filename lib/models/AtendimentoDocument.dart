import 'dart:typed_data';

class AtendimentoDocument {
  int? id; // ID do documento
  String? itemDescription; // Descrição do item
  Uint8List? image; // Imagem em formato binário
  int? atendimentoID; // ID do atendimento associado

  AtendimentoDocument({
    this.id,
    this.itemDescription,
    this.image,
    this.atendimentoID,
  });

  // Cria o objeto a partir de um JSON
  factory AtendimentoDocument.fromJson(Map<String, dynamic> json) {
    return AtendimentoDocument(
      id: json['id'] as int?,
      itemDescription: json['itemDescription'] as String?,
      image: json['image'] != null && json['image']['data'] != null
          ? Uint8List.fromList(List<int>.from(json['image']['data']))
          : null,
      atendimentoID: json['atendimentoID'] as int?,
    );
  }

  // Converte o objeto para JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'itemDescription': itemDescription,
      'image': image != null ? image!.toList() : null, // ou usar base64Encode(image!)
      'atendimentoID': atendimentoID,
    };
  }
}
