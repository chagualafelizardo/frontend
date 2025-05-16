import 'dart:convert';

import 'package:app/models/Atendimento.dart';
import 'package:app/models/Pagamento.dart';
import 'package:app/models/Reserva.dart';
import 'package:app/services/AtendimentoService.dart';
import 'package:app/services/ReservaService.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:app/models/PagamentoList.dart';
import 'package:app/services/DetalhePagamentoService.dart';
import 'package:app/services/DetalhesPagamento.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart';
import 'package:app/services/PagamentoService.dart';
import 'package:path/path.dart';

import '../../services/UserService.dart';

class ManageConfirmPaymentPage extends StatefulWidget {
  const ManageConfirmPaymentPage({super.key});

  @override
  _ManagePaymentPageState createState() => _ManagePaymentPageState();
}

class _ManagePaymentPageState extends State<ManageConfirmPaymentPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 1,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Payment Management'),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Payments'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            PaymentsTab(),
          ],
        ),
      ),
    );
  }
}

class PaymentsTab extends StatelessWidget {
  final PagamentoService paymentService = PagamentoService(dotenv.env['BASE_URL']!);
  final PagamentoService pagamentoService = PagamentoService(dotenv.env['BASE_URL']!);
  final AtendimentoService atendimentoService = AtendimentoService(dotenv.env['BASE_URL']!);
  
  Future<void> _showAtendimentoDetails(BuildContext context, int atendimentoId) async {
      try {
        // Mostra loading enquanto busca os dados
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(child: CircularProgressIndicator()),
        );

        // Busca os detalhes do atendimento
        final atendimento = await atendimentoService.getAtendimentoById(atendimentoId);

        // Fecha o loading
        Navigator.of(context).pop();

        // Mostra os detalhes em um dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Service Details'),
            contentPadding: const EdgeInsets.all(20.0), // Espaçamento interno
            content: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.9, // 90% da largura da tela
                  maxHeight: MediaQuery.of(context).size.height * 0.8, // 80% da altura da tela
                ),
                child: ExpansionTile(
                  initiallyExpanded: true,
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
                          _buildDetailRow(Icons.numbers, 'Atendimento:', '${atendimento.id}'),
                          ExpansionTile(
                            title: _buildDetailRow(Icons.numbers, 'Reserva:', '${atendimento.reservaId}'),
                            children: [
                              FutureBuilder<Reserva>(
                                future: ReservaService(dotenv.env['BASE_URL']!).getReservaById(atendimento.reservaId!),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return const Padding(
                                      padding: EdgeInsets.all(12.0),
                                      child: Center(child: CircularProgressIndicator()),
                                    );
                                  } else if (snapshot.hasError) {
                                    return Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Text('Error: ${snapshot.error}'),
                                    );
                                  } else if (!snapshot.hasData) {
                                    return const Padding(
                                      padding: EdgeInsets.all(12.0),
                                      child: Text('No reservation data found'),
                                    );
                                  }
                                  
                                  final reserva = snapshot.data!;
                                  return Padding(
                                    padding: const EdgeInsets.only(left: 24.0, right: 12.0, bottom: 12.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _buildDetailRow(Icons.date_range, 'Date:', DateFormat('dd/MM/yyyy').format(reserva.date)),
                                        _buildDetailRow(Icons.place, 'Destination:', reserva.destination),
                                        _buildDetailRow(Icons.confirmation_number, 'Number of Days:', '${reserva.numberOfDays}'),
                                        _buildDetailRow(Icons.payment, 'Payment Status:', reserva.isPaid),
                                        _buildDetailRow(Icons.build, 'Service Status:', reserva.inService),
                                        _buildDetailRow(Icons.verified, 'Confirmation:', reserva.state),
                                        if (reserva.clientId != null)
                                          ExpansionTile(
                                            title: _buildDetailRow(Icons.person, 'Client id:', '${reserva.clientId}'),
                                            children: [
                                              FutureBuilder<dynamic>(
                                                future: UserService(dotenv.env['BASE_URL']!).getUserById(reserva.clientId!),
                                                builder: (context, snapshot) {
                                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                                    return const Padding(
                                                      padding: EdgeInsets.all(12.0),
                                                      child: Center(child: CircularProgressIndicator()),
                                                    );
                                                  } else if (snapshot.hasError) {
                                                    return Padding(
                                                      padding: const EdgeInsets.all(12.0),
                                                      child: Text('Error: ${snapshot.error}'),
                                                    );
                                                  } else if (!snapshot.hasData) {
                                                    return const Padding(
                                                      padding: EdgeInsets.all(12.0),
                                                      child: Text('No client data found'),
                                                    );
                                                  }
                                                  
                                                  final client = snapshot.data!;
                                                  return Padding(
                                                    padding: const EdgeInsets.only(left: 24.0, right: 12.0, bottom: 12.0),
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        _buildDetailRow(Icons.person, 'Nome:', client['firstName'] ?? 'N/A'),
                                                        _buildDetailRow(Icons.email, 'Email:', client['email'] ?? 'N/A'),
                                                        _buildDetailRow(Icons.phone, 'Telefone:', client['phone1'] ?? 'N/A'),
                                                        _buildDetailRow(Icons.location_on, 'Endereço:', client['address'] ?? 'N/A'),
                                                        _buildDetailRow(Icons.calendar_today, 'Data de Nascimento:', 
                                                          client['birthdate'] != null 
                                                            ? DateFormat('dd/MM/yyyy').format(DateTime.parse(client['birthdate'])) 
                                                            : 'N/A'),
                                                      ],
                                                    ),
                                                  );
                                                },
                                              ),
                                            ],
                                          ),
                                        if (reserva.veiculoId != null)
                                          ExpansionTile(
                                            title: _buildDetailRow(Icons.directions_car, 'Vehicle id:', '${reserva.veiculoId}'),
                                            children: [
                                              FutureBuilder<Veiculo>(
                                                future: VeiculoService().getVeiculoById(reserva.veiculoId!),
                                                builder: (context, snapshot) {
                                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                                    return const Padding(
                                                      padding: EdgeInsets.all(12.0),
                                                      child: Center(child: CircularProgressIndicator()),
                                                    );
                                                  } else if (snapshot.hasError) {
                                                    return Padding(
                                                      padding: const EdgeInsets.all(12.0),
                                                      child: Text('Error: ${snapshot.error}'),
                                                    );
                                                  } else if (!snapshot.hasData) {
                                                    return const Padding(
                                                      padding: EdgeInsets.all(12.0),
                                                      child: Text('No vehicle data found'),
                                                    );
                                                  }
                                                  
                                                  final veiculo = snapshot.data!;
                                                  return Padding(
                                                    padding: const EdgeInsets.only(left: 24.0, right: 12.0, bottom: 12.0),
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        _buildDetailRow(Icons.directions_car, 'Matrícula:', veiculo.matricula ?? 'N/A'),
                                                        _buildDetailRow(Icons.branding_watermark, 'Marca:', veiculo.marca ?? 'N/A'),
                                                        _buildDetailRow(Icons.model_training, 'Modelo:', veiculo.modelo ?? 'N/A'),
                                                        _buildDetailRow(Icons.color_lens, 'Cor:', veiculo.cor ?? 'N/A'),
                                                        _buildDetailRow(Icons.confirmation_number, 'Ano:', veiculo.ano?.toString() ?? 'N/A'),
                                                        _buildDetailRow(Icons.star, 'Estado:', veiculo.state ?? 'N/A'),
                                                      ],
                                                    ),
                                                  );
                                                },
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          _buildDetailRow(Icons.place, 'Destino:', atendimento.destino ?? 'N/A'),
                          _buildDetailRow(
                            Icons.car_rental, 
                            'Veículo:', 
                            atendimento.veiculo != null 
                              ? '${atendimento.matricula ?? 'Sem marca'}' : 'N/A'
                          ),
                          _buildDetailRow(Icons.date_range, 'Data Início:', DateFormat('dd/MM/yyyy HH:mm').format(atendimento.dataSaida!)),
                          if (atendimento.dataChegada != null)
                            _buildDetailRow(Icons.date_range, 'Data Fim:', DateFormat('dd/MM/yyyy HH:mm').format(atendimento.dataChegada!)),
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
          ),
        );
      } catch (e) {
        // Fecha o loading se estiver aberto
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar detalhes: ${e.toString()}')),
        );
      }
    }

    Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
  
  
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
              DataColumn(label: Text('Atendimento')),
              DataColumn(label: Text('User ID')),
              DataColumn(label: Text('Driver')),
              DataColumn(label: Text('Critério Pagamento ID')),
              DataColumn(label: Text('Actions')),
            ],
            rows: pagamentosList.asMap().entries.map((entry) {
              final index = entry.key;
              final pagamento = entry.value;

              final color = index % 2 == 0
                  ? const Color.fromARGB(255, 5, 5, 5)
                  : const Color.fromARGB(255, 83, 83, 83);

              return DataRow(
                color: WidgetStateProperty.resolveWith<Color>(
                  (Set<WidgetState> states) => color,
                ),
                cells: [
                  DataCell(Text(pagamento.id.toString())),
                  DataCell(Text(pagamento.valorTotal.toString())),
                  DataCell(Text(pagamento.data.toString())),
                  DataCell(
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: InkWell(
                      onTap: () => _showAtendimentoDetails(context, pagamento.atendimentoId!),
                      borderRadius: BorderRadius.circular(4),
                      hoverColor: Colors.blue.withOpacity(0.1),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(pagamento.atendimentoId.toString()),
                            const SizedBox(width: 8),
                            const Icon(Icons.info_outline, 
                              size: 18, 
                              color: Colors.blue,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                  DataCell(Text(pagamento.userId.toString())),
                  DataCell(Text(pagamento.userName.toString())),
                  DataCell(Text(pagamento.criterioPagamentoId.toString())),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                       IconButton(
                          icon: const Icon(Icons.check, color: Colors.green),
                          onPressed: () => _confirmPaymentAuthorization(context),
                          tooltip: 'Confirm payment',
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

  void _confirmPaymentAuthorization(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Payment Authorization'),
          content: const Text('Are you sure you want to authorize this payment?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _authorizePayment();
              },
              child: const Text('Authorize'),
            ),
          ],
        );
      },
    );
  }

  void _authorizePayment() {
    // Payment authorization logic
    ScaffoldMessenger.of(context as BuildContext).showSnackBar(
      const SnackBar(content: Text('Payment successfully authorized')),
    );
  }
}

class PaymentDetails extends StatelessWidget {
  final int pagamentoId;
  final DetalhePagamentoService paymentDetailsService = DetalhePagamentoService(dotenv.env['BASE_URL']!);
  final AtendimentoService atendimentoService = AtendimentoService(dotenv.env['BASE_URL']!);
  final PagamentoService pagamentoService = PagamentoService(dotenv.env['BASE_URL']!);

  PaymentDetails({required this.pagamentoId});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            const TabBar(
              tabs: [
                Tab(text: 'General Information'),
                Tab(text: 'Payment Details'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  // Primeira aba: Informações gerais (Pagamento + Atendimento)
                  FutureBuilder(
                    future: Future.wait([
                      pagamentoService.fetchPagamentoById(pagamentoId),
                      atendimentoService.fetchAtendimentoByPagamentoId(15),
                    ]),
                    builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }
                      if (!snapshot.hasData) {
                        return const Center(child: Text('No data available'));
                      }

                      final pagamento = snapshot.data![0] as Pagamento;
                      final atendimento = snapshot.data![1] as Atendimento;

                      return SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Seção de informações do pagamento
                            Card(
                              elevation: 3,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Payment Information',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    _buildInfoRow('Payment ID:', pagamento.id.toString()),
                                    _buildInfoRow('Total Amount:', '\$${pagamento.valorTotal.toStringAsFixed(2)}'),
                                    _buildInfoRow('Payment Date:', DateFormat('MMM dd, yyyy').format(pagamento.data)),
                                    _buildInfoRow('Payment Criteria:', pagamento.criterioPagamentoId.toString()),
                                  ],
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 20),
                            
                            // Seção de informações do atendimento
                            Card(
                              elevation: 3,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Service Information',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    _buildInfoRow('Service ID:', atendimento.id.toString()),
                                    _buildInfoRow('Status:', atendimento.state),
                                    _buildInfoRow('Client ID:', atendimento.userId.toString()),
                                    // _buildInfoRow('Created At:', DateFormat('MMM dd, yyyy').format(atendimento.destino)),
                                    // Adicione mais campos conforme necessário
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  // Segunda aba: Detalhes do pagamento
                  FutureBuilder<List<DetalhePagamento>>(
                    future: paymentDetailsService.fetchDetalhesPagamento(pagamentoId: pagamentoId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(child: Text('Error loading payment details: ${snapshot.error}'));
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(child: Text('No payment details available'));
                      }

                      final paymentDetailsList = snapshot.data!;
                      return Padding(
                        padding: const EdgeInsets.all(16),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columnSpacing: 16.0,
                            columns: const [
                              DataColumn(label: Text('ID')),
                              DataColumn(label: Text('Amount'), numeric: true),
                              DataColumn(label: Text('Payment Date')),
                              DataColumn(label: Text('Method')),
                              DataColumn(label: Text('Status')),
                            ],
                            rows: paymentDetailsList.map((detail) {
                              return DataRow(
                                cells: [
                                  DataCell(Text(detail.id.toString())),
                                  DataCell(Text('\$${detail.valorPagamento.toStringAsFixed(2)}')),
                                  DataCell(Text(DateFormat('MMM dd, yyyy').format(detail.dataPagamento))),
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(child: Text(value)),
        ],
      ),
    );
  }
}

class VeiculoService {
  Future<Veiculo> getVeiculoById(int veiculoId) async {
    final response = await http.get(Uri.parse('${dotenv.env['BASE_URL']}/veiculo/$veiculoId'));
    if (response.statusCode == 200) {
      return Veiculo.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load vehicle');
    }
  }
}