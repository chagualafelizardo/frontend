import 'dart:convert';
import 'package:app/models/PaymentCriteria.dart';
import 'package:app/models/Reserva.dart' as user_model;
import 'package:app/services/DetalhePagamentoService.dart';
import 'package:app/services/DetalhesPagamento.dart';
import 'package:app/services/PaymentCriteriaService.dart';
import 'package:app/ui/pagamento/ManagePaymentPage.dart';
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
import 'package:app/models/EnviaManutencao.dart';
import 'package:app/services/EnviaManutencaoService.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:app/models/Atendimento.dart';
import 'package:app/services/AtendimentoService.dart';
import 'package:app/models/Pagamento.dart';
import 'package:app/models/PagamentoList.dart';
import 'package:app/services/PagamentoService.dart';
import 'package:app/models/PagamentoReserva.dart';
import 'package:app/services/PagamentoReservaService.dart';
import 'package:path/path.dart';

class ManageReservationPaymentPage extends StatefulWidget {
  const ManageReservationPaymentPage({super.key});

  @override
  _ManageReservationPaymentPageState createState() => _ManageReservationPaymentPageState();
}

class _ManageReservationPaymentPageState extends State<ManageReservationPaymentPage> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final PagamentoReservaService _pagamentoReservaService = PagamentoReservaService();
  final ReservaService _reservaService = ReservaService(dotenv.env['BASE_URL']!);

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
          title: const Text('Manage Reservation Payments'),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Confirmed Reservations'),
              Tab(text: 'Reservation Payments'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            ReservationsTab(reservaService: _reservaService),
            PagamentosReservaTab(),
          ],
        ),
      ),
    );
  }
}

class ReservationsTab extends StatelessWidget {
  final ReservaService reservaService;

  const ReservationsTab({super.key, required this.reservaService});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Reserva>>(
      future: reservaService.getReservas(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No confirmed reservations found.'));
        }

        // Filter only confirmed reservations
        final confirmedReservations = snapshot.data!.where((reserva) => 
            reserva.state.toLowerCase() == 'confirmed').toList();
        
        if (confirmedReservations.isEmpty) {
          return const Center(child: Text('No confirmed reservations found.'));
        }

        return SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Header with statistics
                _buildStatsHeader(confirmedReservations),
                const SizedBox(height: 20),
                // Reservations list
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: confirmedReservations.length,
                  itemBuilder: (context, index) {
                    return _buildReservationCard(confirmedReservations[index]);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatsHeader(List<Reserva> reservations) {
    final todayCount = reservations.where((r) => 
        DateUtils.isSameDay(r.date, DateTime.now())).length;
    final upcomingCount = reservations.where((r) => 
        r.date.isAfter(DateTime.now())).length;
    final lastReservation = reservations.isNotEmpty 
        ? DateFormat('dd/MM/yyyy').format(reservations.last.date)
        : 'N/A';

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(Icons.list, 'Total Confirmed', reservations.length.toString()),
            _buildStatItem(Icons.today, 'Today', todayCount.toString()),
            _buildStatItem(Icons.calendar_today, 'Last Added', lastReservation),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 30, color: Colors.blue),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 12)),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildReservationCard(Reserva reservation) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Reservation #${reservation.id}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                Chip(
                  label: const Text(
                    'CONFIRMED',
                    style: TextStyle(color: Colors.white),
                  ),
                  backgroundColor: Colors.green,
                ),
              ],
            ),
            const SizedBox(height: 10),
            _buildDetailRow(Icons.person, 'Customer:', 'ID ${reservation.userId}'),
            _buildDetailRow(Icons.directions_car, 'Vehicle:', reservation.veiculo?.matricula ?? 'N/A'),
            _buildDetailRow(
              Icons.calendar_today, 
              'Date:', 
              DateFormat('dd/MM/yyyy').format(reservation.date)
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.payment, color: Colors.green),
                  onPressed: () => _showAddPaymentDialog(context as BuildContext, reservation),
                  tooltip: 'Add Payment',
                ),
                IconButton(
                  icon: const Icon(Icons.remove_red_eye, color: Colors.blue),
                  onPressed: () => _showReservationDetails(context as BuildContext, reservation),
                  tooltip: 'View Details',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 8),
          Text('$label ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _showReservationDetails(BuildContext context, Reserva reservation) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Reservation Details #${reservation.id}'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow(Icons.person, 'Customer ID:', reservation.userId.toString()),
                _buildDetailRow(Icons.directions_car, 'Vehicle:', reservation.veiculo?.matricula ?? 'N/A'),
                _buildDetailRow(Icons.calendar_today, 'Date:', 
                    DateFormat('dd/MM/yyyy').format(reservation.date)),
                _buildDetailRow(Icons.star, 'Status:', 'Confirmed'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showAddPaymentDialog(BuildContext context, Reserva reservation) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add Payment for Reservation #${reservation.id}'),
          content: const Text('Payment form would go here'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Payment added successfully')));
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }
}

class PagamentosReservaTab extends StatelessWidget {
  final PagamentoReservaService _pagamentoService = PagamentoReservaService();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<PagamentoReserva>>(
      future: _pagamentoService.fetchAllPagamentosReservas(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No reservation payments found.'));
        }

        final pagamentos = snapshot.data!;
        return SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Header with statistics
                _buildStatsHeader(pagamentos),
                const SizedBox(height: 20),
                // Payments list
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: pagamentos.length,
                  itemBuilder: (context, index) {
                    return _buildPagamentoCard(pagamentos[index]);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatsHeader(List<PagamentoReserva> pagamentos) {
    final total = pagamentos.fold(0.0, (sum, item) => sum + item.valorTotal);
    final lastPayment = pagamentos.isNotEmpty 
        ? DateFormat('dd/MM/yyyy').format(pagamentos.last.data)
        : 'N/A';

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(Icons.payments, 'Total Received', '${total.toStringAsFixed(2)} €'),
            _buildStatItem(Icons.list, 'Total Payments', pagamentos.length.toString()),
            _buildStatItem(Icons.calendar_today, 'Last Payment', lastPayment),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 30, color: Colors.blue),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 12)),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildPagamentoCard(PagamentoReserva pagamento) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Payment #${pagamento.id}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                Chip(
                  label: Text(
                    '${pagamento.valorTotal.toStringAsFixed(2)} €',
                    style: const TextStyle(color: Colors.white),
                  ),
                  backgroundColor: Colors.green,
                ),
              ],
            ),
            const SizedBox(height: 10),
            _buildDetailRow(Icons.person, 'Customer:', 'ID ${pagamento.userId}'),
            _buildDetailRow(Icons.confirmation_number, 'Reservation:', 'ID ${pagamento.reservaId}'),
            _buildDetailRow(
              Icons.calendar_today, 
              'Date:', 
              DateFormat('dd/MM/yyyy - HH:mm').format(pagamento.data)
            ),
            if (pagamento.obs != null && pagamento.obs!.isNotEmpty)
              _buildDetailRow(Icons.note, 'Notes:', pagamento.obs!),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.list, color: Colors.blue),
                  onPressed: () => _showPagamentoDetails(context as BuildContext, pagamento),
                  tooltip: 'View Details',
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.orange),
                  onPressed: () {}, // Implement edit
                  tooltip: 'Edit',
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {}, // Implement delete
                  tooltip: 'Delete',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 8),
          Text('$label ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _showPagamentoDetails(BuildContext context, PagamentoReserva pagamento) {
    showDialog(
      context: context,
      builder: (context) {
        return FutureBuilder<Map<String, dynamic>>(
          future: _pagamentoService.fetchPagamentoDetails(pagamento.id!),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return AlertDialog(
                title: Text('Payment Details #${pagamento.id}'),
                content: const Center(child: CircularProgressIndicator()),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              );
            }

            if (snapshot.hasError) {
              return AlertDialog(
                title: Text('Payment Details #${pagamento.id}'),
                content: Text('Error loading details: ${snapshot.error}'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              );
            }

            final details = snapshot.data!;
            final user = user_model.User.fromJson(details['user']);
            final reserva = Reserva.fromJson(details['reserva']);

            return AlertDialog(
              title: Text('Payment Details #${pagamento.id}'),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow(Icons.person, 'Customer:', '${user.firstName} ${user.lastName}'),
                    _buildDetailRow(Icons.email, 'Email:', user.email ?? 'N/A'),
                    _buildDetailRow(Icons.phone, 'Phone:', user.phone1 ?? 'N/A'),
                    const Divider(),
                    _buildDetailRow(Icons.confirmation_number, 'Reservation ID:', reserva.id.toString()),
                    _buildDetailRow(Icons.date_range, 'Reservation Date:', 
                        DateFormat('dd/MM/yyyy').format(reserva.date)),
                    _buildDetailRow(Icons.directions_car, 'Vehicle:', reserva.veiculo?.matricula ?? 'N/A'),
                    const Divider(),
                    _buildDetailRow(Icons.payments, 'Amount:', '${pagamento.valorTotal.toStringAsFixed(2)} €'),
                    _buildDetailRow(Icons.calendar_today, 'Payment Date:', 
                        DateFormat('dd/MM/yyyy - HH:mm').format(pagamento.data)),
                    if (pagamento.obs != null && pagamento.obs!.isNotEmpty)
                      _buildDetailRow(Icons.note, 'Notes:', pagamento.obs!),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}