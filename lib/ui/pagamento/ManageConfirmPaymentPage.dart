import 'dart:convert';
import 'package:app/models/PagamentoList.dart';
import 'package:app/models/PaymentCriteria.dart';
import 'package:app/services/DetalhePagamentoService.dart';
import 'package:app/services/DetalhesPagamento.dart';
import 'package:app/services/PaymentCriteriaService.dart';
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
import 'package:app/models/EnviaManutencao.dart'; // Importe o modelo Manutencao
import 'package:app/services/EnviaManutencaoService.dart';
import 'package:intl/intl.dart'; // Importe o serviço ManutencaoService
import 'package:flutter/material.dart';
import 'package:app/models/Atendimento.dart';
import 'package:app/services/AtendimentoService.dart';
import 'package:app/models/Pagamento.dart';
import 'package:app/services/PagamentoService.dart';

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
    _tabController = TabController(length: 1, vsync: this); // Apenas uma aba
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 1, // Apenas uma aba
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Manage Payment'),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Payment'), // Apenas a segunda aba
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            PagamentosTab(), // Apenas a segunda aba
          ],
        ),
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
                color: MaterialStateProperty.resolveWith<Color>(
                  (Set<MaterialState> states) {
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
                          icon: const Icon(Icons.check),
                          onPressed: () {
                            _confirmarAutorizacaoPagamento(context);
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

void _confirmarAutorizacaoPagamento(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Confirm Authorization'),
        content: const Text('Do you want to authorize this payment?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Fecha o popup sem autorizar
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Fecha o popup
              _autorizarPagamento(); // Chama a função para autorizar
            },
            child: const Text('Authorize'),
          ),
        ],
      );
    },
  );
}

void _autorizarPagamento() {
  // Lógica para autorizar o pagamento
  print('Payment authorized!');
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
                                color: MaterialStateProperty.resolveWith<Color>(
                                  (Set<MaterialState> states) {
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