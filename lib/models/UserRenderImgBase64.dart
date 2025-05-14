import 'package:app/models/Reserva.dart';
import 'package:app/models/Role.dart';

class UserBase64 {
  final int id;
  final String username;
  final String firstName;
  final String lastName;
  final String gender;
  final DateTime birthdate;
  final String email;
  final String? address;
  final String? neighborhood;
  final String? phone1;
  final String? phone2;
  final String? password;
  final String? state;
  final String? imgBase64;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<Role>? roles; // Adicione este campo

  UserBase64({
    required this.id,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.gender,
    required this.birthdate,
    required this.email,
    this.address,
    this.neighborhood,
    this.phone1,
    this.phone2,
    this.password,
    this.state,
    this.imgBase64,
    this.createdAt,
    this.updatedAt,
    this.roles, // Adicione este campo
  });

  factory UserBase64.fromJson(Map<String, dynamic> json) {
    return UserBase64(
      id: json['id'] ?? 0, // Valor padrão se o campo for nulo
      username: json['username'] ?? '', // Valor padrão se o campo for nulo
      firstName: json['firstName'] ?? '', // Valor padrão se o campo for nulo
      lastName: json['lastName'] ?? '', // Valor padrão se o campo for nulo
      gender: json['gender'] ?? '', // Valor padrão se o campo for nulo
      birthdate: json['birthdate'] != null
          ? DateTime.parse(json['birthdate'])
          : DateTime.now(), // Valor padrão se o campo for nulo
      email: json['email'] ?? '', // Valor padrão se o campo for nulo
      address: json['address'],
      neighborhood: json['neighborhood'],
      phone1: json['phone1'],
      phone2: json['phone2'],
      password: json['password'],
      state: json['state'],
      imgBase64: json['imgBase64'],
      createdAt: json.containsKey('createdAt') && json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json.containsKey('updatedAt') && json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
      roles: json['roles'] != null
          ? (json['roles'] as List).map((role) => Role.fromJson(role)).toList()
          : null, // Processa as roles
    );
  }

  // Adicione esse método:
  static UserBase64 fromUser(User user) {
    return UserBase64(
      id: user.id,
      firstName: user.firstName,
      lastName: user.lastName,
      imgBase64: user.imagemBase64, 
      username: user.username,
      gender: user.gender, 
      birthdate: user.birthdate, 
      email: user.email, // se existir
      
    );
  }

  Map<String, dynamic> toJson() {
  return {
    'id': id,
    'username': username,
    'firstName': firstName,
    'lastName': lastName,
    'gender': gender,
    'birthdate': birthdate.toIso8601String(),
    'email': email,
    'address': address,
    'neighborhood': neighborhood,
    'phone1': phone1,
    'phone2': phone2,
    'password': password,
    'state': state,
    'imgBase64': imgBase64,
    'createdAt': createdAt?.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
    'roles': roles?.map((role) => role.toJson()).toList(),
  };
}

}