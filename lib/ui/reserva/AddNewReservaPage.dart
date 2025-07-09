import 'dart:convert';
import 'dart:typed_data';
import 'package:app/models/UserReserva.dart' as user_models;
import 'package:app/services/ReservaService.dart';
import 'package:app/services/UserServiceReserva.dart';
import 'package:app/services/VeiculoService.dart';
import 'package:app/models/Veiculo.dart' as veiculo_models;
import 'package:app/services/VeiculoImgService.dart';
import 'package:app/ui/veiculo/ImagePreviewPage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
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
  bool _isCreatingReserva = false; // Adicione esta linha

  final VeiculoService _veiculoService = VeiculoService(dotenv.env['BASE_URL']!);
  final UserServiceReserva _userService = UserServiceReserva(dotenv.env['BASE_URL']!);
  final VeiculoImgService _veiculoImgService = VeiculoImgService(dotenv.env['BASE_URL']!);

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
      List<veiculo_models.Veiculo> veiculos = await _veiculoService.fetchVehiclesByState('Free');
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

  Future<List<String>> _fetchAdditionalImages(int veiculoId) async {
    try {
      final images = await _veiculoImgService.fetchImagesByVehicleId(veiculoId);
      return images.map((img) => img.imageBase64).toList();
    } catch (error) {
      print('Failed to load additional images: $error');
      return [];
    }
  }

  Future<void> _createReserva(veiculo_models.Veiculo veiculo) async {
  // Verificar se todos os campos obrigatórios estão preenchidos
    if (_selectedDates[veiculo] == null ||
        _destinationControllers[veiculo]!.text.isEmpty ||
        _numberOfDaysControllers[veiculo]!.text.isEmpty ||
        _selectedUsers[veiculo] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    // Validar número de dias
    final numberOfDays = int.tryParse(_numberOfDaysControllers[veiculo]!.text);
    if (numberOfDays == null || numberOfDays <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid number of days')),
      );
      return;
    }

    setState(() => _isCreatingReserva = true);

    try {
      // Mostrar diálogo de carregamento
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text('Creating reservation for ${veiculo.marca} ${veiculo.modelo}...'),
              ],
            ),
          ),
        ),
      );

      // Criar a reserva
      await ReservaService(dotenv.env['BASE_URL']!).createReserva(
        date: _selectedDates[veiculo]!,
        destination: _destinationControllers[veiculo]!.text,
        numberOfDays: numberOfDays,
        userID: _selectedUsers[veiculo]!.id,
        clientID: _selectedUsers[veiculo]!.id,
        veiculoID: veiculo.id,
        state: 'Not Confirmed',
        inService: 'No',
        isPaid: 'Not Paid',
      );

      // Fechar diálogo e mostrar sucesso
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reservation created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Limpar os campos
      setState(() {
        _selectedDates.remove(veiculo);
        _destinationControllers[veiculo]!.clear();
        _numberOfDaysControllers[veiculo]!.clear();
        _dateControllers[veiculo]!.clear();
        _selectedUsers.remove(veiculo);
      });

    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCreatingReserva = false);
      }
    }
  }

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

Future<void> _showAddClientDialog() async {
  final result = await showDialog<user_models.User>(
    context: context,
    builder: (context) => AddClientDialog(userService: _userService),
  );

  if (result != null) {
    setState(() {
      _users.add(result);
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

            Text(
              '${veiculo.marca} ${veiculo.modelo}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text('Plate: ${veiculo.matricula}', style: const TextStyle(fontSize: 14)),
            Text('Color: ${veiculo.cor}', style: const TextStyle(fontSize: 14)),
            Text('Year: ${veiculo.ano}', style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 16),

            ExpansionTile(
              title: const Text(
                'More details',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Text('Engine number: ${veiculo.numMotor}', style: const TextStyle(fontSize: 14)),
                      Text('Chassi number: ${veiculo.numChassi}', style: const TextStyle(fontSize: 14)),
                      Text('Seats: ${veiculo.numLugares}', style: const TextStyle(fontSize: 14)),
                      Text('Doors: ${veiculo.numPortas}', style: const TextStyle(fontSize: 14)),
                      Text('Fuel Type: ${veiculo.tipoCombustivel}', style: const TextStyle(fontSize: 14)),
                      Text('Rental Includes Driver?: ${veiculo.rentalIncludesDriver}', style: const TextStyle(fontSize: 14)),
                      Text('State: ${veiculo.state}', style: const TextStyle(fontSize: 14)),
                      const SizedBox(height: 16),

                      const Text(
                        'Additional Images',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 8),
                      FutureBuilder<List<String>>(
                        future: _fetchAdditionalImages(veiculo.id),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          } else if (snapshot.hasError) {
                            return Center(child: Text('Error loading images: ${snapshot.error}'));
                          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return const Center(
                              child: Text(
                                'No additional images available.',
                                style: TextStyle(fontSize: 14, color: Colors.grey),
                              ),
                            );
                          } else {
                            return GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                mainAxisSpacing: 8,
                                crossAxisSpacing: 8,
                              ),
                              itemCount: snapshot.data!.length,
                              itemBuilder: (context, index) {
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ImagePreviewPage(
                                          images: snapshot.data!
                                              .map((base64) => base64Decode(base64))
                                              .toList(),
                                          initialIndex: index,
                                        ),
                                      ),
                                    );
                                  },
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.memory(
                                      base64Decode(snapshot.data![index]),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                );
                              },
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

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
                color: Colors.white,
                tooltip: 'Adicionar novo cliente',
                onPressed: _showAddClientDialog,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.lightBlue,
                  padding: const EdgeInsets.all(12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
            const SizedBox(height: 16),

            TextField(
              decoration: const InputDecoration(
                labelText: 'Destination',
                border: OutlineInputBorder(),
              ),
              controller: _destinationControllers[veiculo],
            ),
            const SizedBox(height: 16),

            Row(
              children: [
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
                  Expanded(
                    flex: 1,
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isCreatingReserva ? null : () {
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

class AddClientDialog extends StatefulWidget {
  final UserServiceReserva userService;

  const AddClientDialog({
    super.key,
    required this.userService,
  });

  @override
  _AddClientDialogState createState() => _AddClientDialogState();
}

class _AddClientDialogState extends State<AddClientDialog> {
  final _formKey = GlobalKey<FormState>();
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

  String _gender = 'M';
  String _state = 'active';
  Uint8List? _imageBytes;

  @override
  void dispose() {
    _usernameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _birthdateController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _neighborhoodController.dispose();
    _phone1Controller.dispose();
    _phone2Controller.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      final Uint8List imageBytes = await image.readAsBytes();
      setState(() {
        _imageBytes = imageBytes;
      });
    }
  }

  Future<void> _selectBirthdate() async {
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

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Passwords do not match.')),
        );
        return;
      }

      try {
        user_models.User newUser = user_models.User(
          id: 0,
          username: _usernameController.text,
          firstName: _firstNameController.text,
          lastName: _lastNameController.text,
          email: _emailController.text,
          address: _addressController.text,
          neighborhood: _neighborhoodController.text,
          phone1: _phone1Controller.text,
          phone2: _phone2Controller.text,
          password: _passwordController.text,
          imgBase64: _imageBytes != null ? base64Encode(_imageBytes!) : '',
          state: _state,
          gender: _gender,
          birthdate: _birthdateController.text,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        user_models.User createdUser = await widget.userService.createUser(newUser);
        
        UserRoleService userRoleService = UserRoleService(dotenv.env['BASE_URL']!);
        await userRoleService.assignRoleToUser(createdUser.id, 9);

        Navigator.of(context).pop(createdUser);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
  return Dialog(
    insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    child: ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.35,
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Add New Client',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: ClipOval(
                    child: Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey[300],
                      child: _imageBytes == null
                          ? const Icon(Icons.add_a_photo, size: 24)
                          : Image.memory(_imageBytes!, fit: BoxFit.cover),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _buildCompactField(_usernameController, 'Username', true),
              _buildCompactField(_firstNameController, 'First Name', true),
              _buildCompactField(_lastNameController, 'Last Name', true),
              
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Gender", style: TextStyle(fontSize: 14)),
                    Row(
                      children: [
                        Radio<String>(
                          value: 'M',
                          groupValue: _gender,
                          onChanged: (value) => setState(() => _gender = value!),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                        const Text("Male", style: TextStyle(fontSize: 14)),
                        Radio<String>(
                          value: 'F',
                          groupValue: _gender,
                          onChanged: (value) => setState(() => _gender = value!),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                        const Text("Female", style: TextStyle(fontSize: 14)),
                      ],
                    ),
                  ],
                ),
              ),
              
              _buildCompactField(_birthdateController, 'Birthdate', true, readOnly: true, onTap: _selectBirthdate),
              _buildCompactField(_emailController, 'Email', true),
              _buildCompactField(_addressController, 'Address', false),
              _buildCompactField(_neighborhoodController, 'Neighborhood', false),
              _buildCompactField(_phone1Controller, 'Phone 1', true),
              _buildCompactField(_phone2Controller, 'Phone 2', false),
              _buildCompactField(_passwordController, 'Password', true, obscureText: true),
              _buildCompactField(_confirmPasswordController, 'Confirm Password', true, obscureText: true),
              
              DropdownButtonFormField<String>(
                value: _state,
                items: ['active', 'inactive']
                    .map((state) => DropdownMenuItem(
                          value: state,
                          child: Text(state, style: const TextStyle(fontSize: 14)),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => _state = value!),
                decoration: const InputDecoration(
                  labelText: 'State',
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                style: const TextStyle(fontSize: 14),
              ),
              
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('CANCEL', style: TextStyle(fontSize: 14)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _submitForm,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    child: const Text('SAVE', style: TextStyle(fontSize: 14)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Widget _buildCompactField(
  TextEditingController controller,
  String labelText,
  bool isRequired, {
  bool obscureText = false,
  bool readOnly = false,
  VoidCallback? onTap,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: TextFormField(
      controller: controller,
      obscureText: obscureText,
      readOnly: readOnly,
      onTap: onTap,
      decoration: InputDecoration(
        labelText: labelText + (isRequired ? ' *' : ''),
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        isDense: true,
      ),
      style: const TextStyle(fontSize: 14),
      validator: isRequired
          ? (value) => value!.isEmpty ? 'Required field' : null
          : null,
    ),
  );
}
}

extension on DateTime {
  String toShortDateString() {
    return '$day/$month/$year';
  }
}