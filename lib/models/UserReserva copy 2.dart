class User {
  final int id;
  final String username;
  final String? firstName;
  final String? lastName;
  final String? gender;
  final String birthdate;
  final String email;
  final String? address;
  final String? neighborhood;
  final String? phone1;
  final String? phone2;
  final String password;
  final String state;
  final String? imgBase64; // Alterado para imgBase64
  final DateTime? createdAt;
  final DateTime? updatedAt;

  User({
    required this.id,
    required this.username,
    this.firstName,
    this.lastName,
    this.gender,
    required this.birthdate,
    required this.email,
    this.address,
    this.neighborhood,
    this.phone1,
    this.phone2,
    required this.password,
    required this.state,
    this.imgBase64, // Alterado para imgBase64
    this.createdAt,
    this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      gender: json['gender'],
      birthdate: json['birthdate'],
      email: json['email'],
      address: json['address'],
      neighborhood: json['neighborhood'],
      phone1: json['phone1'],
      phone2: json['phone2'],
      password: json['password'],
      state: json['state'],
      imgBase64: json['imgBase64'], // Corrigido para imgBase64
      createdAt: json.containsKey('createdAt')
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json.containsKey('updatedAt')
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'firstName': firstName,
      'lastName': lastName,
      'gender': gender,
      'birthdate': birthdate,
      'email': email,
      'address': address,
      'neighborhood': neighborhood,
      'phone1': phone1,
      'phone2': phone2,
      'password': password,
      'state': state,
      'imgBase64': imgBase64, // Corrigido para imgBase64
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
