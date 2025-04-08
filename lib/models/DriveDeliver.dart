class DriveDeliver {
  final int? id;
  final DateTime? date;
  final String? deliver;
  final double? pickupLatitude;
  final double? pickupLongitude;
  final double? dropoffLatitude;
  final double? dropoffLongitude;
  final String? locationDescription;
  final int? reservaID;

  DriveDeliver({
    this.id,
    this.date,
    this.deliver,
    this.pickupLatitude,
    this.pickupLongitude,
    this.dropoffLatitude,
    this.dropoffLongitude,
    this.locationDescription,
    this.reservaID,
  });

  factory DriveDeliver.fromJson(Map<String, dynamic> json) {
    return DriveDeliver(
      id: json['id'],
      date: json['date'] != null ? DateTime.parse(json['date']) : null,
      deliver: json['deliver'],
      pickupLatitude: json['pickupLatitude']?.toDouble(),
      pickupLongitude: json['pickupLongitude']?.toDouble(),
      dropoffLatitude: json['dropoffLatitude']?.toDouble(),
      dropoffLongitude: json['dropoffLongitude']?.toDouble(),
      locationDescription: json['locationDescription'],
      reservaID: json['reservaID'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date?.toIso8601String(),
      'deliver': deliver,
      'pickupLatitude': pickupLatitude,
      'pickupLongitude': pickupLongitude,
      'dropoffLatitude': dropoffLatitude,
      'dropoffLongitude': dropoffLongitude,
      'locationDescription': locationDescription,
      'reservaID': reservaID,
    };
  }
}
