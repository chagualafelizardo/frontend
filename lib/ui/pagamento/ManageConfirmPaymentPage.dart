import 'package:intl/intl.dart';
import 'package:app/models/PagamentoList.dart';
import 'package:app/services/DetalhePagamentoService.dart';
import 'package:app/services/DetalhesPagamento.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart';
import 'package:app/services/PagamentoService.dart';
import 'package:path/path.dart';

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

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<PagamentoList>>(
      future: paymentService.fetchPagamentos(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error loading payments: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No payments available'));
        }

        final paymentsList = snapshot.data!;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 16.0,
            columns: const [
              DataColumn(label: Text('ID')),
              DataColumn(label: Text('Total Amount')),
              DataColumn(label: Text('Date')),
              DataColumn(label: Text('Service ID')),
              DataColumn(label: Text('User ID')),
              DataColumn(label: Text('Payment Criteria ID')),
              DataColumn(label: Text('Actions')),
            ],
            rows: paymentsList.asMap().entries.map((entry) {
              final index = entry.key;
              final payment = entry.value;

              final color = index % 2 == 0
                  ? const Color.fromARGB(255, 5, 5, 5)
                  : const Color.fromARGB(255, 83, 83, 83);

              return DataRow(
                color: MaterialStateProperty.resolveWith<Color>(
                  (Set<MaterialState> states) => color,
                ),
                cells: [
                  DataCell(Text(payment.id.toString())),
                  DataCell(Text('\$${payment.valorTotal.toStringAsFixed(2)}')),
                  DataCell(Text(DateFormat('MM/dd/yyyy').format(payment.data))),
                  DataCell(Text(payment.atendimentoId.toString())),
                  DataCell(Text(payment.userId.toString())),
                  DataCell(Text(payment.criterioPagamentoId.toString())),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.check, color: Colors.green),
                          onPressed: () => _confirmPaymentAuthorization(context),
                          tooltip: 'Authorize Payment',
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
  final DetalhePagamentoService paymentDetailsService = DetalhePagamentoService(dotenv.env['BASE_URL']!);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.6,
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
                  const Center(
                    child: Text(
                      'General payment information will be displayed here',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                  FutureBuilder<List<DetalhePagamento>>(
                    future: paymentDetailsService.fetchDetalhesPagamento(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(child: Text('Error loading details: ${snapshot.error}'));
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(child: Text('No payment details available'));
                      }

                      final detailsList = snapshot.data!;
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: DataTable(
                            columnSpacing: 16.0,
                            columns: const [
                              DataColumn(label: Text('ID')),
                              DataColumn(label: Text('Amount')),
                              DataColumn(label: Text('Payment Date')),
                              DataColumn(label: Text('Payment ID')),
                            ],
                            rows: detailsList.asMap().entries.map((entry) {
                              final index = entry.key;
                              final detail = entry.value;

                              final color = index % 2 == 0
                                  ? const Color.fromARGB(255, 5, 5, 5)
                                  : const Color.fromARGB(255, 83, 83, 83);

                              return DataRow(
                                color: MaterialStateProperty.resolveWith<Color>(
                                  (Set<MaterialState> states) => color,
                                ),
                                cells: [
                                  DataCell(Text(detail.id.toString())),
                                  DataCell(Text('\$${detail.valorPagamento.toStringAsFixed(2)}')),
                                  DataCell(Text(DateFormat('MM/dd/yyyy').format(detail.dataPagamento))),
                                  DataCell(Text(detail.pagamentoId.toString())),
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