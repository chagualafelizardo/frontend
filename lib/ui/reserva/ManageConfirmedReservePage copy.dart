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
    extends State<ManageConfirmedReservasPage> {
  final ReservaService _reservaService =
      ReservaService(dotenv.env['BASE_URL']!);

  final VeiculoService _veiculoService =  
  VeiculoService(dotenv.env['BASE_URL']!);

  final VeiculoImgService _veiculoImgService = 
  VeiculoImgService(dotenv.env['BASE_URL']!);

  List<Reserva> _reservas = [];
  List<Reserva> _filteredReservas = [];
  int _currentPage = 1;
  final int _pageSize = 10;
  bool _hasMore = true;
  bool _isLoading = false;
  int? _selectedVehicleId; // Armazena qual veículo está expandido
  bool _isLoadingImages = false;

  // Filtros
  String _destinationFilter = '';
  String _stateFilter = '';
  String _vehicleFilter = '';
  String _userFilter = '';
  bool _isGridView = true;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _selectedVehicleId = null;
    _fetchReservas();
  }

void _applyFilters() {
  setState(() {
    _filteredReservas = _reservas.where((reserva) {
      // Converter a string da reserva para DateTime
      final reservaDate = reserva.date;
      
      final matchesDestination = reserva.destination
          .toLowerCase()
          .contains(_destinationFilter.toLowerCase());
      
      bool matchesDate = true;
      if (_startDate != null && _endDate != null) {
        matchesDate = reservaDate.isAfter(_startDate!.subtract(const Duration(days: 1))) && 
                     reservaDate.isBefore(_endDate!.add(const Duration(days: 1)));
      } else if (_startDate != null) {
        matchesDate = reservaDate.isAfter(_startDate!.subtract(const Duration(days: 1)));
      } else if (_endDate != null) {
        matchesDate = reservaDate.isBefore(_endDate!.add(const Duration(days: 1)));
      }

      return matchesDestination && matchesDate;
    }).toList();
  });
}
  // Método para abrir o DatePicker e selecionar a data
Future<void> _selectDate(BuildContext context) async {
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
        _applyFilters(); // Aplica os filtros imediatamente após seleção
      });
    }
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
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
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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

  void _showFullScreenImage(BuildContext context, String currentImage, List<String> allImages, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(),
          body: PageView.builder(
            itemCount: allImages.length,
            controller: PageController(initialPage: initialIndex),
            itemBuilder: (context, index) {
              return InteractiveViewer(
                child: Center(
                  child: Image.memory(
                    base64Decode(allImages[index]),
                    fit: BoxFit.contain,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
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
          // Filtra apenas reservas confirmadas E com inService == 'No'
          _reservas.addAll(reservas.where((reserva) => 
            reserva.state == 'Confirmed' && reserva.inService == 'No'));
          
          // Ordena por ID decrescente
          _reservas.sort((a, b) => b.id.compareTo(a.id));
          
          _currentPage++;
        }
        _isLoading = false;
        _applyFilters(); // Aplica os filtros após carregar
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
          content:
              const Text('Do you want to undo the reservation confirmation?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false), // Cancelar
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true), // Confirmar
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );

    // Se o usuário confirmar
    if (confirm == true) {
      print("User confirmed reservation with ID: $reservaId");
      try {
        print("Attempting to confirm the reservation via the service...");

        await _reservaService.unconfirmReserva(reservaId.toString());
        await _reservaService.updateInService(
          reservaId: reservaId,
          inService: 'No',
        );

    /* Processo de Pagamento Confirmacao  */
        await _reservaService.updateIsPaid(
              reservaId: reservaId,
              isPaid: 'Not Paid',
        );
        print("Reservation confirmed successfully on the server.");

    /* Atualizar o estado de ocupacao do veiculo */
        // await _veiculoService.updateVehicleState(3,'Free');
        // print("Vihecle Free state confirmed successfully on the server.");

        // Atualiza o estado localmente
        setState(() {
          print("Updating local reservation state to 'Not Confirmed'.");
          _reservas = _reservas.map((reserva) {
            if (reserva.id == reservaId) {
              reserva.state = 'Not Confirmed';
              print("Reservation ID $reservaId updated to Not Confirmed.");
            }
            return reserva;
          }).toList();
        });
      } catch (e, stackTrace) {
        // Captura o erro e imprime o rastreamento da pilha
        print(
            'Exception occurred while confirming reservation: ${e.toString()}');
        print('StackTrace: $stackTrace');
      }
    } else {
      print("User cancelled the reservation confirmation.");
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
          width: 600, // Largura ajustada do diálogo
          child: DefaultTabController(
            length: 2,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Cabeçalho com nome e imagem do usuário
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
                // Abas
                const TabBar(
                  tabs: [
                    Tab(text: 'User Info'),
                    Tab(text: 'General Info'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      // Aba "User Info"
                      SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // _buildDetailRow(Icons.person, 'ID', user.id),
                            _buildDetailRow(Icons.person_outline, 'First Name', user.firstName),
                            _buildDetailRow(Icons.person_outline, 'Last Name', user.lastName),
                            _buildDetailRow(Icons.email, 'Email', user.email),
                            _buildDetailRow(Icons.phone, 'Phone 1', user.phone1),
                            _buildDetailRow(Icons.phone, 'Phone 2', user.phone2),
                            _buildDetailRow(Icons.location_on, 'Address', user.address),
                          ],
                        ),
                      ),
                      // Aba "General Info"
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
              Navigator.of(context).pop(); // Fecha o diálogo
            },
            child: const Text('Close'),
          ),
        ],
      );
    },
  );
}

// Função para obter a imagem decodificada
Uint8List _getDecodedImage(String base64Image) {
  try {
    // Remover o prefixo data:image/*;base64, se presente
    String base64String = _removeDataPrefix(base64Image);
    // Adicionar padding, caso necessário, antes de decodificar
    base64String = _addPadding(base64String);
    // Decodificar a imagem
    return base64Decode(base64String);
  } catch (e) {
    print("Erro ao decodificar a imagem: $e");
    return Uint8List(0); // Retorna um Uint8List vazio se houver erro
  }
}

// Função para remover o prefixo "data:image/*;base64,"
String _removeDataPrefix(String base64String) {
  if (base64String.startsWith('data:image')) {
    int index = base64String.indexOf(',');
    return base64String.substring(index + 1);
  }
  return base64String;
}

// Função para adicionar padding ao base64, se necessário
String _addPadding(String base64String) {
  int padding = base64String.length % 4;
  if (padding != 0) {
    base64String = base64String.padRight(base64String.length + (4 - padding), '=');
  }
  return base64String;
}

  Future<void> _advanceProcess(int reservaId) async {
    // Encontre a reserva correspondente pelo ID
    Reserva? reserva =
        _reservas.firstWhere((reserva) => reserva.id == reservaId);

    // Obtenha ou crie o objeto 'Atendimento' aqui
    Atendimento atendimento =
        Atendimento(reserveID: reservaId); // Passando reserveID

    // Abra o formulário e passe os dados da reserva
    showDialog(
      context: context,
      builder: (context) {
        return AtendimentoForm(
          atendimento: atendimento, // Passando o atendimento corretamente
          reserva: reserva, // Passando a reserva corretamente
          onProcessStart:
              (dataSaida, dataChegada, destino, kmInicial) async {
            try {
              // Chame o serviço para iniciar o processo de atendimento
              await _reservaService.startAtendimento(
                reservaId: reservaId,
                dataSaida: dataSaida,
                dataChegada: dataChegada,
                destino: destino,
                kmInicial: kmInicial,
              );

              print("Rental process started for reservation ID: $reservaId");
            } catch (e) {
              print('Error starting rental process: $e');
            }
          },
        );
      },
    );
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
                // Lógica para adicionar uma nova reserva
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Reservations'),
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
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(labelText: 'Destination'),
                  onChanged: (value) {
                    setState(() {
                      _destinationFilter = value;
                      _fetchReservas();
                    });
                  },
                ),
              ),
              const SizedBox(width: 8.0),
              Expanded(
                child: InkWell(
                  onTap: () => _selectDate(context),
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
                              : '${_startDate != null ? _formatDate(_startDate!) : ''}'
                                  ' - '
                                  '${_endDate != null ? _formatDate(_endDate!) : ''}',
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
            child: _isLoading && _reservas.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _filteredReservas.isEmpty
                    ? const Center(child: Text('No reservations found for selected filters'))
                    : _isGridView
                        ? GridView.builder(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4,
                              crossAxisSpacing: 8.0,
                              mainAxisSpacing: 8.0,
                              childAspectRatio: 1.5,
                            ),
                            itemCount: _filteredReservas.length + (_hasMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index >= _filteredReservas.length) {
                                return _isLoading
                                    ? const Center(child: CircularProgressIndicator())
                                    : Container();
                              }
                              return _buildReservaCard(_filteredReservas[index]);
                            },
                          )
                        : ListView.builder(
                            itemCount: _filteredReservas.length + (_hasMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index >= _filteredReservas.length) {
                                return _isLoading
                                    ? const Center(child: CircularProgressIndicator())
                                    : Container();
                              }
                              return _buildReservaCard(_filteredReservas[index]);
                            },
                          ),
          )
        ],
      ),
    );
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
        child: SingleChildScrollView( // <- ENVOLVENDO AQUI
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


  @override
  Widget _buildReservaCard(Reserva reserva) {
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
                  // Estado da reserva
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
                  // Status de pagamento
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
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Tooltip(
                message: reserva.isPaid == "Not Paid"
                    ? 'The reservation is not paid, cannot proceed to the rental process. You must go back to the booking process and register the payment.' 
                    : 'The reservation has already been paid, you can now proceed with the rental process. Click on the button to proceed with the process.',
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
        
        // ExpansionTile com detalhes do veículo
        if (_selectedVehicleId == reserva.veiculo.id)
          _buildVehicleExpansionTile(reserva.veiculo),
      ],
    ),
  );
}
    }


// class VeiculoServices {
//   Future<Veiculo> getVeiculoByMatricula(String matricula) async {
//     final response = await http.get(Uri.parse('${dotenv.env['BASE_URL']}/veiculo/matricula/$matricula'));
//     if (response.statusCode == 200) {
//       // Supondo que a resposta seja JSON e que você tenha um método Veiculo.fromJson
//       return Veiculo.fromJson(jsonDecode(response.body));
//     } else {
//       throw Exception('Failed to load vehicle');
//     }
//   }
// }


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

