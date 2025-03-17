import 'dart:convert';
import 'dart:typed_data';
import 'package:app/models/Veiculoimg.dart';
import 'package:app/services/VeiculoImgService.dart';
import 'package:app/ui/reserva/AddDeliveryLocation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:app/services/ReservaService.dart';
import 'package:app/ui/reserva/AddNewReservaPage.dart';
import 'package:app/models/Veiculo.dart';
import '../../models/Reserva.dart' hide Veiculo;

class ManageReservasPage extends StatefulWidget {
  const ManageReservasPage({super.key});

  @override
  _ManageReservasPageState createState() => _ManageReservasPageState();
}

class _ManageReservasPageState extends State<ManageReservasPage> {
  final ReservaService _reservaService =
      ReservaService(dotenv.env['BASE_URL']!);

  List<Reserva> _reservas = [];
  List<Reserva> _filteredReservas = [];
  int _currentPage = 1;
  final int _pageSize = 10;
  bool _hasMore = true;
  bool _isLoading = false;
  String _searchQuery = ''; // Variável para armazenar a consulta de pesquisa
  bool _isGridView = true;
  
  final TextEditingController _searchController = TextEditingController();

  String _destinationFilter = '';
  String _stateFilter = '';
  String _userFilter = '';
  String _matriculaFilter = '';

  @override
  void initState() {
    super.initState();
    _fetchReservas();
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
        // Filtrar reservas com state = "Not Confirmed"
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

  // Função para aplicar os filtros de pesquisa
  void _applyFilters() {
    setState(() {
      _filteredReservas = _reservas.where((reserva) {
        final matchesDestination = reserva.destination
            .toLowerCase()
            .contains(_destinationFilter.toLowerCase());
        final matchesState = reserva.state
            .toLowerCase()
            .contains(_stateFilter.toLowerCase());
        final matchesUser = '${reserva.user.firstName} ${reserva.user.lastName}'
            .toLowerCase()
            .contains(_userFilter.toLowerCase());
        final matchesMatricula = reserva.veiculo.matricula
            .toLowerCase()
            .contains(_matriculaFilter.toLowerCase());

        return matchesDestination ||
            matchesState ||
            matchesUser ||
            matchesMatricula;
      }).toList();
    });
  }

  void _onSearchChanged(String value) {
    setState(() {
      _destinationFilter = value;
    });
    _applyFilters();
  }

  void _onStateChanged(String value) {
    setState(() {
      _stateFilter = value;
    });
    _applyFilters();
  }

  void _onUserChanged(String value) {
    setState(() {
      _userFilter = value;
    });
    _applyFilters();
  }

  void _onMatriculaChanged(String value) {
    setState(() {
      _matriculaFilter = value;
    });
    _applyFilters();
  }

 void _showVeiculoDetailsDialog(Veiculo veiculo) async {
  // Instância do serviço para buscar as imagens
  final veiculoImgService = VeiculoImgService(dotenv.env['BASE_URL']!);

  // Estado para armazenar as imagens adicionais
  List<VeiculoImg> imagensAdicionais = [];

  // Função para buscar as imagens do veículo
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

  // Buscar as imagens ao abrir o diálogo
  await fetchImages();

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(veiculo.matricula),
        content: SizedBox(
          width: 600, // Adjusted dialog width
          child: DefaultTabController(
            length: 3, // Number of tabs
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with license plate and vehicle image
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
                // Tabs
                const TabBar(
                  tabs: [
                    Tab(text: 'Details'),
                    Tab(text: 'General Info'),
                    Tab(text: 'Additional Images'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      // "Details" Tab
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
                      // "General Info" Tab
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
                            _buildDetailRow(Icons.build, 'Regular Maintenance', 'Yes'),
                            _buildDetailRow(Icons.security, 'Active Insurance', 'No'),
                            _buildDetailRow(Icons.calendar_today, 'Last Inspection', '12/08/2024'),
                            _buildDetailRow(Icons.calendar_today, 'Next Inspection', '12/08/2025'),
                            _buildDetailRow(Icons.check_circle, 'Status', 'Operational'),
                          ],
                        ),
                      ),
                      // "Additional Images" Tab
                      // "Additional Images" Tab
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
                            // Exibir as imagens adicionais
                            imagensAdicionais.isNotEmpty
                                ? Column(
                                    children: imagensAdicionais.map((veiculoImg) {
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 8.0),
                                        child: Image.memory(
                                          base64Decode(veiculoImg.imageBase64), // Usando imageBase64
                                          fit: BoxFit.cover,
                                          height: 200,
                                          width: double.infinity-100,
                                        ),
                                      );
                                    }).toList(),
                                  )
                                : const Center(child: Text('No additional images available.')),
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
                Navigator.of(context).pop(); // Fechar o diálogo
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.blue, // Fundo azul
                foregroundColor: Colors.white, // Texto branco
              ),
              child: const Text('Close'),
            ),
        ],
      );
    },
  );
}

// Função auxiliar para construir uma linha de detalhe com ícone
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

// Função auxiliar para construir uma linha de detalhe com ícone

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



  Future<void> _confirmReserva(int reservaId) async {
  bool? confirm = await showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Confirm Reservation'),
        content: const Text('Do you want to confirm this reservation?'),
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

      // Chamada ao serviço para confirmar no backend
      await _reservaService.confirmReserva(reservaId.toString());

      print("Reservation confirmed successfully on the server.");

      // Atualiza o estado localmente
      setState(() {
        print("Updating local reservation state to 'Confirmed'.");
        _reservas = _reservas.map((reserva) {
          if (reserva.id == reservaId) {
            reserva.state = 'Confirmed';
            print("Reservation ID $reservaId updated to Confirmed.");
          }
          return reserva;
        }).toList();
        _filteredReservas = _reservas;
      });

      // **Abrir o formulário para adicionar coordenadas**
      print("Opening AddReservationScreen for adding coordinates...");
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddDeliveryLocation(reservaId: reservaId),
        ),
      );

    } catch (e, stackTrace) {
      // Captura o erro e imprime o rastreamento da pilha
      print('Exception occurred while confirming reservation: ${e.toString()}');
      print('StackTrace: $stackTrace');
    }
  } else {
    print("User cancelled the reservation confirmation.");
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

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Manage Reservations'),
      actions: [
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
    body: Column(
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
                    labelText: 'State',
                  ),
                  onChanged: _onStateChanged,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'User',
                  ),
                  onChanged: _onUserChanged,
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
                                    Text('State: ${reserva.state}'),
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
                                      IconButton(
                                        icon: const Icon(Icons.check),
                                        onPressed: () => _confirmReserva(reserva.id),
                                      ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => _deleteReserva(reserva.id),
                                    ),
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
                                Text('Destination: ${reserva.destination}'),
                                Text('Number of Days: ${reserva.numberOfDays}'),
                                Text('State: ${reserva.state}'),
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
                                  IconButton(
                                    icon: const Icon(Icons.check),
                                    onPressed: () => _confirmReserva(reserva.id),
                                  ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteReserva(reserva.id),
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
    floatingActionButton: FloatingActionButton(
      onPressed: _showAddNewReservaForm,
      backgroundColor: Colors.blue,
      tooltip: 'Add New Reservation',
      child: const Icon(Icons.add),
    ),
  );
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

