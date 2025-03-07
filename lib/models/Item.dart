class Item {
  int? id;
  String? item;
  String? obs;
  bool selected; // Adicione este campo

  // Construtor
  Item({this.id, this.item, this.obs, this.selected = false}); // Inicialize como false

  // Método para criar um objeto a partir de um JSON
  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['id'] as int?,
      item: json['item'] as String?,
      obs: json['obs'] as String?,
      selected: json['selected'] ?? false, // Inicialize como false se não estiver presente
    );
  }

  // Método para converter o objeto em um JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'item': item,
      'obs': obs,
      'selected': selected, // Inclua o campo selected
    };
  }
}