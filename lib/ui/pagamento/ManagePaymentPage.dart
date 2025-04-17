import 'package:app/models/PaymentCriteria.dart';
import 'package:app/services/DetalhePagamentoService.dart';
import 'package:app/services/DetalhesPagamento.dart';
import 'package:app/services/PaymentCriteriaService.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:app/services/ReservaService.dart';
import 'package:app/services/UserService.dart';
import 'package:app/services/VeiculoAddService.dart';
import 'package:flutter/material.dart';
import 'package:app/models/Atendimento.dart';
import 'package:app/services/AtendimentoService.dart';
import 'package:intl/intl.dart'; // Importe o serviço ManutencaoService
import 'package:app/models/Pagamento.dart';
import 'package:app/models/PagamentoList.dart';
import 'package:app/services/PagamentoService.dart';

class ManagePaymentPage extends StatefulWidget {
  const ManagePaymentPage({super.key});

  @override
  _ManagePaymentPageState createState() => _ManagePaymentPageState();
}

class _ManagePaymentPageState extends State<ManagePaymentPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Manage Payment'),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Client in Service'),
              Tab(text: 'Payments'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            const AtendimentosTab(), // Primeira aba: Lista de Atendimentos
            PagamentosTab(),   // Segunda aba: Lista de Pagamentos
          ],
        ),
      ),
    );
  }
}

class AtendimentosTab extends StatefulWidget {
  const AtendimentosTab({super.key});

  @override
  _AtendimentosTabState createState() => _AtendimentosTabState();
}

class _AtendimentosTabState extends State<AtendimentosTab> {
  final AtendimentoService _atendimentoService = AtendimentoService(dotenv.env['BASE_URL']!);
  final ReservaService _reservaService = ReservaService(dotenv.env['BASE_URL']!);
  final VeiculoServiceAdd _veiculoService = VeiculoServiceAdd(dotenv.env['BASE_URL']!);
  final UserService _userService = UserService(dotenv.env['BASE_URL']!);
  final PagamentoService pagamentoService = PagamentoService(dotenv.env['BASE_URL']!);

  var user, veiculo, state;

  List<Atendimento> _atendimentos = [];
  List<Atendimento> _filteredAtendimentos = [];
  bool _isLoading = false;
  String _searchQuery = '';
  bool _isGridView = true;

  final TextEditingController _destinoController = TextEditingController();
  final TextEditingController _userController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchAtendimentos();
  }

  Future<void> _fetchAtendimentos() async {
  if (_isLoading) return;

  setState(() => _isLoading = true);

  try {
    List<Atendimento> atendimentos = await _atendimentoService.fetchAtendimentos();

    for (var atendimento in atendimentos) {
      print('Atendimento ID: ${atendimento.id}, ReserveID: ${atendimento.reservaId}, State: ${atendimento.state}');

      var reserva = await _reservaService.getReservaById(atendimento.reservaId!);
      user = reserva.user;
      veiculo = reserva.veiculo;
      state = reserva.state;

      // Armazene o userId da reserva no atendimento
      atendimento.userId = reserva.clientId;
    }

    setState(() {
      _atendimentos = atendimentos;
      _filteredAtendimentos = atendimentos;
      _isLoading = false;
    });
  } catch (e) {
    print('Error fetching atendimentos: $e');
    setState(() => _isLoading = false);
  }
}

  void _filterAtendimentos() {
    String destino = _destinoController.text.toLowerCase();
    String user = _userController.text.toLowerCase();

    setState(() {
      _filteredAtendimentos = _atendimentos.where((atendimento) {
        final atendimentoDestino = atendimento.destino?.toLowerCase() ?? '';
        final atendimentoUser = atendimento.user?.toLowerCase() ?? '';
        return atendimentoDestino.contains(destino) && atendimentoUser.contains(user);
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
            controller: _userController,
            label: 'User',
            icon: Icons.person,
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
      child: Text('No atendimentos found'),
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

void _showCreatePagamentoDialog(BuildContext context, int atendimentoId, int userId, int criterioPagamentoId) {
  TextEditingController valorTotalController = TextEditingController();
  TextEditingController dataPagamentoController = TextEditingController();
  PaymentCriteriaService paymentCriteriaService = PaymentCriteriaService(baseUrl: dotenv.env['BASE_URL']!);

  // Variable to store payment criteria
  List<PaymentCriteria> paymentCriteriaList = [];
  PaymentCriteria? selectedPaymentCriteria;

  // Function to load payment criteria
  Future<void> loadPaymentCriteria() async {
    try {
      paymentCriteriaList = await paymentCriteriaService.getAllPaymentCriteria();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading payment criteria: $e')),
      );
    }
  }

  showDialog(
  context: context,
  builder: (BuildContext context) {
    return FutureBuilder(
      future: loadPaymentCriteria(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return AlertDialog(
            title: const Text('Create Payment'),
            content: const Center(child: CircularProgressIndicator()),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Cancel'),
              ),
            ],
          );
        }

        // Define o valor padrão para o valorTotalController
        if (paymentCriteriaList.isNotEmpty) {
          valorTotalController.text = paymentCriteriaList[0].amount.toString();
        }

        // Define a data atual como valor padrão para o dataPagamentoController
        dataPagamentoController.text = DateTime.now().toIso8601String().split('T')[0];

        // Define o valor padrão para o selectedPaymentCriteria
        selectedPaymentCriteria = paymentCriteriaList.isNotEmpty ? paymentCriteriaList[0] : null;

        return AlertDialog(
          title: const Text('Create Payment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start, // Alinha tudo à esquerda
            children: [
              // Display atendimentoId
              Text(
                'Service number: $atendimentoId',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              // Display userId
              Text(
                'User id: $userId',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              // Field for total value
              TextField(
                controller: valorTotalController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Total Value',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              // Field for payment date
              TextField(
                controller: dataPagamentoController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Payment Date',
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
                    dataPagamentoController.text = pickedDate.toIso8601String().split('T')[0];
                  }
                },
              ),
              const SizedBox(height: 10),
              // Dropdown to select payment criteria
              DropdownButtonFormField<PaymentCriteria>(
                value: selectedPaymentCriteria,
                hint: const Text('Select payment criteria'),
                items: paymentCriteriaList.map((PaymentCriteria criteria) {
                  return DropdownMenuItem<PaymentCriteria>(
                    value: criteria,
                    child: Text(
                      '${criteria.activity} - ${criteria.paymentType} (${criteria.amount})',
                    ),
                  );
                }).toList(),
                onChanged: (PaymentCriteria? value) {
                  setState(() {
                    selectedPaymentCriteria = value;
                    // Atualiza o valorTotalController com o amount do critério selecionado
                    if (value != null) {
                      valorTotalController.text = value.amount.toString();
                    }
                  });
                },
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            // Cancel button
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            // Confirm button
            TextButton(
              onPressed: () {
                // Field validation
                String valorTotalText = valorTotalController.text.trim();
                String dataPagamentoText = dataPagamentoController.text.trim();

                if (valorTotalText.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter the total value.')),
                  );
                  return;
                }

                double valorTotal = double.tryParse(valorTotalText) ?? -1;
                if (valorTotal < 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invalid total value.')),
                  );
                  return;
                }

                if (dataPagamentoText.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select the payment date.')),
                  );
                  return;
                }

                if (selectedPaymentCriteria == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select a payment criteria.')),
                  );
                  return;
                }

                // Create the Pagamento object
                Pagamento novoPagamento = Pagamento(
                  valorTotal: valorTotal,
                  data: DateTime.parse(dataPagamentoText),
                  atendimentoId: atendimentoId,
                  userId: userId,
                  criterioPagamentoId: selectedPaymentCriteria!.id!, // Use o critério selecionado
                );

                // Here you can call the service to save the payment
                pagamentoService.createPagamento(novoPagamento);

                // Close the popup
                Navigator.of(context).pop();
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  },
);
}

Widget _buildAtendimentoCard(Atendimento atendimento) {
  final DateTime? dataChegada = atendimento.dataChegada;

  String daysRemainingMessage = 'Data de chegada não disponível';
  Color circleColor = Colors.grey;
  bool isBlinking = false;

  if (dataChegada != null) {
    int daysRemaining = _calculateDaysRemaining(dataChegada);
    if (daysRemaining < 0) {
      daysRemainingMessage = 'Devolução já realizada';
    } else if (daysRemaining <= 5) {
      daysRemainingMessage = 'Faltam $daysRemaining dias para a devolução';
      circleColor = Colors.red;
      isBlinking = true;
    } else if (daysRemaining <= 10) {
      daysRemainingMessage = 'Faltam $daysRemaining dias para a devolução';
      circleColor = Colors.orange;
    } else if (daysRemaining <= 15) {
      daysRemainingMessage = 'Faltam $daysRemaining dias para a devolução';
      circleColor = Colors.yellow;
    } else {
      daysRemainingMessage = 'Faltam mais de 15 dias para a devolução';
      circleColor = Colors.green;
    }
  }

  return Card(
    margin: const EdgeInsets.all(8.0),
    elevation: 4, // Sombra do card
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12), // Bordas arredondadas
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
                  'Atendimento ID: ${atendimento.id}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Destino: ${atendimento.destino ?? 'N/A'}',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
      subtitle: Text(
        'Usuário: ${user.firstName ?? 'N/A'}',
        style: const TextStyle(fontSize: 14),
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
                'Data de Saída:',
                atendimento.dataSaida != null
                    ? DateFormat('dd/MM/yyyy').format(atendimento.dataSaida!)
                    : 'N/A',
              ),
              _buildDetailRow(
                Icons.date_range,
                'Data da Provável Devolução:',
                atendimento.dataChegada != null
                    ? DateFormat('dd/MM/yyyy').format(atendimento.dataChegada!)
                    : 'N/A',
              ),
              _buildDetailRow(
                Icons.date_range,
                'Data da Devolução:',
                atendimento.dataDevolucao != null
                    ? DateFormat('dd/MM/yyyy').format(atendimento.dataDevolucao!)
                    : 'N/A',
              ),
              _buildDetailRow(Icons.speed, 'Km Inicial:', atendimento.kmInicial?.toString() ?? 'N/A'),
              _buildDetailRow(Icons.speed, 'Km Final:', atendimento.kmFinal?.toString() ?? 'N/A'),
              _buildDetailRow(Icons.person, 'Usuário:', user.firstName ?? 'N/A'),
              _buildDetailRow(Icons.directions_car, 'Veículo:', veiculo.matricula ?? 'N/A'),
              _buildDetailRow(Icons.flag, 'Estado:', state ?? 'N/A'),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.check_circle, color: Colors.green),
                onPressed: () => _showCreatePagamentoDialog(
                  context,
                  atendimento.id!,
                  atendimento.userId!,
                  2, // Critério de pagamento selecionado
                ),
                tooltip: 'Confirmar Criação de Pagamento',
              ),
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                onPressed: () {
                  // Implemente a edição do atendimento
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  // Implemente a exclusão do atendimento
                },
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

// Método auxiliar para construir uma linha de detalhe
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
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 16.0,
                              mainAxisSpacing: 16.0,
                            ),
                            itemCount: _filteredAtendimentos.length,
                            itemBuilder: (context, index) {
                              return _buildAtendimentoCard(_filteredAtendimentos[index]);
                            },
                          )
                        : ListView.builder(
                            itemCount: _filteredAtendimentos.length,
                            itemBuilder: (context, index) {
                              return _buildAtendimentoCard(_filteredAtendimentos[index]);
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

class PagamentosTab extends StatelessWidget {
final PagamentoService pagamentoService = PagamentoService(dotenv.env['BASE_URL']!);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<PagamentoList>>(
      future: pagamentoService.fetchPagamentos(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No pagamentos available.'));
        }

        final pagamentosList = snapshot.data!;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 16.0,
            columns: const [
              DataColumn(label: Text('ID')),
              DataColumn(label: Text('Valor Total')),
              DataColumn(label: Text('Data')),
              DataColumn(label: Text('Atendimento ID')),
              DataColumn(label: Text('User ID')),
              DataColumn(label: Text('Critério Pagamento ID')),
              DataColumn(label: Text('Actions')),
            ],
            rows: pagamentosList.asMap().entries.map((entry) {
              final index = entry.key; // Índice da linha
              final pagamento = entry.value; // Dados do pagamento

              // Define as cores alternadas
              final color = index % 2 == 0
                  ? const Color.fromARGB(255, 5, 5, 5)
                  : const Color.fromARGB(255, 83, 83, 83);

              return DataRow(
                color: WidgetStateProperty.resolveWith<Color>(
                  (Set<WidgetState> states) {
                    return color; // Aplica a cor de fundo
                  },
                ),
                cells: [
                  DataCell(Text(pagamento.id.toString())),
                  DataCell(Text(pagamento.valorTotal.toString())),
                  DataCell(Text(pagamento.data.toString())),
                  DataCell(Text(pagamento.atendimentoId.toString())),
                  DataCell(Text(pagamento.userId.toString())),
                  DataCell(Text(pagamento.criterioPagamentoId.toString())),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () {
                            // Implemente a edição do pagamento
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            // Implemente a exclusão do pagamento
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.list),
                          onPressed: () {
                            // Abre o popup com os detalhes do pagamento
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: const Text('Detalhes do Pagamento'),
                                  content: SizedBox(
                                    width: double.maxFinite,
                                    child: DetalhesPagamento(),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop(); // Fecha o popup
                                      },
                                      child: const Text('Fechar'),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

class DetalhesPagamento extends StatelessWidget {
  final DetalhePagamentoService pagamentoDetalhesService = DetalhePagamentoService(dotenv.env['BASE_URL']!);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // Número de abas
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9, // 90% da largura da tela
        height: MediaQuery.of(context).size.height * 0.6, // 60% da altura da tela
        child: Column(
          children: [
            // Barra de abas
            const TabBar(
              tabs: [
                Tab(text: 'Informações Gerais'), // Primeira aba
                Tab(text: 'Detalhes de Pagamento'), // Segunda aba
              ],
            ),
            // Conteúdo das abas
            Expanded(
              child: TabBarView(
                children: [
                  // Conteúdo da primeira aba (Informações Gerais)
                  const Center(
                    child: Text(
                      'Aqui você pode adicionar informações gerais sobre o pagamento.',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                  // Conteúdo da segunda aba (Detalhes de Pagamento)
                  FutureBuilder<List<DetalhePagamento>>(
                    future: pagamentoDetalhesService.fetchDetalhesPagamento(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(child: Text('No detalhes pagamento available.'));
                      }

                      final detalhesList = snapshot.data!;
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: DataTable(
                            columnSpacing: 16.0,
                            columns: const [
                              DataColumn(label: Text('ID')),
                              DataColumn(label: Text('Valor Pagamento')),
                              DataColumn(label: Text('Data Pagamento')),
                              DataColumn(label: Text('Pagamento ID')),
                            ],
                            rows: detalhesList.asMap().entries.map((entry) {
                              final index = entry.key; // Índice da linha
                              final detalhe = entry.value; // Dados do detalhe de pagamento

                              // Define as cores alternadas
                              final color = index % 2 == 0
                                  ? const Color.fromARGB(255, 5, 5, 5) // Cor para linhas pares
                                  : const Color.fromARGB(255, 83, 83, 83); // Cor para linhas ímpares

                              return DataRow(
                                color: WidgetStateProperty.resolveWith<Color>(
                                  (Set<WidgetState> states) {
                                    return color; // Aplica a cor de fundo
                                  },
                                ),
                                cells: [
                                  DataCell(Text(detalhe.id.toString())),
                                  DataCell(Text(detalhe.valorPagamento.toString())),
                                  DataCell(Text(detalhe.dataPagamento.toString())),
                                  DataCell(Text(detalhe.pagamentoId.toString())),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}