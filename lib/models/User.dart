
class User {
  final int id;
  final String username;
  final String? firstName;
  final String? lastName;
  final String? gender;
  final String birthdate; // Alterado para String
  final String email;
  final String? address;
  final String? neighborhood;
  final String? phone1;
  final String? phone2;
  final String password;
  final String state;
  final String? img;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  User({
    required this.id,
    required this.username,
    this.firstName,
    this.lastName,
    this.gender,
    required this.birthdate, // Alterado para String
    required this.email,
    this.address,
    this.neighborhood,
    this.phone1,
    this.phone2,
    required this.password,
    required this.state,
    this.img,
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
      birthdate: json['birthdate'], // Mantém como String
      email: json['email'],
      address: json['address'],
      neighborhood: json['neighborhood'],
      phone1: json['phone1'],
      phone2: json['phone2'],
      password: json['password'],
      state: json['state'],
      img: json['img'],
      createdAt: json.containsKey('createdAt')
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json.containsKey('updatedAt')
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

// factory User.fromJson(Map<String, dynamic> json) {
//     return User(
//       id: json['id'] as int,
//       username: json['username'] as String,
//       firstName: json['firstName'] as String?,
//       lastName: json['lastName'] as String?,
//       gender: json['gender'] as String?,
//       birthdate: json['birthdate'], 
//       email: json['email'] as String,
//       address: json['address'] as String?,
//       neighborhood: json['neighborhood'] as String?,
//       phone1: json['phone1'] as String?,
//       phone2: json['phone2'] as String?,
//       password: json['password'] as String,
//       state: json['state'] as String,
//       img: json['img']?.toString(), // Garante que img seja String
//       createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
//       updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt']) : null,
//     );
// }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'firstName': firstName,
      'lastName': lastName,
      'gender': gender,
      'birthdate': birthdate, // Mantém como String
      'email': email,
      'address': address,
      'neighborhood': neighborhood,
      'phone1': phone1,
      'phone2': phone2,
      'password': password,
      'state': state,
      'img': img,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
