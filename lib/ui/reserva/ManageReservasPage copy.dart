import 'dart:convert';
import 'dart:typed_data';
import 'package:app/models/VeiculoDetails.dart';
import 'package:app/models/Veiculoimg.dart';
import 'package:app/services/VeiculoAddService.dart';
import 'package:app/services/VeiculoImgService.dart';
import 'package:app/ui/reserva/PaymentAndDeliveryLocation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:app/services/ReservaService.dart';
import 'package:app/ui/reserva/AddNewReservaPage.dart';
import 'package:app/models/Veiculo.dart';
import 'package:intl/intl.dart';
import '../../models/Reserva.dart' hide Veiculo;

class ManageReservasPage extends StatefulWidget {
  const ManageReservasPage({super.key});

  @override
  _ManageReservasPageState createState() => _ManageReservasPageState();
}

class _ManageReservasPageState extends State<ManageReservasPage> with SingleTickerProviderStateMixin {
  final ReservaService _reservaService = ReservaService(dotenv.env['BASE_URL']!);
  List<Reserva> _reservas = [];
  List<Reserva> _filteredReservas = [];
  int _currentPage = 1;
  final int _pageSize = 10;
  bool _hasMore = true;
  bool _isLoading = false;
  String _searchQuery = '';
  bool _isGridView = true;
  DateTime? _startDate;
  DateTime? _endDate;
  late TabController _tabController;
  List<Reserva> _confirmedReservas = []; // Nova lista para reservas confirmadas
  List<Reserva> _filteredConfirmedReservas = []; // Lista filtrada de reservas confirmadas
  DateTime? _startDateConfirmed;
  DateTime? _endDateConfirmed;
  String _destinationFilterConfirmed = '';
  String _matriculaFilterConfirmed = '';
  bool _isConfirmingReserva = false; // Adicione esta linha
  int? _currentlyProcessingReservaId; // Adicione esta linha para controlar qual reserva está sendo processada

  final TextEditingController _searchController = TextEditingController();
  String _destinationFilter = '';
  String _matriculaFilter = '';
  String _dateFilter = '';
  bool _isLoadingConfirmed = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchReservas();
    _applyFiltersConfirmed();
    _fetchConfirmedReservation();
    _searchController.addListener(() {
      _onSearchChanged(_searchController.text);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
        reservas = reservas
            .where((reserva) => reserva.state == "Not Confirmed")
            .toList();

        if (reservas.isEmpty) {
          _hasMore = false;
        } else {
          _reservas.addAll(reservas);
          _filteredReservas = _reservas;
          _applyFilters();
          _currentPage++;
        }
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching reservas: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Atualize o método para aplicar filtros nas reservas confirmadas
void _applyFiltersConfirmed() {
  print('Applying filters with dates: $_startDateConfirmed to $_endDateConfirmed');
  setState(() {
    _filteredConfirmedReservas = _confirmedReservas.where((reserva) {
      final reservaDate = reserva.date;
      print('Checking reservation date: $reservaDate');
      
      final matchesDestination = reserva.destination
          .toLowerCase()
          .contains(_destinationFilterConfirmed.toLowerCase());
      final matchesMatricula = reserva.veiculo.matricula
          .toLowerCase()
          .contains(_matriculaFilterConfirmed.toLowerCase());
      
      bool matchesDate = true;
      if (_startDateConfirmed != null || _endDateConfirmed != null) {
        DateTime reservaDateTime;
        if (reserva.date is String) {
          reservaDateTime = DateTime.parse(reserva.date as String);
        } else {
          reservaDateTime = reserva.date;
        }

        if (_startDateConfirmed != null && _endDateConfirmed != null) {
          matchesDate = reservaDateTime.isAfter(_startDateConfirmed!.subtract(const Duration(days: 1))) && 
                      reservaDateTime.isBefore(_endDateConfirmed!.add(const Duration(days: 1)));
        } else if (_startDateConfirmed != null) {
          matchesDate = reservaDateTime.isAfter(_startDateConfirmed!.subtract(const Duration(days: 1)));
        } else if (_endDateConfirmed != null) {
          matchesDate = reservaDateTime.isBefore(_endDateConfirmed!.add(const Duration(days: 1)));
        }
      }

      print('Matches: destination=$matchesDestination, matricula=$matchesMatricula, date=$matchesDate');
      return matchesDestination && matchesMatricula && matchesDate;
    }).toList();
  });
}

// Atualize o método para selecionar intervalo de datas na segunda tab
Future<void> _selectDateRangeConfirmed(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: _startDateConfirmed != null && _endDateConfirmed != null
          ? DateTimeRange(start: _startDateConfirmed!, end: _endDateConfirmed!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDateConfirmed = picked.start;
        _endDateConfirmed = picked.end;
        _applyFiltersConfirmed();
      });
    }
  }



  Future<void> _fetchConfirmedReservation() async {
  if (_isLoadingConfirmed) return;

  setState(() {
    _isLoadingConfirmed = true;
  });

  try {
    List<Reserva> reservas = await _reservaService.getReservas(
      page: _currentPage,
      pageSize: _pageSize,
    );

    setState(() {
      _confirmedReservas = reservas
          .where((reserva) => reserva.state == "Confirmed")
          .toList();
      _filteredConfirmedReservas = _confirmedReservas;
      _applyFiltersConfirmed(); // Aplica os filtros após carregar
      _isLoadingConfirmed = false;
    });
  } catch (e) {
    print('Error fetching confirmed reservas: $e');
    setState(() {
      _isLoadingConfirmed = false;
    });
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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        _applyFilters();
      });
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredReservas = _reservas.where((reserva) {
        final reservaDate = reserva.date;
        
        final matchesDestination = reserva.destination
            .toLowerCase()
            .contains(_destinationFilter.toLowerCase());
        final matchesMatricula = reserva.veiculo.matricula
            .toLowerCase()
            .contains(_matriculaFilter.toLowerCase());
        
        bool matchesDate = true;
        if (_startDate != null && _endDate != null) {
          matchesDate = reservaDate.isAfter(_startDate!.subtract(const Duration(days: 1))) && 
                       reservaDate.isBefore(_endDate!.add(const Duration(days: 1)));
        } else if (_startDate != null) {
          matchesDate = reservaDate.isAfter(_startDate!.subtract(const Duration(days: 1)));
        } else if (_endDate != null) {
          matchesDate = reservaDate.isBefore(_endDate!.add(const Duration(days: 1)));
        }

        return matchesDestination && matchesMatricula && matchesDate;
      }).toList();
    });
  }

  void _onSearchChanged(String value) {
    setState(() {
      _destinationFilter = value;
    });
    _applyFilters();
  }

  void _onMatriculaChanged(String value) {
    setState(() {
      _matriculaFilter = value;
    });
    _applyFilters();
  }

  void _onDateChanged(String value) {
    setState(() {
      _dateFilter = value;
    });
    _applyFilters();
  }

  void _showVeiculoDetailsDialog(Veiculo veiculo) async {
    final veiculoImgService = VeiculoImgService(dotenv.env['BASE_URL']!);
    final veiculoServiceAdd = VeiculoServiceAdd(dotenv.env['BASE_URL']!);
    
    List<VeiculoImg> imagensAdicionais = [];
    List<VeiculoDetails> veiculoDetails = [];

    Future<void> fetchImages() async {
      try {
        final images = await veiculoImgService.fetchImagesByVehicleId(veiculo.id);
        setState(() {
          imagensAdicionais = images;
        });
      } catch (e) {
        print('Failed to fetch images: $e');
      }
    }

    Future<void> fetchDetails() async {
      try {
        final details = await veiculoServiceAdd.fetchDetailsByVehicleId(veiculo.id);
        setState(() {
          veiculoDetails = details;
        });
      } catch (e) {
        print('Failed to fetch details: $e');
      }
    }

    await fetchImages();
    await fetchDetails();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(veiculo.matricula),
          content: SizedBox(
            width: 600,
            child: DefaultTabController(
              length: 4,
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
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey),
                          ),
                          child: veiculo.imagemBase64.isNotEmpty
                              ? Image.memory(
                                  base64Decode(veiculo.imagemBase64),
                                  fit: BoxFit.cover,
                                )
                              : const Center(child: Icon(Icons.car_repair, size: 40, color: Colors.grey)),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              veiculo.matricula,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${veiculo.marca} ${veiculo.modelo}',
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
                      Tab(icon: Icon(Icons.info)),
                      Tab(icon: Icon(Icons.description)),
                      Tab(icon: Icon(Icons.photo_library)),
                      Tab(icon: Icon(Icons.calendar_today)),
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
                              _buildDetailRow(Icons.confirmation_number, 'ID', veiculo.id.toString()),
                              _buildDetailRow(Icons.directions_car, 'License Plate', veiculo.matricula),
                              _buildDetailRow(Icons.branding_watermark, 'Brand', veiculo.marca),
                              _buildDetailRow(Icons.model_training, 'Model', veiculo.modelo),
                              _buildDetailRow(Icons.calendar_today, 'Year', veiculo.ano.toString()),
                              _buildDetailRow(Icons.color_lens, 'Color', veiculo.cor),
                              _buildDetailRow(Icons.confirmation_number, 'Chassis Number', veiculo.numChassi.toString()),
                              _buildDetailRow(Icons.people, 'Number of Seats', veiculo.numLugares.toString()),
                              _buildDetailRow(Icons.engineering, 'Engine Number', veiculo.numMotor.toString()),
                              _buildDetailRow(Icons.door_front_door_outlined, 'Number of Doors', veiculo.numPortas.toString()),
                              _buildDetailRow(Icons.local_gas_station, 'Fuel Type', veiculo.tipoCombustivel),
                              _buildDetailRow(Icons.info, 'Status', veiculo.state),
                            ],
                          ),
                        ),
                        
                        SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'General Information',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (veiculoDetails.isNotEmpty)
                                ...veiculoDetails.map((detail) {
                                  return Card(
                                    margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    elevation: 3,
                                    child: Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                flex: 2,
                                                child: Text(
                                                  detail.description ?? 'N/A',
                                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                flex: 1,
                                                child: Text(
                                                  detail.startDate != null
                                                      ? detail.startDate.toString().split(' ')[0]
                                                      : 'N/A',
                                                  style: const TextStyle(color: Colors.grey),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                flex: 1,
                                                child: Text(
                                                  detail.endDate != null
                                                      ? detail.endDate.toString().split(' ')[0]
                                                      : 'N/A',
                                                  style: const TextStyle(color: Colors.grey),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              Expanded(
                                                flex: 2,
                                                child: Text(
                                                  detail.obs ?? 'N/A',
                                                  style: const TextStyle(color: Colors.grey),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.delete, color: Colors.red),
                                                onPressed: () {
                                                  setState(() {
                                                    veiculoDetails.remove(detail);
                                                  });
                                                },
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                            ],
                          ),
                        ),
                        
                        SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Additional Images',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              imagensAdicionais.isNotEmpty
                                  ? GridView.builder(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 3,
                                        crossAxisSpacing: 8,
                                        mainAxisSpacing: 8,
                                        childAspectRatio: 1,
                                      ),
                                      itemCount: imagensAdicionais.length,
                                      itemBuilder: (context, index) {
                                        final veiculoImg = imagensAdicionais[index];
                                        return GestureDetector(
                                          onTap: () {},
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: Image.memory(
                                              base64Decode(veiculoImg.imageBase64),
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        );
                                      },
                                    )
                                  : const Center(child: Text('No additional images available.')),
                            ],
                          ),
                        ),
                        
                        SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Reservation Information',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              _buildDetailRow(Icons.calendar_today, 'Next Available', '2023-12-01'),
                              _buildDetailRow(Icons.money, 'Daily Rate', '\$120.00'),
                              _buildDetailRow(Icons.star, 'Rating', '4.8/5 (23 reviews)'),
                              _buildDetailRow(Icons.local_gas_station, 'Fuel Policy', 'Full-to-Full'),
                              _buildDetailRow(Icons.people, 'Minimum Age', '21 years'),
                              _buildDetailRow(Icons.credit_card, 'Deposit Required', '\$500.00'),
                              
                              const SizedBox(height: 20),
                              const Text(
                                'Vehicle Specifications',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildDetailRow(Icons.speed, 'Engine', '2.0L Turbo'),
                              _buildDetailRow(Icons.directions_car, 'Transmission', 'Automatic'),
                              _buildDetailRow(Icons.airline_seat_recline_normal, 'Seats', '5'),
                              _buildDetailRow(Icons.luggage, 'Luggage', '2 Large Bags'),
                              
                              const SizedBox(height: 20),
                              const Text(
                                'Policies',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildDetailRow(Icons.warning, 'Cancellation', 'Free up to 24h before'),
                              _buildDetailRow(Icons.security, 'Insurance', 'Full Coverage Included'),
                              _buildDetailRow(Icons.smoke_free, 'Smoking', 'Strictly Prohibited'),
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
              style: TextButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
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

  Uint8List _getDecodedImage(String base64Image) {
    try {
      String base64String = _removeDataPrefix(base64Image);
      base64String = _addPadding(base64String);
      return base64Decode(base64String);
    } catch (e) {
      print("Erro ao decodificar a imagem: $e");
      return Uint8List(0);
    }
  }

  String _removeDataPrefix(String base64String) {
    if (base64String.startsWith('data:image')) {
      int index = base64String.indexOf(',');
      return base64String.substring(index + 1);
    }
    return base64String;
  }

  String _addPadding(String base64String) {
    int padding = base64String.length % 4;
    if (padding != 0) {
      base64String = base64String.padRight(base64String.length + (4 - padding), '=');
    }
    return base64String;
  }

  Future<void> _confirmReserva(int reservaId) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Reservation'),
          content: const Text('Do you want to confirm this reservation?'),
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
        await _reservaService.confirmReserva(reservaId.toString());

        setState(() {
          _reservas = _reservas.map((reserva) {
            if (reserva.id == reservaId) {
              reserva.state = 'Confirmed';
            }
            return reserva;
          }).toList();
          _filteredReservas = _reservas;
        });

        Reserva reserva = _reservas.firstWhere((r) => r.id == reservaId);
        
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentAndDeliveryLocation(
              reservaId: reservaId,
              userId: reserva.userId,
              veiculoId: reserva.veiculoId,
            ),
          ),
        );

      } catch (e, stackTrace) {
        print('Exception occurred while confirming reservation: ${e.toString()}');
        print('StackTrace: $stackTrace');
      }
    }
  }

  void _showAddNewReservaForm() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.height * 0.8,
            child: AddNewReservaForm(
              onReserve: (veiculo, date, destination, numberOfDays, userId) {
                setState(() {});
              },
              onSelect: (veiculo) {
                setState(() {});
              },
            ),
          ),
        );
      },
    );
  }

  void _goToPreviousPage() {
    if (_currentPage > 1) {
      setState(() {
        _currentPage--;
      });
      _fetchReservas();
    }
  }

  void _goToNextPage() {
    if (_hasMore) {
      setState(() {
        _currentPage++;
      });
      _fetchReservas();
    }
  }

  Future<void> _deleteReserva(int reservaId) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Reservation'),
          content: const Text('Are you sure you want to delete this reservation?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        await _reservaService.deleteReserva(reservaId);

        setState(() {
          _reservas.removeWhere((reserva) => reserva.id == reservaId);
          _filteredReservas = _reservas;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reservation deleted successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete reservation: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Reservations'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.list), text: 'Reservations'),
            Tab(icon: Icon(Icons.analytics), text: 'Confirmed Reservations'),
          ],
        ),
        actions: [
          if (_tabController.index == 0)
            IconButton(
              icon: Icon(
                _isGridView ? Icons.list : Icons.grid_view,
                color: Colors.white,
              ),
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
          // Primeira Tab - Lista de Reservas
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          labelText: 'Search Destination',
                          prefixIcon: Icon(Icons.search),
                        ),
                        onChanged: _onSearchChanged,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText: 'Matricula',
                        ),
                        onChanged: _onMatriculaChanged,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectDateRange(context),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Date Range',
                            border: OutlineInputBorder(),
                            suffixIcon: _startDate != null || _endDate != null
                                ? Icon(Icons.filter_alt, color: Colors.blue)
                                : Icon(Icons.calendar_today),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _startDate == null && _endDate == null
                                    ? 'Select date range'
                                    : '${_startDate != null ? DateFormat('yyyy-MM-dd').format(_startDate!) : ''}'
                                        ' - '
                                        '${_endDate != null ? DateFormat('yyyy-MM-dd').format(_endDate!) : ''}',
                              ),
                              if (_startDate != null || _endDate != null)
                                IconButton(
                                  icon: Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    setState(() {
                                      _startDate = null;
                                      _endDate = null;
                                      _applyFilters();
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
                child: _filteredReservas.isEmpty && !_isLoading
                    ? const Center(child: Text('No reservations found'))
                    : _isGridView
                        ? GridView.builder(
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                              childAspectRatio: 1.5,
                            ),
                            itemCount: _filteredReservas.length + (_hasMore ? 0 : 1),
                            itemBuilder: (context, index) {
                              var reserva = _filteredReservas[index];
                              return Card(
                                margin: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ListTile(
                                      title: Text('Reserva ID: ${reserva.id}'),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Client: ${reserva.user.firstName}'),
                                          Text('Destination: ${reserva.destination}'),
                                          Text('Reserve Date: ${reserva.date}'),
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
                                                      print('Erro ao buscar detalhes do usuário: $error');
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
                                                'Veiculo: ${reserva.veiculo.matricula}',
                                                style: const TextStyle(fontWeight: FontWeight.bold),
                                              ),
                                              const SizedBox(width: 8.0),
                                              Tooltip(
                                                message: 'See more vehicle details',
                                                child: IconButton(
                                                  onPressed: () async {
                                                    try {
                                                      VeiculoService veiculoService = VeiculoService();
                                                      Veiculo veiculoDetails = await veiculoService.getVeiculoByMatricula(reserva.veiculo.matricula);
                                                      _showVeiculoDetailsDialog(veiculoDetails);
                                                    } catch (error) {
                                                      print('Erro ao buscar detalhes do veículo: $error');
                                                    }
                                                  },
                                                  icon: const Icon(Icons.arrow_forward),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (reserva.state == 'Not Confirmed')
                                            Tooltip(
                                              message: 'Confirm reservation',
                                              child: Material(
                                                color: Colors.lightBlue,
                                                shape: const CircleBorder(),
                                                child: InkWell(
                                                  borderRadius: BorderRadius.circular(50),
                                                  onTap: () => _confirmReserva(reserva.id),
                                                  child: const Padding(
                                                    padding: EdgeInsets.all(8.0),
                                                    child: Icon(Icons.check, color: Colors.white),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          Tooltip(
                                            message: 'Delete reservation',
                                            child: Material(
                                              color: Colors.redAccent,
                                              shape: const CircleBorder(),
                                              child: InkWell(
                                                borderRadius: BorderRadius.circular(50),
                                                onTap: () => _deleteReserva(reserva.id),
                                                child: const Padding(
                                                  padding: EdgeInsets.all(8.0),
                                                  child: Icon(Icons.delete_forever, color: Colors.white),
                                                ),
                                              ),
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          )
                        : ListView.builder(
                            itemCount: _filteredReservas.length + (_hasMore ? 0 : 1),
                            itemBuilder: (context, index) {
                              var reserva = _filteredReservas[index];
                              return Card(
                                margin: const EdgeInsets.all(8.0),
                                child: ListTile(
                                  title: Text('Reserva ID: ${reserva.id}'),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Client: ${reserva.user.firstName}'),
                                      Text('Destination: ${reserva.destination}'),
                                      Text('Reserve Date: ${reserva.date}'),
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
                                                  print('Erro ao buscar detalhes do usuário: $error');
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
                                            'Veiculo: ${reserva.veiculo.matricula}',
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(width: 8.0),
                                          Tooltip(
                                            message: 'See more vehicle details',
                                            child: IconButton(
                                              onPressed: () async {
                                                try {
                                                  VeiculoService veiculoService = VeiculoService();
                                                  Veiculo veiculoDetails = await veiculoService.getVeiculoByMatricula(reserva.veiculo.matricula);
                                                  _showVeiculoDetailsDialog(veiculoDetails);
                                                } catch (error) {
                                                  print('Erro ao buscar detalhes do veículo: $error');
                                                }
                                              },
                                              icon: const Icon(Icons.arrow_forward),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (reserva.state == 'Not Confirmed')
                                        Tooltip(
                                          message: 'Confirm reservation',
                                          child: Material(
                                            color: Colors.lightBlue,
                                            shape: const CircleBorder(),
                                            child: InkWell(
                                              borderRadius: BorderRadius.circular(50),
                                              onTap: () => _confirmReserva(reserva.id),
                                              child: const Padding(
                                                padding: EdgeInsets.all(8.0),
                                                child: Icon(Icons.check, color: Colors.white),
                                              ),
                                            ),
                                          ),
                                        ),
                                      Tooltip(
                                        message: 'Delete reservation',
                                        child: Material(
                                          color: Colors.redAccent,
                                          shape: const CircleBorder(),
                                          child: InkWell(
                                            borderRadius: BorderRadius.circular(50),
                                            onTap: () => _deleteReserva(reserva.id),
                                            child: const Padding(
                                              padding: EdgeInsets.all(8.0),
                                              child: Icon(Icons.delete_forever, color: Colors.white),
                                            ),
                                          ),
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
              ),
              
              if (_isLoading)
                const CircularProgressIndicator()
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: _goToPreviousPage,
                      icon: const Icon(Icons.arrow_back),
                    ),
                    IconButton(
                      onPressed: _goToNextPage,
                      icon: const Icon(Icons.arrow_forward),
                    ),
                  ],
                ),
            ],
          ),

          // Segunda Tab - Reservas Confirmadas
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
                          labelText: 'Matricula',
                        ),
                        onChanged: (value) {
                          setState(() {
                            _matriculaFilterConfirmed = value;
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
                                    : '${_startDateConfirmed != null ? DateFormat('yyyy-MM-dd').format(_startDateConfirmed!) : ''}'
                                        ' - '
                                        '${_endDateConfirmed != null ? DateFormat('yyyy-MM-dd').format(_endDateConfirmed!) : ''}',
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
                child: _filteredConfirmedReservas.isEmpty && !_isLoading
                    ? const Center(child: Text('No confirmed reservations found'))
                    : ListView.builder(
                        itemCount: _filteredConfirmedReservas.length,
                        itemBuilder: (context, index) {
                          var reserva = _filteredConfirmedReservas[index];
                          return Card(
                            margin: const EdgeInsets.all(8.0),
                            child: ListTile(
                              title: Text('Reservation #${reserva.id}'),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Client: ${reserva.user.firstName} ${reserva.user.lastName}'),
                                  Text('Destination: ${reserva.destination}'),
                                  Text('Date: ${DateFormat('yyyy-MM-dd').format(reserva.date)}'),
                                  Text('Days: ${reserva.numberOfDays}'),
                                  Row(
                                    children: [
                                      Chip(
                                        label: Text(
                                          'Confirmed',
                                          style: const TextStyle(color: Colors.white),
                                        ),
                                        backgroundColor: Colors.green,
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
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.visibility),
                                    color: Colors.blue,
                                    onPressed: () {
                                      _showReservationDetails(reserva);
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.print),
                                    color: Colors.grey,
                                    onPressed: () {
                                      _printReservation(reserva);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              if (_isLoading)
                const CircularProgressIndicator()
            ],
          ),
        ],
      ),
        
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton(
              onPressed: _showAddNewReservaForm,
              backgroundColor: Colors.blue,
              tooltip: 'Add New Reservation',
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  // Método auxiliar para mostrar detalhes da reserva
void _showReservationDetails(Reserva reserva) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('Reservation #${reserva.id}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailItem(Icons.person, 'Client:', '${reserva.user.firstName} ${reserva.user.lastName}'),
              _buildDetailItem(Icons.place, 'Destination:', reserva.destination),
              _buildDetailItem(Icons.date_range, 'Date:', DateFormat('yyyy-MM-dd').format(reserva.date)),
              _buildDetailItem(Icons.calendar_view_day, 'Days:', reserva.numberOfDays.toString()),
              _buildDetailItem(Icons.car_rental, 'Vehicle:', '${reserva.veiculo.marca} ${reserva.veiculo.modelo} (${reserva.veiculo.matricula})'),
              _buildDetailItem(Icons.payment, 'Payment Status:', reserva.isPaid),
              _buildDetailItem(Icons.star, 'Status:', reserva.state),
            ],
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

// Método auxiliar para construir itens de detalhe
Widget _buildDetailItem(IconData icon, String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: Row(
      children: [
        Icon(icon, size: 20, color: Colors.blue),
        const SizedBox(width: 16),
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 16,
            ),
          ),
        ),
      ],
    ),
  );
}

// Método auxiliar para imprimir reserva (simulado)
void _printReservation(Reserva reserva) {
  // Implemente a lógica de impressão aqui
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Printing reservation #${reserva.id}...')),
  );
}

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildRecentReservationsList() {
    final recentReservas = _reservas.take(5).toList();
    
    if (recentReservas.isEmpty) {
      return [
        const Center(
          child: Text('No recent reservations'),
        ),
      ];
    }
    
    return recentReservas.map((reserva) {
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: reserva.state == 'Confirmed' 
                ? Colors.green 
                : Colors.orange,
            child: Icon(
              reserva.state == 'Confirmed' 
                  ? Icons.check 
                  : Icons.pending,
              color: Colors.white,
            ),
          ),
          title: Text('Reservation #${reserva.id}'),
          subtitle: Text('${reserva.destination} - ${reserva.date}'),
          trailing: Chip(
            label: Text(
              reserva.isPaid,
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: reserva.isPaid == 'Paid'
                ? Colors.green
                : Colors.red,
          ),
        ),
      );
    }).toList();
  }
}

extension on DateTime {
  toLowerCase() {}
}

class VeiculoService {
  Future<Veiculo> getVeiculoByMatricula(String matricula) async {
    final response = await http.get(Uri.parse('${dotenv.env['BASE_URL']}/veiculo/matricula/$matricula'));
    if (response.statusCode == 200) {
      // Supondo que a resposta seja JSON e que você tenha um método Veiculo.fromJson
      return Veiculo.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load vehicle');
    }
  }
}

class UserService {
  Future<User> getUserByName(int userId) async {
    final response = await http.get(Uri.parse('${dotenv.env['BASE_URL']}/user/$userId'));

    if (response.statusCode == 200) {
      // Supondo que a resposta seja JSON e que você tenha um método Veiculo.fromJson
      return User.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load vehicle');
    }
  }
}