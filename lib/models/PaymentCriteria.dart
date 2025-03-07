class PaymentCriteria {
    final int? id;
    final String activity;
    final String paymentType; // 'Alojamento' ou 'PERDIEM'
    final String paymentMethod; // 'cash', 'transfer' ou 'mobile_money'
    final String paymentPeriod; // 'daily', 'weekly', 'monthly', ou 'yearly'
    final double amount;
  
    PaymentCriteria({
      this.id,
      required this.activity,
      required this.paymentType,
      required this.paymentMethod,
      required this.paymentPeriod,
      required this.amount,
    });
  
    // Método para converter de JSON para um objeto PaymentCriteria
    factory PaymentCriteria.fromJson(Map<String, dynamic> json) {
      return PaymentCriteria(
        id: json['id'],
        activity: json['activity'],
        paymentType: json['paymentType'],
        paymentMethod: json['paymentMethod'],
        paymentPeriod: json['paymentPeriod'],
        amount: json['amount'].toDouble(),
      );
    }
  
    // Método para converter um objeto PaymentCriteria para JSON
    Map<String, dynamic> toJson() {
      return {
        'id': id,
        'activity': activity,
        'paymentType': paymentType,
        'paymentMethod': paymentMethod,
        'paymentPeriod': paymentPeriod,
        'amount': amount,
      };
    }
  }
  