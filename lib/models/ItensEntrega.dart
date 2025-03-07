class ItensEntrega{
  int? id;
  String? item;
  String? obs;

  ItensEntrega({
    this.id,
    this.item,
    this.obs,
  });

  // Método para converter de JSON para um objeto ItensEntrega
  factory ItensEntrega.fromJson(Map<String, dynamic> json) {
    return ItensEntrega(
      id: json['id'],
      item: json['item'],
      obs: json['obs'],
    );
  }

  // Método para converter de ItensEntrega para um formato JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'item': item,
      'obs': obs,
    };
  }
}
