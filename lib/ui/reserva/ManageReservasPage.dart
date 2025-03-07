import 'dart:convert';
import 'dart:typed_data';
import 'package:app/ui/reserva/AddDeliveryLocation.dart';
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
      ReservaService('http://localhost:5000');

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

  // Use o alias para referenciar a classe Veiculo corretamente
 void _showVeiculoDetailsDialog(Veiculo veiculo) async {
  // Verificando o conteúdo de imagemBase64 para depuração
  print('Imagem Base64: ${veiculo.imagemBase64}');
  
  // Buscar imagens adicionais usando VeiculoImgService
  // List<String> imagensAdicionais = (await VeiculoImgService('http://localhost:5000').fetchImagesByVehicleId(veiculo.id)).cast<String>();

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(veiculo.matricula),
        content: SizedBox(
          width: 600, // Largura ajustada do diálogo
          child: DefaultTabController(
            length: 3, // Número de abas
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Abas no topo
                const TabBar(
                  tabs: [
                    Tab(text: 'Detalhes'),
                    Tab(text: 'Informações Genéricas'),
                    Tab(text: 'Imagens Adicionais Veiculo'),
                  ],
                ),
                // Conteúdo das abas
                SizedBox(
                  height: 400, // Altura ajustada do conteúdo
                  child: TabBarView(
                    children: [
                      // Primeira aba: Detalhes do Veículo
                      SingleChildScrollView(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Imagem à esquerda
                            Container(
                              width: 250, // Largura da imagem ajustada
                              height: 250, // Altura da imagem ajustada
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: veiculo.imagemBase64.isNotEmpty
                                  ? Image.memory(
                                      base64Decode(veiculo.imagemBase64),
                                      fit: BoxFit.cover,
                                    )
                                  : const Center(child: Text('No Image Available')),
                            ),
                            const SizedBox(width: 16), // Espaçamento entre a imagem e os detalhes
                            // Detalhes do veículo à direita
                            Flexible(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('ID: ${veiculo.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    Text('Matricula: ${veiculo.matricula}'),
                                    Text('Marca: ${veiculo.marca}'),
                                    Text('Modelo: ${veiculo.modelo}'),
                                    Text('Ano: ${veiculo.ano}'),
                                    Text('Cor: ${veiculo.cor}'),
                                    Text('Num Chassi: ${veiculo.numChassi}'),
                                    Text('Num Lugares: ${veiculo.numLugares}'),
                                    Text('Num Motor: ${veiculo.numMotor}'),
                                    Text('Num Portas: ${veiculo.numPortas}'),
                                    Text('Tipo Combustível: ${veiculo.tipoCombustivel}'),
                                    Text('State: ${veiculo.state}'),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Segunda aba: Informações Genéricas
                      const SingleChildScrollView(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Informações Adicionais', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              SizedBox(height: 8),
                              Text('Manutenção Regular: Sim'),
                              Text('Seguro Ativo: Não'),
                              Text('Última Inspeção: 12/08/2024'),
                              Text('Próxima Inspeção: 12/08/2025'),
                              Text('Status: Operacional'),
                            ],
                          ),
                        ),
                      ),
                      // Terceira aba: Imagens Adicionais
                      const SingleChildScrollView(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            // children: imagensAdicionais.isNotEmpty
                            //     ? imagensAdicionais.map((image) => Padding(
                            //           padding: const EdgeInsets.only(bottom: 8.0),
                            //           child: Image.memory(
                            //             base64Decode(image),
                            //             fit: BoxFit.cover,
                            //             height: 200,
                            //             width: double.infinity,
                            //           ),
                            //         )).toList()
                            //     : [const Center(child: Text('No Additional Images'))],
                          ),
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
            child: const Text('Close'),
          ),
        ],
      );
    },
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
              children: [
                const TabBar(
                  tabs: [
                    Tab(text: 'User Info'),
                    Tab(text: 'General Info'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      // User Info Tab
                      SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('ID: ${user.id}'),
                            Text('First Name: ${user.firstName}'),
                            Text('Last Name: ${user.lastName}'),
                            Text('Email: ${user.email}'),
                            Text('Phone Number1: ${user.phone1}'),
                            Text('Phone Number2: ${user.phone2}'),
                            Text('Address: ${user.address}'),
                          ],
                        ),
                      ),
                      // General Info Tab
                      const SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('General information about the user or application goes here.'),
                            Text('This could include additional notes or metadata.'),
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
              crossAxisCount: 4, // Número de colunas
              crossAxisSpacing: 8, // Espaçamento entre as colunas
              mainAxisSpacing: 8, // Espaçamento entre as linhas
              childAspectRatio: 1.5, // Aumente o valor para diminuir a altura das células
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
                                      User userDetails = await userService.getUserByName('Felizardo Chaguala');
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
                      trailing: reserva.state == 'Not Confirmed'
                          ? IconButton(
                              icon: const Icon(Icons.check),
                              onPressed: () => _confirmReserva(reserva.id),
                            )
                          : null,
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
                                  User userDetails = await userService.getUserByName('Felizardo Chaguala');
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
                  trailing: reserva.state == 'Not Confirmed'
                      ? IconButton(
                          icon: const Icon(Icons.check),
                          onPressed: () => _confirmReserva(reserva.id),
                        )
                      : null,
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
}

class VeiculoService {
  Future<Veiculo> getVeiculoByMatricula(String matricula) async {
    final response = await http.get(Uri.parse('http://localhost:5000/veiculo/matricula/$matricula'));

    if (response.statusCode == 200) {
      // Supondo que a resposta seja JSON e que você tenha um método Veiculo.fromJson
      return Veiculo.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load vehicle');
    }
  }
}


class UserService {
  Future<User> getUserByName(String fullName) async {
    final response = await http.get(Uri.parse('http://localhost:5000/user/user/$fullName'));

    if (response.statusCode == 200) {
      // Supondo que a resposta seja JSON e que você tenha um método Veiculo.fromJson
      return User.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load vehicle');
    }
  }
}

