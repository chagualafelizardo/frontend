import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:app/models/Atendimento.dart';
import 'package:app/ui/atendimento/AtendimentoForm.dart';
import 'package:flutter/material.dart';
import 'package:app/models/Reserva.dart';
import 'package:app/services/ReservaService.dart';
import 'package:app/ui/reserva/AddNewReservaPage.dart';

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

  List<Reserva> _reservas = [];
  List<Reserva> _filteredReservas = [];
  int _currentPage = 1;
  final int _pageSize = 10;
  bool _hasMore = true;
  bool _isLoading = false;

  // Filtros
  String _destinationFilter = '';
  String _stateFilter = '';
  String _vehicleFilter = '';
  String _userFilter = '';
  bool _isGridView = true;

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
        if (reservas.isEmpty) {
          _hasMore = false;
        } else {
          // Filtrar apenas as reservas confirmadas
          _reservas = reservas
              .where((reserva) =>
                  reserva.state == 'Confirmed' &&
                  (reserva.destination.contains(_destinationFilter)) &&
                  (reserva.state.contains(_stateFilter)) &&
                  (reserva.veiculo.matricula.contains(_vehicleFilter)) &&
                  (reserva.user.firstName.contains(_userFilter)))
              .toList();

          // Ordenar a lista de reservas pelo ID da reserva em ordem decrescente
          _reservas.sort((a, b) => b.id.compareTo(a.id));

          _currentPage++;
        }
        _isLoading = false;
        _filteredReservas = _reservas;
      });
    } catch (e) {
      print('Error fetching reservas: $e');
      setState(() {
        _isLoading = false;
      });
    }
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

        // Chamada ao serviço
        await _reservaService.unconfirmReserva(reservaId.toString());

        print("Reservation confirmed successfully on the server.");

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

    // Use o alias para referenciar a classe Veiculo corretamente
 void _showVeiculoDetailsDialog(Veiculo veiculo) async {
  // Verificando o conteúdo de imagemBase64 para depuração
  print('Imagem Base64: ${veiculo.imagemBase64}');

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
                              child: veiculo.imagemBase64!.isNotEmpty
                                  ? Image.memory(
                                      base64Decode(veiculo.imagemBase64!),
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
                  child: TextField(
                    decoration: const InputDecoration(labelText: 'State'),
                    onChanged: (value) {
                      setState(() {
                        _stateFilter = value;
                        _fetchReservas();
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _reservas.isEmpty && !_isLoading
                ? const Center(child: Text('No reservations found'))
                : _isGridView
                    ? GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          crossAxisSpacing: 8.0,
                          mainAxisSpacing: 8.0,
                          childAspectRatio: 1.5,
                        ),
                        itemCount: _reservas.length + (_hasMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _reservas.length) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          return _buildReservaCard(_reservas[index]);
                        },
                      )
                    : ListView.builder(
                        itemCount: _reservas.length + (_hasMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _reservas.length) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          return _buildReservaCard(_reservas[index]);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  @override
  Widget _buildReservaCard(Reserva reserva) {
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
                        User userDetails = await userService.getUserByName('${reserva.user.firstName} ${reserva.user.lastName}');
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
                    onPressed: () async {
                      try {
                        VeiculoService veiculoService = VeiculoService();
                        Veiculo veiculoDetails = await veiculoService.getVeiculoByMatricula(reserva.veiculo.matricula);
                        _showVeiculoDetailsDialog(veiculoDetails);
                      } catch (error) {
                        print('Error fetching vehicle details: $error');
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
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () => _advanceProcess(reserva.id),
            ),
            IconButton(
              icon: const Icon(Icons.undo),
              onPressed: () => _uncheckReserva(reserva.id),
            ),
          ],
        ),
      ),
    );
  }
}


class VeiculoService {
  Future<Veiculo> getVeiculoByMatricula(String matricula) async {
    final response = await http.get(Uri.parse('http://localhost:0/veiculo/matricula/$matricula'));

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
    final response = await http.get(Uri.parse('${dotenv.env['BASE_URL']}/user/user/$fullName'));

    if (response.statusCode == 200) {
      // Supondo que a resposta seja JSON e que você tenha um método Veiculo.fromJson
      return User.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load vehicle');
    }
  }
}

