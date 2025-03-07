import 'package:app/models/Manutencao.dart';

class DetalhesManutencao {
  int? id;
  String item;
  String? obs;
  int manutencaoID;
  Manutencao? manutencao; // Referência ao modelo Manutencao (opcional)

  DetalhesManutencao({
    this.id,
    required this.item,
    this.obs,
    required this.manutencaoID,
    this.manutencao,
  });

  factory DetalhesManutencao.fromJson(Map<String, dynamic> json) {
    return DetalhesManutencao(
      id: json['id'],
      item: json['item'],
      obs: json['obs'],
      manutencaoID: json['manutencaoID'],
      manutencao: json['manutencao'] != null ? Manutencao.fromJson(json['manutencao']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'item': item,
      'obs': obs,
      'manutencaoID': manutencaoID,
      'manutencao': manutencao?.toJson(),
    };
  }
}