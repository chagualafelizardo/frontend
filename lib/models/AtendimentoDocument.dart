import 'dart:typed_data';

class AtendimentoDocument {
  int? id; // ID do documento
  String? itemDescription; // Descrição do item
  Uint8List? image; // Imagem em formato binário
  int? atendimentoID; // ID do atendimento associado

  // Construtor
  AtendimentoDocument(
      {this.id, this.itemDescription, this.image, this.atendimentoID});

  // Método para criar um objeto a partir de um JSON
  factory AtendimentoDocument.fromJson(Map<String, dynamic> json) {
    return AtendimentoDocument(
      id: json['id'] as int?,
      itemDescription: json['itemDescription'] as String?,
      image: json['image'] != null
          ? json['image'] as Uint8List
          : null, // Certifique-se de tratar a imagem
      atendimentoID: json['atendimentoID'] as int?,
    );
  }

  // Método para converter o objeto em um JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'itemDescription': itemDescription,
      'image':
          image, // Você pode precisar converter a imagem se não estiver em Uint8List
      'atendimentoID': atendimentoID,
    };
  }
}
