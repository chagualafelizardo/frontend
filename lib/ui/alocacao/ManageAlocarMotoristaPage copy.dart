import 'dart:convert';
import 'dart:typed_data';
import 'package:app/models/ExtendServiceDay.dart';
import 'package:app/models/Multa.dart';
import 'package:app/services/AtendimentoDocumentService.dart';
import 'package:app/services/AtendimentoItemService.dart';
import 'package:app/ui/user/UserDetailsPage.dart';
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
import 'package:app/services/ExtendServiceDayService.dart';
import 'package:app/services/MultaService.dart';
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
  final ReservaService _reservaService = ReservaService(dotenv.env['BASE_URL']);
  final VeiculoServiceAdd _veiculoService =
      VeiculoServiceAdd(dotenv.env['BASE_URL']!);
  final UserService _userService = UserService(dotenv.env['BASE_URL']!);
  final AtendimentoItemService _atendimentoServiceItens =
      AtendimentoItemService(dotenv.env['BASE_URL']!);
  final AtendimentoDocumentService _atendimentoServiceDocuments =
      AtendimentoDocumentService(dotenv.env['BASE_URL']!);
  final UserAtendimentoAllocationService _userAtendimentoAllocationService =
      UserAtendimentoAllocationService(baseUrl: dotenv.env['BASE_URL']!);
  final ExtendServiceDayService _extendServiceDayService = 
        ExtendServiceDayService(dotenv.env['BASE_URL']!);
  final MultaService _multaService = MultaService(dotenv.env['BASE_URL']!);

  var user, veiculo, state;
  late TabController _tabController;

  List<Atendimento> _atendimentos = [];
  List<Atendimento> _activeAtendimentos = [];
  List<Atendimento> _completedAtendimentos = [];
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
    _tabController = TabController(length: 2, vsync: this);
    _fetchAtendimentos();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchAtendimentos() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      List<Atendimento> atendimentos = await _atendimentoService.fetchAtendimentos();

      for (var atendimento in atendimentos) {
        var reserva = await _reservaService.getReservaById(atendimento.reservaId!);
        user = reserva.user;
        veiculo = reserva.veiculo;
        state = reserva.state;
      }

      // Classificar atendimentos em ativos e completados
      List<Atendimento> active = [];
      List<Atendimento> completed = [];

      for (var atendimento in atendimentos) {
        if (atendimento.dataChegada != null) {
          int daysRemaining = _calculateDaysRemaining(atendimento.dataChegada!);
          if (daysRemaining < 0) {
            completed.add(atendimento);
          } else {
            active.add(atendimento);
          }
        } else {
          active.add(atendimento);
        }
      }

      setState(() {
        _atendimentos = atendimentos;
        _activeAtendimentos = active;
        _completedAtendimentos = completed;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching service records: $e');
      setState(() => _isLoading = false);
    }
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

  Future<List<ExtendServiceDay>> _fetchExtendServiceDays(int atendimentoId) async {
    try {
      return await _extendServiceDayService.fetchByAtendimentoId(atendimentoId);
    } catch (e) {
      print('Error fetching extended service days: $e');
      return [];
    }
  }

  Future<List<Multa>> _fetchMultas(int atendimentoId) async {
    try {
      return await _multaService.fetchMultasByAtendimentoId(atendimentoId);
    } catch (e) {
      print('Error fetching fines: $e');
      return [];
    }
  }

  Widget _buildTabContent(List<Atendimento> atendimentos) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: _buildSearchFields(),
        ),
        Expanded(
          child: _isLoading
              ? _buildLoadingIndicator()
              : atendimentos.isEmpty
                  ? _buildEmptyState()
                  : _isGridView
                      ? GridView.builder(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 16.0,
                            mainAxisSpacing: 16.0,
                          ),
                          itemCount: atendimentos.length,
                          itemBuilder: (context, index) {
                            return _buildAtendimentoCard(atendimentos[index]);
                          },
                        )
                      : ListView.builder(
                          itemCount: atendimentos.length,
                          itemBuilder: (context, index) {
                            return _buildAtendimentoCard(atendimentos[index]);
                          },
                        ),
        ),
      ],
    );
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
  print('Starting allocation process...');
  print('Selected User IDs: $selectedUserIds');
  
  try {
    final allocation = Allocation(
      startDate: startDate,
      endDate: endDate,
      destination: destination,
    );

    print('Creating allocation with data: ${allocation.toJson()}');
    final createdAllocation = await allocationService.createAllocation(allocation);
    
    if (createdAllocation.id == null) {
      print('Allocation creation failed - no ID returned');
      throw Exception('Failed to create allocation');
    }

    print('Allocation created with ID: ${createdAllocation.id}');
    
    for (int userId in selectedUserIds) {
      try {
        print('Processing user ID: $userId');
        
        final userAtendimentoAllocation = UserAtendimentoAllocation(
          userId: userId,
          atendimentoId: atendimentoId,
          allocationId: createdAllocation.id!,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        print('Creating association for user $userId with data: ${userAtendimentoAllocation.toJson()}');
        
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
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ExpansionTile para os motoristas
                ExpansionTile(
                  initiallyExpanded: true,
                  title: const Text(
                    'Available Drivers',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
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
                          allUsers = snapshot.data!;
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
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    height: 300,
                                    child: ListView.separated(
                                      shrinkWrap: true,
                                      itemCount: filteredUsers.length,
                                      separatorBuilder: (context, index) => const SizedBox(height: 8),
                                      itemBuilder: (context, index) {
                                        final user = filteredUsers[index];
                                        final isSelected = selectedUserIds.contains(user.id);

                                        return Container(
                                          decoration: BoxDecoration(
                                            color: Colors.grey[200],
                                            borderRadius: BorderRadius.circular(8),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.05),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: CheckboxListTile(
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                                            title: Text(
                                              '[${user.id}] ${user.firstName} ${user.lastName}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 15,
                                                color: Colors.black87,
                                              ),
                                            ),
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
                                          ),
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
                  ],
                ),
                
                // ExpansionTile para os detalhes
                ExpansionTile(
                  title: const Text(
                    'Service Details',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailRow(Icons.numbers, 'Service ID:', '$atendimentoId'),
                          _buildDetailRow(Icons.place, 'Destination:', destination),
                          _buildDetailRow(Icons.directions_car, 'License Plate:', plate),
                          _buildDetailRow(Icons.date_range, 'Start Date:', DateFormat('dd/MM/yyyy').format(startDate)),
                          _buildDetailRow(Icons.date_range, 'End Date:', DateFormat('dd/MM/yyyy').format(endDate)),
                        ],
                      ),
                    ),
                  ],
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
    var response = await _userService.getAllMotoristas();
    // var response = await _userService.getUsers();
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

Future<Map<String, dynamic>> _fetchItemsAndDocuments(int atendimentoId) async {
  try {
    final items = await _atendimentoServiceItens.fetchAtendimentoItem(atendimentoId);
    final documents = await _atendimentoServiceDocuments.fetchAtendimentoDocument(atendimentoId);
    return {
      'items': items,
      'documents': documents,
    };
  } catch (e) {
    print('Error fetching items and documents: $e');
    return {
      'items': [],
      'documents': [],
    };
  }
}

  Widget _buildItemsAndDocumentsSection(int atendimentoId) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _fetchItemsAndDocuments(atendimentoId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          }
          
          final items = snapshot.data?['items'] ?? [];
          final documents = snapshot.data?['documents'] ?? [];
          
          return Column(
            children: [
              // Seção de Items (existente)
              ExpansionTile(
                title: const Text(
                  'Listed items',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                children: [
                  if (items.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'No items found',
                        style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: items.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              leading: CircleAvatar(
                                radius: 20,
                                backgroundColor: Colors.blue[400],
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                item.itemDescription ?? 'No description',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),

              // Seção de Documents (existente)
              ExpansionTile(
                title: const Text(
                  'Listed Documents',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                children: [
                  if (documents.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'No documents found',
                        style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: documents.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final doc = documents[index];
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              leading: CircleAvatar(
                                radius: 20,
                                backgroundColor: Colors.blue[400],
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                doc.itemDescription ?? 'No description',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                  color: Colors.black87,
                                ),
                              ),
                              trailing: doc.image != null && doc.image!.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.remove_red_eye, color: Colors.blue),
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: Text(doc.itemDescription ?? 'Document Preview'),
                                            content: SingleChildScrollView(
                                              child: InteractiveViewer(
                                                panEnabled: true,
                                                boundaryMargin: const EdgeInsets.all(20),
                                                minScale: 0.5,
                                                maxScale: 4.0,
                                                child: Image.memory(doc.image!),
                                              ),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.of(context).pop(),
                                                child: const Text('Close'),
                                              ),
                                            ],
                                            contentPadding: const EdgeInsets.all(20),
                                            insetPadding: const EdgeInsets.all(20),
                                          ),
                                        );
                                      },
                                    )
                                  : null,
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),

              // Seção para Motoristas Alocados (existente)
              ExpansionTile(
                title: const Text(
                  'Assigned Drivers',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                children: [
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: _userAtendimentoAllocationService.getUserDetailsByAtendimentoId(atendimentoId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            'Error loading drivers',
                            style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                          ),
                        );
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            'No drivers assigned',
                            style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                          ),
                        );
                      } else {
                        final drivers = snapshot.data!;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: drivers.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final driver = drivers[index];
                              return InkWell(
                                onTap: () {
                                  final user = UserBase64(
                                    id: driver['id'],
                                    username: driver['email'] ?? '',
                                    firstName: driver['nome']?.split(' ').first ?? '',
                                    lastName: driver['nome']?.split(' ').length > 1 
                                        ? driver['nome']?.split(' ').last ?? ''
                                        : '',
                                    email: driver['email'] ?? '',
                                    phone1: driver['telefone'] ?? '',
                                    phone2: driver['telefoneAlternativo'] ?? '',
                                    imgBase64: driver['imagem'],
                                    gender: driver['gender'] ?? '',
                                    birthdate: driver['birthdate'] ?? '',
                                  );
                                  
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => UserDetailsPage(user: user),
                                    ),
                                  );
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    leading: CircleAvatar(
                                      radius: 20,
                                      backgroundColor: Colors.green[400],
                                      child: Text(
                                        '${index + 1}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    title: Text(
                                      driver['nome'] ?? 'No name',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                        color: Colors.black87),
                                    ),
                                    subtitle: Text(
                                      driver['telefone'] ?? 'No phone',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.black),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (driver['imagem'] != null)
                                          CircleAvatar(
                                            backgroundImage: MemoryImage(base64Decode(driver['imagem'])),
                                            radius: 20,
                                          )
                                        else
                                          const CircleAvatar(
                                            radius: 20,
                                            child: Icon(Icons.person, size: 20),
                                          ),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          onPressed: () => _confirmRemoveDriver(atendimentoId, driver['id']),
                                          tooltip: 'Remove driver',
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),

              // NOVA SEÇÃO PARA EXTEND SERVICE DAYS
              FutureBuilder<List<ExtendServiceDay>>(
                future: _fetchExtendServiceDays(atendimentoId),
                builder: (context, snapshot) {
                  return ExpansionTile(
                    title: const Text(
                      'Service Extensions',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    children: [
                      if (snapshot.connectionState == ConnectionState.waiting)
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(),
                        )
                      else if (snapshot.hasError)
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            'Error loading service extensions',
                            style: TextStyle(color: Color.fromARGB(255, 17, 17, 17), fontStyle: FontStyle.italic),
                          ),
                        )
                      else if (!snapshot.hasData || snapshot.data!.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            'No service extensions',
                            style: TextStyle(color: Color.fromARGB(255, 14, 13, 13), fontStyle: FontStyle.italic),
                          ),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: snapshot.data!.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final extension = snapshot.data![index];
                              return Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  leading: CircleAvatar(
                                    radius: 20,
                                    backgroundColor: Colors.purple[400],
                                    child: Text(
                                      '${index + 1}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  title: Text(
                                    'Extended to ${DateFormat('dd/MM/yyyy').format(extension.date)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                      color: Colors.black87),
                                  ),
                                  subtitle: Text(
                                    extension.notes,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF616161), // Cinza escuro
                                    ),
                                  ),
                                  trailing: Text(
                                    'Created: ${DateFormat('dd/MM/yyyy').format(extension.createdAt ?? DateTime.now())}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF616161), // Cinza escuro
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  );
                },
              ),

              // NOVA SEÇÃO PARA MULTAS
              FutureBuilder<List<Multa>>(
                future: _fetchMultas(atendimentoId),
                builder: (context, snapshot) {
                  return ExpansionTile(
                    title: const Text(
                      'Fines Applied',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    children: [
                      if (snapshot.connectionState == ConnectionState.waiting)
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(),
                        )
                      else if (snapshot.hasError)
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            'Error loading fines',
                            style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                          ),
                        )
                      else if (!snapshot.hasData || snapshot.data!.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            'No fines applied',
                            style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                          ),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: snapshot.data!.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final fine = snapshot.data![index];
                              return Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  leading: CircleAvatar(
                                    radius: 20,
                                    backgroundColor: Colors.red[400],
                                    child: Text(
                                      '${index + 1}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  title: Text(
                                    fine.description,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                      color: Colors.black87),
                                  ),
                                  subtitle: Text(
                                    fine.observation ?? 'No observations',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  trailing: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'MZN ${fine.valorpagar.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Colors.red),
                                      ),
                                      Text(
                                        DateFormat('dd/MM/yyyy').format(fine.createdAt ?? DateTime.now()),
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          );
        },
      );
    }

Future<void> _confirmRemoveDriver(int atendimentoId, int userId) async {
  bool confirm = await showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Confirm Removal'),
        content: const Text('Are you sure you want to remove this driver assignment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      );
    },
  );

  if (confirm == true) {
    try {
      // Primeiro precisamos obter o ID da associação
      final allocations = await _userAtendimentoAllocationService.getAllUserAtendimentoAllocations();
      
      // Encontrar a alocação específica para este atendimento e usuário
      final allocation = allocations.firstWhere(
        (alloc) => alloc.atendimentoId == atendimentoId && alloc.userId == userId,
        orElse: () => UserAtendimentoAllocation(
          id: 0, // Valor inválido se não encontrado
          userId: 0,
          atendimentoId: 0,
          allocationId: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      if (allocation.id != 0) {
        await _userAtendimentoAllocationService.deleteUserAtendimentoAllocationByUserId(userId);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Driver assignment removed successfully')),
        );
        
        // Atualizar a lista de motoristas
        setState(() {});
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Assignment not found')),
        );
      }
    } catch (e) {
      print('Error removing driver assignment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to remove assignment: ${e.toString()}')),
      );
    }
  }
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
              Text(
                'User: ${user.firstName ?? 'N/A'}',
                style: const TextStyle(fontSize: 14),
              ),
              Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.person_add, color: Colors.blue, size: 20),
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
                      icon: const Icon(Icons.check_circle, color: Colors.green, size: 20),
                      onPressed: () => _showConfirmReturnDialog(atendimento),
                      tooltip: 'Confirm Return',
                    ),
                    IconButton(
                      icon: const Icon(Icons.car_crash, color: Colors.orange, size: 20),
                      onPressed: () => _showSendToMaintenanceDialog(atendimento.id!, veiculo.matricula),
                      tooltip: 'Send for Maintenance',
                    ),
                    // Novo botão para estender dias de serviço
                    IconButton(
                      icon: const Icon(Icons.calendar_today, color: Colors.purple, size: 20),
                      onPressed: () => _showExtendServiceDialog(atendimento),
                      tooltip: 'Extend Service Days',
                    ),
                    // Novo botão para processar multa
                    IconButton(
                      icon: const Icon(Icons.money_off, color: Colors.red, size: 20),
                      onPressed: () => _showProcessFineDialog(atendimento),
                      tooltip: 'Process Late Return Fine',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                      onPressed: () => _showDeleteConfirmationDialog(atendimento.id!),
                      tooltip: 'Delete Service',
                    ),
                  ],
                ),
              _buildItemsAndDocumentsSection(atendimento.id!),
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
    ],
  ),
);
}

void _showExtendServiceDialog(Atendimento atendimento) {
  final _formKey = GlobalKey<FormState>();
  DateTime? _newDate = atendimento.dataChegada;
  final _observationController = TextEditingController();
  final _dateController = TextEditingController(); // Controller para o campo de data
  bool _isSubmitting = false;

  // Inicializa o controller com a data atual
  _dateController.text = _newDate != null 
      ? DateFormat('dd/MM/yyyy').format(_newDate!)
      : '';

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder( // Adiciona StatefulBuilder aqui
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Extend Service Days'),
            content: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Current Return Date: ${DateFormat('dd/MM/yyyy').format(atendimento.dataChegada!)}'),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _dateController, // Usa o controller criado
                      decoration: const InputDecoration(
                        labelText: 'New Return Date',
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      readOnly: true, // Impede edição manual
                      onTap: () async {
                        final selectedDate = await showDatePicker(
                          context: context,
                          initialDate: _newDate ?? DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                        );
                        if (selectedDate != null) {
                          setState(() { // Usa setState do StatefulBuilder
                            _newDate = selectedDate;
                            _dateController.text = DateFormat('dd/MM/yyyy').format(_newDate!);
                          });
                        }
                      },
                      validator: (value) {
                        if (_newDate == null) return 'Please select a date';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _observationController,
                      decoration: const InputDecoration(
                        labelText: 'Notes',
                        hintText: 'Reason for extension'),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter the notes';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: _isSubmitting ? null : () async {
                  if (_formKey.currentState!.validate()) {
                    setState(() => _isSubmitting = true);
                    
                    try {
                      final extendServiceDay = ExtendServiceDay(
                        date: _newDate!,
                        notes: _observationController.text,
                        atendimentoId: atendimento.id!,
                      );

                      await _extendServiceDayService.create(extendServiceDay);
                      
                      await _atendimentoService.updateEndDate(
                        atendimento.id!,
                        _newDate!,
                      );
                      
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Service period extended successfully!')),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error extending period: $e')),
                      );
                    } finally {
                      if (mounted) setState(() => _isSubmitting = false);
                    }
                  }
                },
                child: _isSubmitting 
                    ? const CircularProgressIndicator()
                    : const Text('Confirm'),
              ),
            ],
          );
        },
      );
    },
  );
}

void _showProcessFineDialog(Atendimento atendimento) {
  final _formKey = GlobalKey<FormState>();
  final _fineValueController = TextEditingController();
  final _observationController = TextEditingController();
  final _daysLate = DateTime.now().difference(atendimento.dataChegada!).inDays;

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Process Late Return Fine'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Days late: $_daysLate days'),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _fineValueController,
                  decoration: const InputDecoration(
                    labelText: 'Fine Amount',
                    prefixText: 'MZN ',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the amount';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Invalid amount';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _observationController,
                  decoration: const InputDecoration(
                    labelText: 'Reason for Delay',
                  ),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the reason';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  title: const Text('Notify customer via SMS'),
                  value: true,
                  onChanged: (value) {},
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  title: const Text('Block future rentals'),
                  value: false,
                  onChanged: (value) {},
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                try {
                  await _processLateFine(
                    atendimento.id!,
                    double.parse(_fineValueController.text),
                    _observationController.text,
                    _daysLate,
                  );
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Fine processed successfully!')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error processing fine: $e')),
                  );
                }
              }
            },
            child: const Text('Process Fine'),
          ),
        ],
      );
    },
  );
}

Future<void> _processLateFine(int serviceId, double fineValue, String observation, int daysLate) async {
  // Implementar chamada à API para processar a multa
  // Exemplo:
  // await ApiService.processLateFine(serviceId, fineValue, observation, daysLate);
}

Widget _buildDetailRow(IconData icon, String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4.0),
    child: Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Text(
          '$label ',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        Text(
          value,
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
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Active Services'),
            Tab(text: 'Completed Services'),
          ],
        ),
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
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTabContent(_activeAtendimentos),
          _buildTabContent(_completedAtendimentos),
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

class DocumentPreviewPage extends StatelessWidget {
  final String documentName;
  final Uint8List documentData;

  const DocumentPreviewPage({
    required this.documentName,
    required this.documentData,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(documentName),
      ),
      body: Center(
        child: Image.memory(
          documentData,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}