enum ReservaState {
  notConfirmed,
  confirmed,
}

class Reserva {
  // Informações da reserva
  int id;
  DateTime date;
  String destination;
  int numberOfDays;
  String state;
  String inService; // ✅ Novo campo

  // Informações do usuário
  int userId; // Adicione o campo userId
  int clientId; // Adicione o campo userId
  User user;

  // Informações do veículo
  Veiculo veiculo;

  Reserva({
    required this.id,
    required this.date,
    required this.destination,
    required this.numberOfDays,
    required this.inService, // ✅ Adicione no construtor
    required this.state,
    required this.userId, // Adicione o campo userId no construtor
    required this.clientId, // Adicione o campo userId no construtor
    required this.user,
    required this.veiculo,
  });

  String get stateString {
    switch (state) {
      case 'Not Confirmed':
        return 'Not Confirmed';
      case 'Confirmed':
        return 'Confirmed';
      default:
        // Retorna um valor padrão para evitar que o método não retorne nada
        return 'Unknown State';
    }
  }

  static ReservaState stateFromString(String state) {
    switch (state) {
      case 'Confirmed':
        return ReservaState.confirmed;
      case 'Not Confirmed':
      default:
        return ReservaState.notConfirmed;
    }
  }

  // Converte um objeto Reserva em JSON
  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'destination': destination,
        'number_of_days': numberOfDays,
        'inService': inService, // ✅ Novo campo no JSON
        'state': state,
        'userID': userId, // Adicione o campo userId no JSON
        'clientID': clientId, // Adicione o campo userId no JSON
        'user': user.toJson(),
        'veiculo': veiculo.toJson(),
      };

  // Converte um JSON em um objeto Reserva
  factory Reserva.fromJson(Map<String, dynamic> json) {
    return Reserva(
      id: json['id'] ?? 0,
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      destination: json['destination'] ?? '',
      numberOfDays: json['number_of_days'] ?? 0,
      inService: json['inService'] ?? 'No', // ✅ Novo campo
      state: json['state'] ?? '',
      userId: json['userID'] ?? 0, // Adicione o campo userId no fromJson
      clientId: json['clientID'] ?? 0, // Adicione o campo userId no fromJson
      user: User.fromJson(json['user'] ?? {}),
      veiculo: Veiculo.fromJson(json['veiculo'] ?? {}),
    );
  }
}

// Classe User com campo de imagem
class User {
  int id;
  String username;
  String firstName;
  String lastName;
  String gender;
  DateTime birthdate;
  String address;
  String neighborhood;
  String email;
  String phone1;
  String phone2;
  String password;
  String state;
  String? imagemBase64;

  User({
    required this.id,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.gender,
    required this.birthdate,
    required this.address,
    required this.neighborhood,
    required this.email,
    required this.phone1,
    required this.phone2,
    required this.password,
    required this.state,
    this.imagemBase64,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'firstName': firstName,
    'lastName': lastName,
    'gender': gender,
    'birthdate': birthdate.toIso8601String(),
    'address': address,
    'neighborhood': neighborhood,
    'email': email,
    'phone1': phone1,
    'phone2': phone2,
    'password': password,
    'state': state,
    'img': imagemBase64,
  };

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'] ?? 0,
    username: json['username'] ?? '',
    firstName: json['firstName'] ?? '',
    lastName: json['lastName'] ?? '',
    gender: json['gender'] ?? '',
    birthdate: DateTime.parse(json['birthdate'] ?? DateTime.now().toIso8601String()),
    address: json['address'] ?? '',
    neighborhood: json['neighborhood'] ?? '',
    email: json['email'] ?? '',
    phone1: json['phone1'] ?? '',
    phone2: json['phone2'] ?? '',
    password: json['password'] ?? '',
    state: json['state'] ?? '',
    imagemBase64: json['img'],
  );


  toLowerCase() {}
}

// Classe Veiculo com campo de imagem
class Veiculo {
  int id;
  String matricula;
  String marca;
  String modelo;
  int ano;
  String cor;
  String numChassi;
  int numLugares;
  String numMotor;
  int numPortas;
  String tipoCombustivel;
  String? imagemBase64; // Campo opcional para imagem

  Veiculo({
    required this.id,
    required this.matricula,
    required this.marca,
    required this.modelo,
    required this.ano,
    required this.cor,
    required this.numChassi,
    required this.numLugares,
    required this.numMotor,
    required this.numPortas,
    required this.tipoCombustivel,
    this.imagemBase64, // Adicione o novo campo ao construtor
  });

  // Converte um objeto Veiculo em JSON
  Map<String, dynamic> toJson() => {
        'id': id,
        'matricula': matricula,
        'marca': marca,
        'modelo': modelo,
        'ano': ano,
        'cor': cor,
        'num_chassi': numChassi,
        'num_lugares': numLugares,
        'num_motor': numMotor,
        'num_portas': numPortas,
        'tipo_combustivel': tipoCombustivel,
        'image': imagemBase64, // Adicione o novo campo ao JSON
      };

  // Converte um JSON em um objeto Veiculo
  factory Veiculo.fromJson(Map<String, dynamic> json) => Veiculo(
        id: json['id'] ?? 0,
        matricula: json['matricula'] ?? '',
        marca: json['marca'] ?? '',
        modelo: json['modelo'] ?? '',
        ano: json['ano'] ?? 0,
        cor: json['cor'] ?? '',
        numChassi: json['num_chassi'] ?? '',
        numLugares: json['num_lugares'] ?? 0,
        numMotor: json['num_motor'] ?? '',
        numPortas: json['num_portas'] ?? 0,
        tipoCombustivel: json['tipo_combustivel'] ?? '',
        imagemBase64: json['image'],
      );

  get state => null;
}
