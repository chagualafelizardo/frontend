class User {
  final int id;
  final String username;
  final String? firstName;
  final String? lastName;
  final String? gender;
  final String? birthdate;
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
  final List<Role>? roles;

  User({
    required this.id,
    required this.username,
    this.firstName,
    this.lastName,
    this.gender,
    this.birthdate,
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
    this.roles,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      firstName: json['firstName'],
      lastName: json['lastName'],
      gender: json['gender'],
      birthdate: json['birthdate'],
      email: json['email'] ?? '',
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
      roles: (json['roles'] as List<dynamic>?)
          ?.map((role) => Role.fromJson(role))
          .toList(),
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
      'imgBase64': imgBase64,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'roles': roles?.map((role) => role.toJson()).toList(),
    };
  }
}

class Role {
  final int id;
  final String name;

  Role({
    required this.id,
    required this.name,
  });

  factory Role.fromJson(Map<String, dynamic> json) {
    return Role(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}