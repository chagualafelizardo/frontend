import 'dart:convert';
import 'package:app/models/AtendimentoDocument.dart';
import 'package:app/models/AtendimentoItem.dart';
import 'package:app/services/UserServiceBase64.dart';
import 'package:app/ui/alocacao/AtendimentoDetailsPopup.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:app/models/Allocation.dart';
import 'package:app/models/UserAtendimentoAllocation.dart';
import 'package:app/models/UserRenderImgBase64.dart';
import 'package:app/services/AllocationService.dart';
import 'package:app/services/UserAtendimentoAllocationService.dart';
import 'package:app/models/Reserva.dart';
import 'package:app/services/ReservaService.dart';
import 'package:app/services/UserService.dart';
import 'package:app/services/VeiculoAddService.dart';
import 'package:flutter/material.dart';
import 'package:app/models/Atendimento.dart';
import 'package:app/services/AtendimentoService.dart';
import 'package:app/models/EnviaManutencao.dart';
import 'package:app/services/EnviaManutencaoService.dart';
import 'package:intl/intl.dart';

class ManageAlocarMotoristaPage extends StatefulWidget {
  const ManageAlocarMotoristaPage({super.key});

  @override
  _ManageAlocarMotoristaPageState createState() =>
      _ManageAlocarMotoristaPageState();
}

class _ManageAlocarMotoristaPageState
    extends State<ManageAlocarMotoristaPage> with SingleTickerProviderStateMixin {
  final AtendimentoService _atendimentoService =
      AtendimentoService(dotenv.env['BASE_URL']!);

  final ReservaService _reservaService =
      ReservaService(dotenv.env['BASE_URL']);
 
  final VeiculoServiceAdd _veiculoService =
      VeiculoServiceAdd(dotenv.env['BASE_URL']!);

  final UserService _userService = UserService(dotenv.env['BASE_URL']!);

  var user,veiculo,state;

  List<Atendimento> _atendimentos = [];
  List<Atendimento> _filteredAtendimentos = [];
  bool _isLoading = false;
  String _searchQuery = '';
  bool _isGridView = true;

  DateTime? _startDate;
  DateTime? _endDate;

  // Search controllers
  final TextEditingController _destinoController = TextEditingController();
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _matriculaController = TextEditingController();
  

  @override
  void initState() {
    super.initState();
    _fetchAtendimentos();
  }

  Future<void> _fetchAtendimentos() async {
  if (_isLoading) return;

  setState(() => _isLoading = true);

  try {
    // Fetch all service records
    List<Atendimento> atendimentos = await _atendimentoService.fetchAtendimentos();

    // Logging Service ID, ReserveID and state
    for (var atendimento in atendimentos) {
      print('Service ID: ${atendimento.id}, ReserveID: ${atendimento.reservaId}, State: ${atendimento.state}');

      // Get associated reservation
      var reserva = await _reservaService.getReservaById(atendimento.reservaId!);

      // Get user associated with reservation
      user = reserva.user;
      if (user != null) {
        print('User for Service ID ${atendimento.id}: ${user.firstName} ${user.lastName}');
      } else {
        print('User not found for Service ID ${atendimento.id}');
      }

      // Get vehicle associated with reservation
      veiculo = reserva.veiculo;
      if (veiculo != null) {
        print('Vehicle for Service ID ${atendimento.id}: ${veiculo.matricula}');
      } else {
        print('Vehicle not found for Service ID ${atendimento.id}');
      }

      // Assign reservation state to service record
      state = reserva.state;
        }

    setState(() {
      _atendimentos = atendimentos;
      _filteredAtendimentos = atendimentos;
      _isLoading = false;
    });
  } catch (e) {
    print('Error fetching service records: $e');
    setState(() => _isLoading = false);
  }
}

Future<void> _selectDateRange(BuildContext context) async {
  final DateTimeRange? picked = await showDateRangePicker(
    context: context,
    firstDate: DateTime(2000),
    lastDate: DateTime(2100),
    initialDateRange: _startDate != null && _endDate != null
        ? DateTimeRange(start: _startDate!, end: _endDate!)
        : null,
  );

  if (picked != null) {
    setState(() {
      _startDate = picked.start;
      _endDate = picked.end;
      _filterAtendimentos();
    });
  }
}

Future<void> _showDeleteConfirmationDialog(int atendimentoId) async {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Confirm Deletion'),
        content: const Text('Are you sure you want to delete this service record?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await _deleteAtendimento(atendimentoId);
              Navigator.of(context).pop();
            },
            child: const Text('Delete'),
          ),
        ],
      );
    },
  );
}

Future<void> _deleteAtendimento(int atendimentoId) async {
  try {
    await _atendimentoService.deleteAtendimento(atendimentoId);
    await _fetchAtendimentos();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Service record deleted successfully')),
    );
  } catch (e) {
    print('Error deleting service record: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Failed to delete service record')),
    );
  }
}

void _filterAtendimentos() {
  String destino = _destinoController.text.toLowerCase();
  String user = _userController.text.toLowerCase();
  String state = _stateController.text.toLowerCase();
  String matricula = _matriculaController.text.toLowerCase();

  setState(() {
    _filteredAtendimentos = _atendimentos.where((atendimento) {
      final atendimentoDestino = atendimento.destino?.toLowerCase() ?? '';
      final atendimentoState = atendimento.state?.toLowerCase() ?? '';
      final atendimentoMatricula = veiculo.matricula?.toLowerCase() ?? '';
      
      // Date filter
      bool matchesDate = true;
      if (atendimento.dataSaida != null) {
        if (_startDate != null && _endDate != null) {
          matchesDate = atendimento.dataSaida!.isAfter(_startDate!.subtract(const Duration(days: 1))) && 
                       atendimento.dataSaida!.isBefore(_endDate!.add(const Duration(days: 1)));
        } else if (_startDate != null) {
          matchesDate = atendimento.dataSaida!.isAfter(_startDate!.subtract(const Duration(days: 1)));
        } else if (_endDate != null) {
          matchesDate = atendimento.dataSaida!.isBefore(_endDate!.add(const Duration(days: 1)));
        }
      }

      return atendimentoDestino.contains(destino) &&
          atendimentoState.contains(state) &&
          atendimentoMatricula.contains(matricula) &&
          matchesDate;
    }).toList();
  });
}

  Widget _buildSearchFields() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildSearchField(
            controller: _destinoController,
            label: 'Destination',
            icon: Icons.search,
          ),
          const SizedBox(width: 8),
          _buildSearchField(
            controller: _matriculaController,
            label: 'License Plate',
            icon: Icons.directions_car,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return SizedBox(
      width: 200,
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
        ),
        onChanged: (value) => _filterAtendimentos(),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Text('No service records found'),
    );
  }

  int _calculateDaysRemaining(DateTime dataChegada) {
    final DateTime now = DateTime.now();
    final Duration difference = dataChegada.difference(now);
    final int daysRemaining = difference.inDays;

    return daysRemaining;
  }

  Widget _buildBlinkingAlert(String message, Color color) {
    return AnimatedBuilder(
      animation: Listenable.merge([ValueNotifier(true)]),
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Text(
            message,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        );
      },
    );
  }

Future<void> showAtendimentoDetailsPopup(BuildContext context, int atendimentoId) async {
  try {
    final AtendimentoService atendimentoService = AtendimentoService(dotenv.env['BASE_URL']!);
    final Map<String, dynamic> details = await atendimentoService.fetchAtendimentoDetails(atendimentoId);

    final List<AtendimentoItem> items = details['items'];
    final List<AtendimentoDocument> documents = details['documents'];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AtendimentoDetailsPopup(
          items: items,
          documents: documents,
        );
      },
    );
  } catch (error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to load service details: $error')),
    );
  }
}

void _showDriverDetailsDialog(int atendimentoId) async {
  try {
    UserAtendimentoAllocationService allocationService = UserAtendimentoAllocationService(baseUrl: dotenv.env['BASE_URL']!);
    UserBase64 user = (await allocationService.getDriverForAtendimento(atendimentoId)) as UserBase64;

    if (user.id == 0) {
      throw Exception('Driver not associated with this service');
    }

    print('userId: ${user.id}');

    UserServiceBase64 userService = UserServiceBase64(dotenv.env['BASE_URL']!);
    UserBase64 motorista = await userService.getUserById(user.id);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Driver Details"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("ID: ${motorista.id}"),
            Text("Name: ${motorista.firstName} ${motorista.lastName}"),
            Text("Email: ${motorista.email}"),
            Text("Phone 1: ${motorista.phone1 ?? 'Not provided'}"),
            Text("Phone 2: ${motorista.phone2 ?? 'Not provided'}"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  } catch (error) {
    print('Error fetching driver details: $error');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Error loading driver details')),
    );
  }
}

void _showUserDetails({
  required int atendimentoId,
  required String destination,
  required String plate,
  required DateTime startDate,
  required DateTime endDate,
}) {
  final AllocationService allocationService = AllocationService(dotenv.env['BASE_URL']!);
  final UserAtendimentoAllocationService userAtendimentoAllocationService = UserAtendimentoAllocationService(baseUrl: dotenv.env['BASE_URL']!);

  print("Calling _showUserDetails...");
  List<int> selectedUserIds = [];
  TextEditingController searchController = TextEditingController();
  List<UserBase64> filteredUsers = [];
  List<UserBase64> allUsers = [];

  Future<void> allocateSelectedUsers() async {
  try {
    final allocation = Allocation(
      startDate: startDate,
      endDate: endDate,
      destination: destination,
    );

    final createdAllocation = await allocationService.createAllocation(allocation);

    if (createdAllocation.id == null) {
      throw Exception('Failed to create allocation');
    }

    for (int userId in selectedUserIds) {
      try {
        final userAtendimentoAllocation = UserAtendimentoAllocation(
          userId: userId,
          atendimentoId: atendimentoId,
          allocationId: createdAllocation.id!,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await userAtendimentoAllocationService
            .createUserAtendimentoAllocation(userAtendimentoAllocation);

        print('Association created successfully for User ID: $userId');
      } catch (e) {
        print('Failed to create association for User ID: $userId. Error: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to allocate User ID: $userId')),
        );
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Allocation completed successfully')),
    );
  } catch (e) {
    print('Error during allocation: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Failed to complete allocation')),
    );
  }
}

showDialog(
  context: context,
  builder: (BuildContext context) {
    return AlertDialog(
      title: const Text('Allocate Drivers'),
      content: SizedBox(
        width: 600,
        height: 600,
        child: DefaultTabController(
          length: 2,
          child: Column(
            children: [
              const TabBar(
                tabs: [
                  Tab(text: 'Drivers'),
                  Tab(text: 'Details'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    FutureBuilder<List<UserBase64>>(
                      future: _fetchUsers(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          return Center(child: Text('Error: ${snapshot.error}'));
                        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Center(child: Text('No drivers found.'));
                        } else {
                          final allUsers = snapshot.data!;
                          filteredUsers = List.from(allUsers);

                          return StatefulBuilder(
                            builder: (context, setState) {
                              return Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: TextField(
                                      controller: searchController,
                                      decoration: const InputDecoration(
                                        labelText: 'Search drivers',
                                        prefixIcon: Icon(Icons.search),
                                        border: OutlineInputBorder(),
                                      ),
                                        onChanged: (value) {
                                          setState(() {
                                            filteredUsers = allUsers.where((user) {
                                              final query = value.toLowerCase();
                                              final fullName = '${user.firstName} ${user.lastName}'.toLowerCase();
                                              return fullName.contains(query);
                                            }).toList();
                                          });
                                      },
                                    ),
                                  ),
                                  Expanded(
                                    child: ListView.builder(
                                      itemCount: filteredUsers.length,
                                      itemBuilder: (context, index) {
                                        final user = filteredUsers[index];
                                        final isSelected = selectedUserIds.contains(user.id);

                                        return CheckboxListTile(
                                          title: Text('${user.firstName} ${user.lastName}'),
                                          subtitle: Text('ID: ${user.id}'),
                                          tileColor: index.isEven ? const Color.fromARGB(255, 12, 12, 12) : const Color.fromARGB(190, 75, 74, 74),
                                          value: isSelected,
                                          onChanged: (bool? value) {
                                            setState(() {
                                              if (value == true) {
                                                selectedUserIds.add(user.id);
                                              } else {
                                                selectedUserIds.remove(user.id);
                                              }
                                            });
                                          },
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                        }
                      },
                    ),
                    SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Service ID: $atendimentoId'),
                          Text('Destination: $destination'),
                          Text('Plate: $plate'),
                          Text('Start Date: ${startDate.toLocal()}'),
                          Text('End Date: ${endDate.toLocal()}'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () async {
            if (selectedUserIds.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No drivers selected')),
              );
              return;
            }

            await allocateSelectedUsers();
            Navigator.of(context).pop();
          },
          child: const Text('Allocate'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Close'),
        ),
      ],
    );
  },
);
}

Future<List<UserBase64>> _fetchUsers() async {
  print('Starting user search...');
  try {
    var response = await _userService.getUsers();
    print('User service response: $response');

    print('Response is a user list');

    List<UserBase64> users = response.map<UserBase64>((userJson) {
      try {
        print('Converting user: $userJson');
        return UserBase64.fromJson(userJson);
      } catch (e) {
        print('Error converting user: $e');
        throw Exception("Error converting one of the users.");
      }
    }).toList();

    print('Converted user list: $users');
    return users;
  } catch (e) {
    print('Error fetching users: $e');
    return [];
  }
}

Future<bool> updateAtendimentoKmFinal(int atendimentoId, double kmFinal, String returnDateText) async {
  try {
    if (atendimentoId == 0) {
      throw Exception('Invalid service ID. Cannot update.');
    }

    DateTime dataDevolucao = DateTime.parse(returnDateText);

    await _atendimentoService.updateKmFinal(
      atendimentoId: atendimentoId,
      kmFinal: kmFinal,
      dataDevolucao: dataDevolucao,
    );

    print('Final mileage and return date updated successfully for service $atendimentoId.');
    return true;
  } catch (e) {
    print('Error updating final mileage and return date: $e');
    return false;
  }
}

void _confirmReturn(BuildContext context, int atendimentoid, double kmFinal, String returnDateText) async {
  try {
    final response = await updateAtendimentoKmFinal(atendimentoid, kmFinal,returnDateText);

    if (response) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vehicle return confirmed successfully!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to confirm vehicle return.')),
      );
    }
  } catch (error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $error')),
    );
  }
}

void _showSendToMaintenanceDialog(int atendimentoID, String matricula) async {
  final TextEditingController obsController = TextEditingController();

  Veiculo? veiculo;
  try {
    veiculo = await _veiculoService.getVeiculoByMatricula(matricula);
    if (veiculo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vehicle not found!')),
      );
      return;
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error fetching vehicle: $e')),
    );
    return;
  }

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Send Vehicle for Maintenance'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Vehicle License Plate: $matricula',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: obsController,
                decoration: const InputDecoration(
                  labelText: 'Observations (optional)',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 5,
                keyboardType: TextInputType.multiline,
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              EnviaManutencao manutencao = EnviaManutencao(
                obs: obsController.text,
                veiculoID: veiculo!.id,
                oficinaID: 1,
                atendimentoID: atendimentoID,
              );

              print('Maintenance request created:');
              print('obs: ${manutencao.obs}');
              print('veiculoID: ${manutencao.veiculoID}');
              print('oficinaID: ${manutencao.oficinaID}');
              print('atendimentoID: ${manutencao.atendimentoID}');

              try {
                EnviaManutencaoService service = EnviaManutencaoService(dotenv.env['BASE_URL']!);
                await service.createEnviaManutencao(manutencao);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vehicle sent for maintenance successfully!')),
                );

                Navigator.of(context).pop();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error sending vehicle for maintenance: $e')),
                );
              }
            },
            child: const Text('Confirm'),
          ),
        ],
      );
    },
  );
}

void _showConfirmReturnDialog(Atendimento atendimento) {
  TextEditingController kmFinalController = TextEditingController();

  showDialog(
  context: context,
  builder: (BuildContext context) {
    TextEditingController dateController = TextEditingController();
    
    return AlertDialog(
      title: const Text('Confirm Vehicle Return'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Enter the final mileage of the vehicle:'),
          const SizedBox(height: 10),
          TextField(
            controller: kmFinalController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Final Mileage',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          const Text('Select the return date:'),
          const SizedBox(height: 10),
          TextField(
            controller: dateController,
            readOnly: true,
            decoration: const InputDecoration(
              labelText: 'Return Date',
              border: OutlineInputBorder(),
              suffixIcon: Icon(Icons.calendar_today),
            ),
            onTap: () async {
              DateTime? pickedDate = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );

              if (pickedDate != null) {
                dateController.text = pickedDate.toIso8601String().split('T')[0];
              }
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            String kmFinalText = kmFinalController.text.trim();
            String returnDateText = dateController.text.trim();

            if (kmFinalText.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please enter the final mileage.')),
              );
              return;
            }

            double kmFinal = double.tryParse(kmFinalText) ?? -1;
            if (kmFinal < 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Invalid mileage.')),
              );
              return;
            }

            if (returnDateText.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please select the return date.')),
              );
              return;
            }

            _confirmReturn(context, atendimento.id!, kmFinal, returnDateText);

            Navigator.of(context).pop();
          },
          child: const Text('Confirm'),
        ),
      ],
    );
  },
);
}

Widget _buildAtendimentoCard(Atendimento atendimento) {
  final DateTime? dataChegada = atendimento.dataChegada;

  String daysRemainingMessage = 'Return date not available';
  Color circleColor = Colors.grey;
  bool isBlinking = false;

  if (dataChegada != null) {
    int daysRemaining = _calculateDaysRemaining(dataChegada);
    if (daysRemaining < 0) {
      daysRemainingMessage = 'Return already completed';
    } else if (daysRemaining <= 5) {
      daysRemainingMessage = '$daysRemaining days until return';
      circleColor = Colors.red;
      isBlinking = true;
    } else if (daysRemaining <= 10) {
      daysRemainingMessage = '$daysRemaining days until return';
      circleColor = Colors.orange;
    } else if (daysRemaining <= 15) {
      daysRemainingMessage = '$daysRemaining days until return';
      circleColor = Colors.yellow;
    } else {
      daysRemainingMessage = 'More than 15 days until return';
      circleColor = Colors.green;
    }
  }

  return Card(
  margin: const EdgeInsets.all(8.0),
  elevation: 4,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  ),
  child: ExpansionTile(
    title: Row(
      children: [
        Icon(
          Icons.car_rental,
          color: circleColor,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Service nr. ${atendimento.id}'
                ', of reservation nr. ${atendimento.reservaId!}' ,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Destination: ${atendimento.destino ?? 'N/A'}',
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    ),
    subtitle: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'User: ${user.firstName ?? 'N/A'}',
          style: const TextStyle(fontSize: 14),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.person_2, color: Color.fromARGB(255, 45, 116, 163)),
                onPressed: () {
                  _atendimentoService.fetchReserveIdAndUserDetails(atendimento.reservaId!);
                },
                tooltip: 'View Assigned Driver',
              ),
              IconButton(
                icon: const Icon(Icons.list, color: Colors.teal),
                onPressed: () async {
                  await showAtendimentoDetailsPopup(context, atendimento.id!);
                },
                tooltip: 'View Items Details',
              ),
            ],
          ),
        ),
      ],
    ),
    trailing: isBlinking
        ? _buildBlinkingAlert(daysRemainingMessage, circleColor)
        : Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              color: circleColor,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              daysRemainingMessage,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
    children: [
      Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow(
              Icons.date_range,
              'Departure Date:',
              atendimento.dataSaida != null
                  ? DateFormat('dd/MM/yyyy').format(atendimento.dataSaida!)
                  : 'N/A',
            ),
            _buildDetailRow(
              Icons.date_range,
              'Expected Return Date:',
              atendimento.dataChegada != null
                  ? DateFormat('dd/MM/yyyy').format(atendimento.dataChegada!)
                  : 'N/A',
            ),
            _buildDetailRow(
              Icons.date_range,
              'Actual Return Date:',
              atendimento.dataDevolucao != null
                  ? DateFormat('dd/MM/yyyy').format(atendimento.dataDevolucao!)
                  : 'N/A',
            ),
            _buildDetailRow(Icons.speed, 'Initial Mileage:', atendimento.kmInicial?.toString() ?? 'N/A'),
            _buildDetailRow(Icons.speed, 'Final Mileage:', atendimento.kmFinal?.toString() ?? 'N/A'),
            _buildDetailRow(Icons.person, 'User:', user.firstName ?? 'N/A'),
            _buildDetailRow(Icons.directions_car, 'Vehicle:', veiculo.matricula ?? 'N/A'),
            _buildDetailRow(Icons.flag, 'State:', state ?? 'N/A'),
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            IconButton(
              icon: const Icon(Icons.person_add, color: Colors.blue),
              onPressed: () async {
                try {
                  _showUserDetails(
                    atendimentoId: atendimento.id!,
                    destination: atendimento.destino!,
                    plate: veiculo.matricula,
                    startDate: atendimento.dataSaida!,
                    endDate: atendimento.dataChegada!,
                  );
                  print('User details displayed successfully.');
                } catch (error) {
                  print('Error loading user details: $error');
                }
              },
              tooltip: 'Assign Driver',
            ),
            IconButton(
              icon: const Icon(Icons.check_circle, color: Colors.green),
              onPressed: () => _showConfirmReturnDialog(atendimento),
              tooltip: 'Confirm Return',
            ),
            IconButton(
              icon: const Icon(Icons.car_crash, color: Colors.orange),
              onPressed: () => _showSendToMaintenanceDialog(atendimento.id!, veiculo.matricula),
              tooltip: 'Send for Maintenance',
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _showDeleteConfirmationDialog(atendimento.id!),
              tooltip: 'Delete Service',
            ),
          ],
        ),
      ),
    ],
  ),
);
}

Widget _buildDetailRow(IconData icon, String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4.0),
    child: Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Text(
          '$label $value',
          style: const TextStyle(fontSize: 14),
        ),
      ],
    ),
  );
}

  @override
  Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Vehicles in Service and Allocations'),
      actions: [
        IconButton(
          icon: Icon(_isGridView ? Icons.list : Icons.grid_view),
          onPressed: () {
            setState(() {
              _isGridView = !_isGridView;
            });
          },
        ),
      ],
    ),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: _buildSearchFields(),
        ),
        Expanded(
          child: _isLoading
              ? _buildLoadingIndicator()
              : _filteredAtendimentos.isEmpty
                  ? _buildEmptyState()
                  : _isGridView
                      ? GridView.builder(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 16.0,
                            mainAxisSpacing: 16.0,
                          ),
                          itemCount: _filteredAtendimentos.length,
                          itemBuilder: (context, index) {
                            return _buildAtendimentoCard(
                                _filteredAtendimentos[index]);
                          },
                        )
                      : ListView.builder(
                          itemCount: _filteredAtendimentos.length,
                          itemBuilder: (context, index) {
                            return _buildAtendimentoCard(
                                _filteredAtendimentos[index]);
                          },
                        ),
        ),
      ],
    ),
  );
}
}

class VeiculoService {
  Future<Veiculo> getVeiculoByMatricula(String matricula) async {
    final response = await http.get(Uri.parse('${dotenv.env['BASE_URL']}/veiculo/matricula/$matricula'));
    if (response.statusCode == 200) {
      return Veiculo.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load vehicle');
    }
  }
}

class UserServiceDetails {
  Future<User> getUserByName(int userId) async {
    final response = await http.get(Uri.parse('${dotenv.env['BASE_URL']}/user/$userId'));

    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load vehicle');
    }
  }
}