import 'dart:convert';
import 'dart:typed_data';
import 'package:app/models/UserReserva.dart' as user_models;
import 'package:app/services/ReservaService.dart';
import 'package:app/services/UserServiceReserva.dart';
import 'package:app/services/VeiculoService.dart';
import 'package:app/models/Veiculo.dart' as veiculo_models;
import 'package:image/image.dart' as img;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import 'package:app/services/RoleService.dart';
import 'package:app/models/Role.dart';
import 'package:app/services/UserRoleService.dart';

class AddNewReservaForm extends StatefulWidget {
  final Function(veiculo_models.Veiculo?, DateTime, String, int, int) onReserve;

  const AddNewReservaForm({
    super.key,
    required this.onReserve,
    required Null Function(dynamic veiculo) onSelect,
  });

  @override
  _AddNewReservaFormState createState() => _AddNewReservaFormState();
}

class _AddNewReservaFormState extends State<AddNewReservaForm> {
  List<veiculo_models.Veiculo> _veiculos = [];
  List<user_models.User> _users = [];
  final Map<veiculo_models.Veiculo, user_models.User?> _selectedUsers = {};
  final Map<veiculo_models.Veiculo, DateTime> _selectedDates = {};
  final Map<veiculo_models.Veiculo, TextEditingController> _destinationControllers = {};
  final Map<veiculo_models.Veiculo, TextEditingController> _numberOfDaysControllers = {};
  final Map<veiculo_models.Veiculo, TextEditingController> _dateControllers = {};
  String _searchQuery = '';
  bool _isGridView = false;
  Uint8List? _imageBytes;

  final VeiculoService _veiculoService = VeiculoService(dotenv.env['BASE_URL']!);
  final UserServiceReserva _userService = UserServiceReserva(dotenv.env['BASE_URL']!);

  @override
  void initState() {
    super.initState();
    _fetchVeiculos();
    _fetchUsers();
  }

  @override
  void dispose() {
    for (var controller in _destinationControllers.values) {
      controller.dispose();
    }
    for (var controller in _numberOfDaysControllers.values) {
      controller.dispose();
    }
    for (var controller in _dateControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _fetchVeiculos() async {
    try {
      List<veiculo_models.Veiculo> veiculos = await _veiculoService.getVeiculos();
      setState(() {
        _veiculos = veiculos;
        for (var veiculo in veiculos) {
          _destinationControllers[veiculo] = TextEditingController();
          _numberOfDaysControllers[veiculo] = TextEditingController(text: '1');
          _dateControllers[veiculo] = TextEditingController();
        }
      });
    } catch (e) {
      print('Error fetching veiculos: $e');
    }
  }

  Future<void> _fetchUsers() async {
    try {
      final response = await _userService.getAllClients();
      setState(() {
        _users = response.cast<user_models.User>();
      });
    } catch (e) {
      print('Error fetching users: $e');
    }
  }

  Future<void> _createReserva(veiculo_models.Veiculo veiculo) async {
    if (_selectedDates.containsKey(veiculo) &&
        _destinationControllers[veiculo]!.text.isNotEmpty &&
        _numberOfDaysControllers[veiculo]!.text.isNotEmpty &&
        _selectedUsers.containsKey(veiculo) &&
        _selectedUsers[veiculo] != null) {
      try {
        final selectedDate = _selectedDates[veiculo]!;
        final selectedDateUTC = selectedDate.toUtc(); // Converta a data para UTC

        print('Creating reservation with date (Local): ${selectedDate.toLocal().toShortDateString()}');
        print('Creating reservation with date (UTC): ${selectedDateUTC.toIso8601String()}');

        await ReservaService(dotenv.env['BASE_URL']!).createReserva(
          date: selectedDate, // Use a data original sem adicionar um dia
          destination: _destinationControllers[veiculo]!.text,
          numberOfDays: int.parse(_numberOfDaysControllers[veiculo]!.text),
          userID: _selectedUsers[veiculo]!.id,
          clientID: _selectedUsers[veiculo]!.id,
          veiculoID: veiculo.id,
          state: 'Not Confirmed',
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reservation created successfully!')),
        );

        // Limpa os campos após a criação da reserva
        setState(() {
          _selectedDates.remove(veiculo);
          _destinationControllers[veiculo]!.clear();
          _numberOfDaysControllers[veiculo]!.clear();
          _dateControllers[veiculo]!.clear();
          _selectedUsers.remove(veiculo);
        });
      } catch (e) {
        print('Error creating Reservation: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error creating reservation')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields.')),
      );
    }
  }

  // Método para exibir o diálogo de adicionar novo cliente

void _showAddClientDialog() {
  // Controladores para os campos de texto
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _birthdateController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _neighborhoodController = TextEditingController();
  final TextEditingController _phone1Controller = TextEditingController();
  final TextEditingController _phone2Controller = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  // Variáveis para gênero e estado
  String _gender = 'M'; // 'M' para masculino, 'F' para feminino
  String _state = 'active'; // 'active' ou 'inactive'

  // Variável para armazenar a imagem selecionada

  // Função para comprimir a imagem
  Uint8List _compressImage(Uint8List imageBytes) {
    final img.Image? image = img.decodeImage(imageBytes);
    if (image != null) {
      final img.Image resizedImage =
          img.copyResize(image, width: 600, height: 400);
      return Uint8List.fromList(img.encodeJpg(resizedImage, quality: 80));
    }
    return imageBytes;
  }

  // Função para selecionar uma imagem
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final imageBytes = await image.readAsBytes();
      final compressedImageBytes = _compressImage(imageBytes); // Agora a função está declarada antes
      setState(() {
        _imageBytes = compressedImageBytes;
      });
    }
  }

  // Função para selecionar a data de nascimento
  Future<void> _selectBirthdate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null) {
      _birthdateController.text = pickedDate.toLocal().toString().split(' ')[0];
    }
  }

  showDialog(
  context: context,
  builder: (context) {
    return AlertDialog(
      title: const Text('Add New Client'),
      content: Container(
        width: 400, // Define a largura do conteúdo
        height: 600, // Define a altura do conteúdo
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Seleção de imagem
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: ClipOval(
                    child: Container(
                      width: 100,
                      height: 100,
                      color: Colors.grey[300],
                      child: _imageBytes == null
                          ? const Center(child: Text('Select Image'))
                          : Image.memory(_imageBytes!, fit: BoxFit.cover),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Campos de texto
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Username'),
              ),
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(labelText: 'First Name'),
              ),
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(labelText: 'Last Name'),
              ),
              const SizedBox(height: 20),

              // Seleção de gênero
              const Text("Gender", style: TextStyle(fontSize: 16)),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Radio<String>(
                    value: 'M',
                    groupValue: _gender,
                    onChanged: (value) {
                      setState(() {
                        _gender = value!;
                      });
                    },
                  ),
                  const Text("Male"),
                  Radio<String>(
                    value: 'F',
                    groupValue: _gender,
                    onChanged: (value) {
                      setState(() {
                        _gender = value!;
                      });
                    },
                  ),
                  const Text("Female"),
                ],
              ),

              // Data de nascimento
              TextFormField(
                controller: _birthdateController,
                readOnly: true,
                onTap: () => _selectBirthdate(context),
                decoration: const InputDecoration(labelText: 'Birthdate'),
              ),

              // Outros campos
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Address'),
              ),
              TextFormField(
                controller: _neighborhoodController,
                decoration: const InputDecoration(labelText: 'Neighborhood'),
              ),
              TextFormField(
                controller: _phone1Controller,
                decoration: const InputDecoration(labelText: 'Phone 1'),
              ),
              TextFormField(
                controller: _phone2Controller,
                decoration: const InputDecoration(labelText: 'Phone 2'),
              ),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              TextFormField(
                controller: _confirmPasswordController,
                decoration: const InputDecoration(labelText: 'Confirm Password'),
                obscureText: true,
              ),

              // Dropdown para estado
              DropdownButtonFormField<String>(
                value: _state,
                items: ['active', 'inactive']
                    .map((state) => DropdownMenuItem(
                          value: state,
                          child: Text(state),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _state = value!;
                  });
                },
                decoration: const InputDecoration(labelText: 'State'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context); // Fecha o diálogo
          },
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () async {
            // Validação dos campos
            if (_usernameController.text.isEmpty ||
                _firstNameController.text.isEmpty ||
                _lastNameController.text.isEmpty ||
                _emailController.text.isEmpty ||
                _passwordController.text.isEmpty ||
                _confirmPasswordController.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please fill in all required fields.')),
              );
              return;
            }

            if (_passwordController.text != _confirmPasswordController.text) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Passwords do not match.')),
              );
              return;
            }

            // Cria o novo cliente
            final newClient = user_models.User(
              id: _users.length + 1, // Gera um ID temporário (substitua pela lógica do backend)
              username: _usernameController.text,
              firstName: _firstNameController.text,
              lastName: _lastNameController.text,
              gender: _gender,
              birthdate: _birthdateController.text,
              email: _emailController.text,
              address: _addressController.text,
              neighborhood: _neighborhoodController.text,
              phone1: _phone1Controller.text,
              phone2: _phone2Controller.text,
              password: _passwordController.text,
              state: _state,
              // imageBytes: _imageBytes,
            );

            // Adiciona o novo cliente à lista de usuários
            setState(() {
              _users.add(newClient);
            });

            // Fecha o diálogo
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  },
);
}

  // Método para selecionar a data
  Future<void> _selectDate(BuildContext context, veiculo_models.Veiculo veiculo) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDates[veiculo] ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDates[veiculo] = pickedDate;
        _dateControllers[veiculo]!.text = pickedDate.toLocal().toShortDateString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    List<veiculo_models.Veiculo> filteredVeiculos = _veiculos
        .where((veiculo) =>
            veiculo.marca.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            veiculo.modelo.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Reservation'),
        actions: [
          IconButton(
            icon: Icon(_isGridView ? Icons.list : Icons.grid_view),
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Search Vehicle',
                border: OutlineInputBorder(),
              ),
              onChanged: (query) {
                setState(() {
                  _searchQuery = query;
                });
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isGridView
                  ? GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16.0,
                        mainAxisSpacing: 16.0,
                      ),
                      itemCount: filteredVeiculos.length,
                      itemBuilder: (context, index) {
                        return _buildVeiculoCard(filteredVeiculos[index]);
                      },
                    )
                  : ListView.builder(
                      itemCount: filteredVeiculos.length,
                      itemBuilder: (context, index) {
                        return _buildVeiculoCard(filteredVeiculos[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVeiculoCard(veiculo_models.Veiculo veiculo) {
  return Card(
    margin: const EdgeInsets.symmetric(vertical: 8.0),
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagem do veículo
          if (veiculo.imagemBase64.isNotEmpty)
            Center(
              child: ClipOval(
                child: Image.memory(
                  base64Decode(veiculo.imagemBase64),
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          const SizedBox(height: 16),

          // Detalhes básicos do veículo
          Text(
            '${veiculo.marca} ${veiculo.modelo}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Plate: ${veiculo.matricula}',
            style: const TextStyle(fontSize: 14),
          ),
          Text(
            'Color: ${veiculo.cor}',
            style: const TextStyle(fontSize: 14),
          ),
          Text(
            'Year: ${veiculo.ano}',
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),

          // Botão "Ver mais detalhes" com ExpansionTile
          ExpansionTile(
            title: const Text(
              'More details',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.blue, // Cor do texto
              ),
            ),
            children: [
              // Detalhes adicionais do veículo
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      'Engine numebr: ${veiculo.numMotor}',
                      style: const TextStyle(fontSize: 14),
                    ),
                    Text(
                      'Chassi number: ${veiculo.numChassi}',
                      style: const TextStyle(fontSize: 14),
                    ),
                    Text(
                      'Seats: ${veiculo.numLugares}',
                      style: const TextStyle(fontSize: 14),
                    ),
                    Text(
                      'Dors: ${veiculo.numPortas}',
                      style: const TextStyle(fontSize: 14),
                    ),
                    Text(
                      'Fuel Type: ${veiculo.tipoCombustivel}',
                      style: const TextStyle(fontSize: 14),
                    ),
                     Text(
                      'Rental Includes Driver?: ${veiculo.rentalIncludesDriver}',
                      style: const TextStyle(fontSize: 14),
                    ),
                     Text(
                      'State: ${veiculo.state}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Seleção de usuário
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<user_models.User>(
                  value: _selectedUsers[veiculo],
                  hint: const Text('Select User'),
                  onChanged: (user) {
                    setState(() {
                      _selectedUsers[veiculo] = user;
                    });
                  },
                  items: _users.map((user) {
                    return DropdownMenuItem<user_models.User>(
                      value: user,
                      child: Text(user.firstName as String),
                    );
                  }).toList(),
                  decoration: const InputDecoration(
                    labelText: 'Client',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: _showAddClientDialog,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Campo de destino
          TextField(
            decoration: const InputDecoration(
              labelText: 'Destination',
              border: OutlineInputBorder(),
            ),
            controller: _destinationControllers[veiculo],
          ),
          const SizedBox(height: 16),

          // Linha com "Number of Days", "Start Date" e botão "Reserve"
          Row(
            children: [
              // Campo "Number of Days"
              Expanded(
                flex: 2,
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Number of Days',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  controller: _numberOfDaysControllers[veiculo],
                ),
              ),
              const SizedBox(width: 8),

              // Campo "Start Date"
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _dateControllers[veiculo],
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Start Date',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  onTap: () => _selectDate(context, veiculo),
                ),
              ),
              const SizedBox(width: 8),

              // Botão "Reserve"
              Expanded(
                flex: 1,
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      _createReserva(veiculo);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Reserve'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
}

extension on DateTime {
  String toShortDateString() {
    return '$day/$month/$year';
  }
}