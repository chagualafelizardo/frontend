import 'dart:convert';
import 'dart:typed_data';
import 'package:app/services/VeiculoImgService.dart';
import 'package:app/ui/veiculo/ImagePreviewPage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:app/models/Atendimento.dart';
import 'package:app/ui/atendimento/AtendimentoForm.dart';
import 'package:flutter/material.dart';
import 'package:app/models/Reserva.dart';
import 'package:app/services/ReservaService.dart';
import 'package:app/ui/reserva/AddNewReservaPage.dart';
import 'package:intl/intl.dart';
import 'package:app/services/VeiculoService.dart';

class ManageConfirmedReservasPage extends StatefulWidget {
  const ManageConfirmedReservasPage({super.key});

  @override
  _ManageConfirmedReservasPageState createState() =>
      _ManageConfirmedReservasPageState();
}

class _ManageConfirmedReservasPageState
    extends State<ManageConfirmedReservasPage> with SingleTickerProviderStateMixin {
  final ReservaService _reservaService = ReservaService(dotenv.env['BASE_URL']!);
  final VeiculoService _veiculoService = VeiculoService(dotenv.env['BASE_URL']!);
  final VeiculoImgService _veiculoImgService = VeiculoImgService(dotenv.env['BASE_URL']!);

  List<Reserva> _confirmedReservas = []; // Reservas confirmadas (inService == 'No')
  List<Reserva> _inServiceReservas = []; // Reservas em serviço (inService == 'Yes')
  
  List<Reserva> _filteredConfirmedReservas = [];
  List<Reserva> _filteredInServiceReservas = [];
  
  int _currentPage = 1;
  final int _pageSize = 10;
  bool _hasMore = true;
  bool _isLoading = false;
  int? _selectedVehicleId;
  bool _isLoadingImages = false;
  late TabController _tabController;

  // Filtros para cada tab
  String _destinationFilterConfirmed = '';
  String _vehicleFilterConfirmed = '';
  DateTime? _startDateConfirmed;
  DateTime? _endDateConfirmed;
  
  String _destinationFilterInService = '';
  String _vehicleFilterInService = '';
  DateTime? _startDateInService;
  DateTime? _endDateInService;

  bool _isGridView = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedVehicleId = null;
    _fetchReservas();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _applyFiltersConfirmed() {
    setState(() {
      _filteredConfirmedReservas = _confirmedReservas.where((reserva) {
        final reservaDate = reserva.date;
        
        final matchesDestination = reserva.destination
            .toLowerCase()
            .contains(_destinationFilterConfirmed.toLowerCase());
        final matchesVehicle = reserva.veiculo.matricula
            .toLowerCase()
            .contains(_vehicleFilterConfirmed.toLowerCase());
        
        bool matchesDate = true;
        if (_startDateConfirmed != null && _endDateConfirmed != null) {
          matchesDate = reservaDate.isAfter(_startDateConfirmed!.subtract(const Duration(days: 1))) && 
                       reservaDate.isBefore(_endDateConfirmed!.add(const Duration(days: 1)));
        } else if (_startDateConfirmed != null) {
          matchesDate = reservaDate.isAfter(_startDateConfirmed!.subtract(const Duration(days: 1)));
        } else if (_endDateConfirmed != null) {
          matchesDate = reservaDate.isBefore(_endDateConfirmed!.add(const Duration(days: 1)));
        }

        return matchesDestination && matchesVehicle && matchesDate;
      }).toList();
    });
  }

  void _applyFiltersInService() {
    setState(() {
      _filteredInServiceReservas = _inServiceReservas.where((reserva) {
        final reservaDate = reserva.date;
        
        final matchesDestination = reserva.destination
            .toLowerCase()
            .contains(_destinationFilterInService.toLowerCase());
        final matchesVehicle = reserva.veiculo.matricula
            .toLowerCase()
            .contains(_vehicleFilterInService.toLowerCase());
        
        bool matchesDate = true;
        if (_startDateInService != null && _endDateInService != null) {
          matchesDate = reservaDate.isAfter(_startDateInService!.subtract(const Duration(days: 1))) && 
                       reservaDate.isBefore(_endDateInService!.add(const Duration(days: 1)));
        } else if (_startDateInService != null) {
          matchesDate = reservaDate.isAfter(_startDateInService!.subtract(const Duration(days: 1)));
        } else if (_endDateInService != null) {
          matchesDate = reservaDate.isBefore(_endDateInService!.add(const Duration(days: 1)));
        }

        return matchesDestination && matchesVehicle && matchesDate;
      }).toList();
    });
  }

  Future<void> _selectDateRangeConfirmed(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: _startDateConfirmed != null && _endDateConfirmed != null
          ? DateTimeRange(start: _startDateConfirmed!, end: _endDateConfirmed!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _startDateConfirmed = picked.start;
        _endDateConfirmed = picked.end;
        _applyFiltersConfirmed();
      });
    }
  }

  Future<void> _selectDateRangeInService(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: _startDateInService != null && _endDateInService != null
          ? DateTimeRange(start: _startDateInService!, end: _endDateInService!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _startDateInService = picked.start;
        _endDateInService = picked.end;
        _applyFiltersInService();
      });
    }
  }

  Future<void> _fetchReservas() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
    });

    try {
      List<Reserva> reservas = await _reservaService.getReservas(
        page: _currentPage,
        pageSize: _pageSize,
      );

      setState(() {
        if (reservas.isEmpty) {
          _hasMore = false;
        } else {
          // Separar reservas confirmadas e em serviço
          _confirmedReservas.addAll(reservas.where((reserva) => 
            reserva.state == 'Confirmed' && reserva.inService == 'No'));
          
          _inServiceReservas.addAll(reservas.where((reserva) => 
            reserva.state == 'Confirmed' && reserva.inService == 'Yes'));
          
          // Ordenar por ID decrescente
          _confirmedReservas.sort((a, b) => b.id.compareTo(a.id));
          _inServiceReservas.sort((a, b) => b.id.compareTo(a.id));
          
          _currentPage++;
        }
        
        _applyFiltersConfirmed();
        _applyFiltersInService();
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching reservas: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  Future<void> _uncheckReserva(int reservaId) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Reservation'),
          content: const Text('Do you want to undo the reservation confirmation?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        await _reservaService.unconfirmReserva(reservaId.toString());
        await _reservaService.updateInService(
          reservaId: reservaId,
          inService: 'No',
        );
        await _reservaService.updateIsPaid(
          reservaId: reservaId,
          isPaid: 'Not Paid',
        );

        setState(() {
          _confirmedReservas = _confirmedReservas.where((r) => r.id != reservaId).toList();
          _filteredConfirmedReservas = _filteredConfirmedReservas.where((r) => r.id != reservaId).toList();
        });
      } catch (e, stackTrace) {
        print('Exception occurred while confirming reservation: ${e.toString()}');
        print('StackTrace: $stackTrace');
      }
    }
  }

  Future<void> _advanceProcess(int reservaId) async {
    try {
      Reserva? reserva = _confirmedReservas.firstWhere((r) => r.id == reservaId);
      Atendimento atendimento = Atendimento(reserveID: reservaId);
      
      bool? processStarted = await showDialog<bool>(
        context: context,
        builder: (context) => AtendimentoForm(
          atendimento: atendimento,
          reserva: reserva,
          onProcessStart: (dataSaida, dataChegada, destino, kmInicial) async {
            try {
              await _reservaService.startAtendimento(
                reservaId: reservaId,
                dataSaida: dataSaida,
                dataChegada: dataChegada,
                destino: destino,
                kmInicial: kmInicial,
              );
              
              await _reservaService.updateInService(
                reservaId: reservaId,
                inService: 'Yes',
              );
              
              setState(() {
                _confirmedReservas.removeWhere((r) => r.id == reservaId);
                _filteredConfirmedReservas.removeWhere((r) => r.id == reservaId);
                reserva.inService = 'Yes';
                _inServiceReservas.add(reserva);
                _inServiceReservas.sort((a, b) => b.id.compareTo(a.id));
                _applyFiltersInService();
              });
              
              return true;
            } catch (e) {
              print('Error starting rental process: $e');
              return false;
            }
          },
        ),
      );

      if (processStarted == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rental process started successfully')),
        );
      }
    } catch (e) {
      print('Error in advanceProcess: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error starting process: ${e.toString()}')),
      );
    }
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.blue),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showUserDetails(User user) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('User Details'),
          content: SizedBox(
            width: 600,
            child: DefaultTabController(
              length: 2,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.person, size: 40, color: Colors.blue),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${user.firstName} ${user.lastName}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              user.email,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const TabBar(
                    tabs: [
                      Tab(text: 'User Info'),
                      Tab(text: 'General Info'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildDetailRow(Icons.person_outline, 'First Name', user.firstName),
                              _buildDetailRow(Icons.person_outline, 'Last Name', user.lastName),
                              _buildDetailRow(Icons.email, 'Email', user.email),
                              _buildDetailRow(Icons.phone, 'Phone 1', user.phone1),
                              _buildDetailRow(Icons.phone, 'Phone 2', user.phone2),
                              _buildDetailRow(Icons.location_on, 'Address', user.address),
                            ],
                          ),
                        ),
                        SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Additional Information',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildDetailRow(Icons.history, 'Reservations', '5 completed'),
                              _buildDetailRow(Icons.note, 'Notes', 'No additional notes.'),
                              _buildDetailRow(Icons.star, 'Rating', '4.5/5'),
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
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
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

  Widget _buildVehicleExpansionTile(Veiculo veiculo) {
    return ExpansionTile(
      title: const Text(
        'Vehicle Details',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ),
      initiallyExpanded: true,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text('Engine number: ${veiculo.numMotor}', style: const TextStyle(fontSize: 14)),
                Text('Chassi number: ${veiculo.numChassi}', style: const TextStyle(fontSize: 14)),
                Text('Seats: ${veiculo.numLugares}', style: const TextStyle(fontSize: 14)),
                Text('Doors: ${veiculo.numPortas}', style: const TextStyle(fontSize: 14)),
                Text('Fuel Type: ${veiculo.tipoCombustivel}', style: const TextStyle(fontSize: 14)),
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
        ),
      ],
    );
  }

  Widget _buildReservaCard(Reserva reserva, bool isInServiceTab) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          ListTile(
            title: Text('Reserva ID: ${reserva.id}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Destination: ${reserva.destination}'),
                Text('Date: ${reserva.date}'),
                Text('Number of Days: ${reserva.numberOfDays}'),
                Row(
                  children: [
                    Chip(
                      label: Text(
                        reserva.state,
                        style: const TextStyle(color: Colors.white),
                      ),
                      backgroundColor: reserva.state == 'Confirmed'
                          ? Colors.green
                          : Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    Chip(
                      label: Text(
                        reserva.isPaid,
                        style: const TextStyle(color: Colors.white),
                      ),
                      backgroundColor: reserva.isPaid == 'Paid'
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                    ),
                  ],
                ),
                const SizedBox(height: 8.0),
                Row(
                  children: [
                    const Icon(Icons.person, color: Colors.blue),
                    const SizedBox(width: 8.0),
                    Text(
                      'User: ${reserva.user.firstName ?? 'Unknown'} ${reserva.user.lastName ?? 'Unknown'}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8.0),
                    Tooltip(
                      message: 'See more customer details',
                      child: IconButton(
                        onPressed: () async {
                          try {
                            UserService userService = UserService();
                            User userDetails = await userService.getUserByName(reserva.clientId);
                            _showUserDetails(userDetails);
                          } catch (error) {
                            print('Error fetching user details: $error');
                          }
                        },
                        icon: const Icon(Icons.arrow_forward),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.car_repair, color: Colors.green),
                    const SizedBox(width: 8.0),
                    Text(
                      'Vehicle: ${reserva.veiculo.matricula}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8.0),
                    Tooltip(
                      message: 'See more vehicle details',
                      child: IconButton(
                        onPressed: () {
                          setState(() {
                            _selectedVehicleId = _selectedVehicleId == reserva.veiculo.id 
                                ? null 
                                : reserva.veiculo.id;
                          });
                        },
                        icon: Icon(
                          _selectedVehicleId == reserva.veiculo.id
                              ? Icons.expand_less
                              : Icons.arrow_forward,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: isInServiceTab 
                ? null
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Tooltip(
                        message: reserva.isPaid == "Not Paid"
                            ? 'The reservation is not paid, cannot proceed to the rental process.'
                            : 'Proceed with the rental process',
                        child: Material(
                          color: reserva.isPaid == "Not Paid" ? Colors.grey : Colors.lightBlue,
                          shape: const CircleBorder(),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(50),
                            onTap: reserva.isPaid == "Not Paid" 
                                ? null 
                                : () => _advanceProcess(reserva.id),
                            child: const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Icon(Icons.add_circle_outline, color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                      Tooltip(
                        message: 'Undo the process',
                        child: Material(
                          color: Colors.redAccent,
                          shape: const CircleBorder(),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(50),
                            onTap: () => _uncheckReserva(reserva.id),
                            child: const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Icon(Icons.undo, color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
          if (_selectedVehicleId == reserva.veiculo.id)
            _buildVehicleExpansionTile(reserva.veiculo),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Confirmed Reservations'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.check_circle), text: 'Confirmed'),
            Tab(icon: Icon(Icons.directions_car), text: 'In Service'),
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
          // Primeira Tab - Reservas Confirmadas
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText: 'Search Destination',
                          prefixIcon: Icon(Icons.search),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _destinationFilterConfirmed = value;
                            _applyFiltersConfirmed();
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText: 'Vehicle Plate'),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _vehicleFilterConfirmed = value;
                            _applyFiltersConfirmed();
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectDateRangeConfirmed(context),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Date Range',
                            border: OutlineInputBorder(),
                            suffixIcon: _startDateConfirmed != null || _endDateConfirmed != null
                                ? Icon(Icons.filter_alt, color: Colors.blue)
                                : Icon(Icons.calendar_today),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _startDateConfirmed == null && _endDateConfirmed == null
                                    ? 'Select date range'
                                    : '${_startDateConfirmed != null ? _formatDate(_startDateConfirmed!) : ''}'
                                        ' - '
                                        '${_endDateConfirmed != null ? _formatDate(_endDateConfirmed!) : ''}',
                              ),
                              if (_startDateConfirmed != null || _endDateConfirmed != null)
                                IconButton(
                                  icon: Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    setState(() {
                                      _startDateConfirmed = null;
                                      _endDateConfirmed = null;
                                      _applyFiltersConfirmed();
                                    });
                                  },
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _isLoading && _confirmedReservas.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredConfirmedReservas.isEmpty
                        ? const Center(child: Text('No confirmed reservations found'))
                        : _isGridView
                            ? GridView.builder(
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 4,
                                  crossAxisSpacing: 8.0,
                                  mainAxisSpacing: 8.0,
                                  childAspectRatio: 1.5,
                                ),
                                itemCount: _filteredConfirmedReservas.length + (_hasMore ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (index >= _filteredConfirmedReservas.length) {
                                    return _isLoading
                                        ? const Center(child: CircularProgressIndicator())
                                        : Container();
                                  }
                                  return _buildReservaCard(_filteredConfirmedReservas[index], false);
                                },
                              )
                            : ListView.builder(
                                itemCount: _filteredConfirmedReservas.length + (_hasMore ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (index >= _filteredConfirmedReservas.length) {
                                    return _isLoading
                                        ? const Center(child: CircularProgressIndicator())
                                        : Container();
                                  }
                                  return _buildReservaCard(_filteredConfirmedReservas[index], false);
                                },
                              ),
              ),
            ],
          ),

          // Segunda Tab - Reservas em Serviço
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText: 'Search Destination',
                          prefixIcon: Icon(Icons.search),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _destinationFilterInService = value;
                            _applyFiltersInService();
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText: 'Vehicle Plate'),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _vehicleFilterInService = value;
                            _applyFiltersInService();
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectDateRangeInService(context),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Date Range',
                            border: OutlineInputBorder(),
                            suffixIcon: _startDateInService != null || _endDateInService != null
                                ? Icon(Icons.filter_alt, color: Colors.blue)
                                : Icon(Icons.calendar_today),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _startDateInService == null && _endDateInService == null
                                    ? 'Select date range'
                                    : '${_startDateInService != null ? _formatDate(_startDateInService!) : ''}'
                                        ' - '
                                        '${_endDateInService != null ? _formatDate(_endDateInService!) : ''}',
                              ),
                              if (_startDateInService != null || _endDateInService != null)
                                IconButton(
                                  icon: Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    setState(() {
                                      _startDateInService = null;
                                      _endDateInService = null;
                                      _applyFiltersInService();
                                    });
                                  },
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _isLoading && _inServiceReservas.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredInServiceReservas.isEmpty
                        ? const Center(child: Text('No in-service reservations found'))
                        : _isGridView
                            ? GridView.builder(
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 4,
                                  crossAxisSpacing: 8.0,
                                  mainAxisSpacing: 8.0,
                                  childAspectRatio: 1.5,
                                ),
                                itemCount: _filteredInServiceReservas.length + (_hasMore ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (index >= _filteredInServiceReservas.length) {
                                    return _isLoading
                                        ? const Center(child: CircularProgressIndicator())
                                        : Container();
                                  }
                                  return _buildReservaCard(_filteredInServiceReservas[index], true);
                                },
                              )
                            : ListView.builder(
                                itemCount: _filteredInServiceReservas.length + (_hasMore ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (index >= _filteredInServiceReservas.length) {
                                    return _isLoading
                                        ? const Center(child: CircularProgressIndicator())
                                        : Container();
                                  }
                                  return _buildReservaCard(_filteredInServiceReservas[index], true);
                                },
                              ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class UserService {
  Future<User> getUserByName(int userId) async {
    final response = await http.get(Uri.parse('${dotenv.env['BASE_URL']}/user/$userId'));

    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load user');
    }
  }
}