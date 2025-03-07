import 'package:app/models/UserReserva.dart' as user_models;
import 'package:app/services/ReservaService.dart';
import 'package:app/services/UserServiceReserva.dart';
import 'package:app/services/VeiculoService.dart';
import 'package:app/models/Veiculo.dart' as veiculo_models;
import 'dart:convert';
import 'package:flutter/material.dart';

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
  String _searchQuery = '';
  bool _isGridView = false;

  final VeiculoService _veiculoService = VeiculoService('http://localhost:5000');
  final UserServiceReserva _userService = UserServiceReserva('http://localhost:5000');

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
        }
      });
    } catch (e) {
      print('Error fetching veiculos: $e');
    }
  }

  Future<void> _fetchUsers() async {
    try {
      final response = await _userService.getClient();
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

      // Adiciona um dia à data selecionada
      final dataComUmDiaAdicional = selectedDate.add(Duration(days: 1));

      print('Creating reservation with date (Local): ${selectedDate.toLocal().toShortDateString()}');
      print('Creating reservation with date (UTC): ${selectedDateUTC.toIso8601String()}');
      print('Data com um dia adicional: ${dataComUmDiaAdicional.toIso8601String()}');

      await ReservaService('http://localhost:5000').createReserva(
        date: dataComUmDiaAdicional, // Use a data com um dia adicional
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
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (veiculo.imagemBase64.isNotEmpty)
              ClipOval(
                child: Image.memory(
                  base64Decode(veiculo.imagemBase64),
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 16),
            Text(
              '${veiculo.marca} ${veiculo.modelo}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Year: ${veiculo.ano}'),
            Text('Color: ${veiculo.cor}'),
            Text('Plate: ${veiculo.matricula}'),
            const SizedBox(height: 16),
            DropdownButtonFormField<user_models.User>(
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
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Destination',
                border: OutlineInputBorder(),
              ),
              controller: _destinationControllers[veiculo],
            ),
            const SizedBox(height: 8),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Number of Days',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              controller: _numberOfDaysControllers[veiculo],
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () async {
                final DateTime? selectedDate = await showDatePicker(
                  context: context,
                  initialDate: _selectedDates[veiculo] ?? DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2101),
                );
                if (selectedDate != null) {
                  setState(() {
                    _selectedDates[veiculo] = selectedDate;
                    print('Selected Date: ${selectedDate.toLocal().toShortDateString()}');
                  });
                }
              },
              child: Text(
                _selectedDates[veiculo] != null
                    ? 'Date: ${_selectedDates[veiculo]!.toLocal().toShortDateString()}'
                    : 'Pick Date',
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _createReserva(veiculo);
              },
              child: const Text('Reserve'),
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