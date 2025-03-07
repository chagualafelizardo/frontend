class AtendimentoItem {
  final int atendimentoID;
  final String itemDescription;

  AtendimentoItem({required this.atendimentoID, required this.itemDescription});

  // Converter de JSON para objeto
  factory AtendimentoItem.fromJson(Map<String, dynamic> json) {
    return AtendimentoItem(
      atendimentoID: json['atendimentoID'],
      itemDescription: json['itemDescription'],
    );
  }

  // Converter objeto para JSON
  Map<String, dynamic> toJson() {
    return {
      'atendimentoID': atendimentoID,
      'itemDescription': itemDescription,
    };
  }
}
