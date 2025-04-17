import 'package:app/ui/reserva/PaymentAndDeliveryLocation.dart';
import 'package:app/ui/user/UserDetailsPage.dart';
import 'package:app/ui/veiculo/ViewVeiculoPage.dart';
import 'package:path/path.dart' as path;
import 'package:app/models/Reserva.dart' as user_model;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:app/models/UserRenderImgBase64.dart';
import 'package:app/models/Reserva.dart';
import 'package:app/services/ReservaService.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:app/models/PagamentoReserva.dart';
import 'package:app/services/PagamentoReservaService.dart';
import 'package:app/models/Veiculo.dart';

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
      future: reservaService.getNotpaidReservas(),
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
          // Título + Status
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

          // Linha: Customer + Botão
          Row(
            children: [
              Expanded(
                child: _buildDetailRow(
                  Icons.person,
                  'Customer:',
                  ' ${reservation.userId} - ${reservation.user.firstName} ${reservation.user.lastName}',
                ),
              ),
              IconButton(
                icon: const Icon(Icons.info_outline, color: Colors.blue),
                tooltip: 'View User Details',
                onPressed: () {
                  Navigator.push(
                    path.context as BuildContext,
                    MaterialPageRoute(
                      builder: (context) => UserDetailsPage(
                        user: UserBase64.fromUser(reservation.user),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),

          // Linha: Vehicle + Botão
          Row(
            children: [
              Expanded(
                child: _buildDetailRow(
                  Icons.directions_car,
                  'Vehicle:',
                  reservation.veiculo.matricula ?? 'N/A',
                ),
              ),
              IconButton(
                icon: const Icon(Icons.info_outline, color: Colors.blue),
                tooltip: 'View Vehicle Details',
                onPressed: () {
                  // Navigator.push(
                    // path.context as BuildContext,
                    // MaterialPageRoute(
                    //   builder: (context) => ViewVeiculoPage(
                    //     veiculo: reservation.veiculo,
                    //   ),
                    // ),
                  // );
                },
              ),
            ],
          ),

          // Linha: Data
          _buildDetailRow(
            Icons.calendar_today,
            'Date:',
            DateFormat('dd/MM/yyyy').format(reservation.date),
          ),

          const SizedBox(height: 10),

          // Botões no canto inferior direito
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.payment, color: Colors.green),
                onPressed: () {
                },
                tooltip: 'Add Payment',
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
              // Abas de navegação (simples Row com botões)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context); // Fecha o diálogo
                      // Navigator.push(
                        // context,
                        // MaterialPageRoute(
                        //   builder: (context) =>
                        //       UserDetailsPage(user: UserBase64.fromUser(reservation.user)), // Aqui converte!),
                        // ),
                      // );
                    },
                    icon: Icon(Icons.person),
                    label: Text('User Details'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context); // Fecha o diálogo
                      // Navigator.push(
                      //   context,
                      //   MaterialPageRoute(
                      //     builder: (context) =>
                      //         ViewVeiculoPage(veiculo: reservation.veiculo),
                      //   ),
                      // );
                    },
                    icon: Icon(Icons.directions_car),
                    label: Text('Vehicle Details'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildDetailRow(Icons.person, 'Customer:',
                  ' ${reservation.userId} - ${reservation.user.firstName} ${reservation.user.lastName}'),
              _buildDetailRow(Icons.directions_car, 'Vehicle:',
                  reservation.veiculo.matricula ?? 'N/A'),
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
            
            // Linha do cliente com botão de detalhes
            Row(
              children: [
                Expanded(
                  child: _buildDetailRow(
                    Icons.person, 
                    'Customer:', 
                    ' ${pagamento.userId}'
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.visibility, size: 20, color: Colors.blue),
                  onPressed: () {
                    // Implemente a navegação para os detalhes do usuário
                    // Você precisará obter o objeto User completo primeiro
                    // Navigator.of(path.context as BuildContext).push(
                    //   MaterialPageRoute(
                    //     builder: (context) => UserDetailsPage(
                    //       user: User(id: pagamento.userId, 
                    //       username: '', 
                    //       firstName: '', 
                    //       lastName: '', 
                    //       gender: '', 
                    //       birthdate: null, 
                    //       address: '', 
                    //       neighborhood: '', 
                    //       email: '', 
                    //       phone1: '', 
                    //       phone2: '', 
                    //       password: '', 
                    //       state: ''), // Adapte conforme sua implementação
                    //     ),
                    //   ),
                    // );
                  },
                  tooltip: 'View Customer Details',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            
            // Linha da reserva com botão de detalhes
            Row(
              children: [
                Expanded(
                  child: _buildDetailRow(
                    Icons.confirmation_number, 
                    'Reservation:', 
                    ' ${pagamento.reservaId}'
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.visibility, size: 20, color: Colors.blue),
                  onPressed: () {
                    // Implemente a navegação para os detalhes da reserva
                    // Navigator.of(context).push(
                    //   MaterialPageRoute(
                    //     builder: (context) => ReservationDetailsPage(
                    //       reservationId: pagamento.reservaId, // Adapte conforme sua implementação
                    //     ),
                    //   ),
                    // );
                  },
                  tooltip: 'View Reservation Details',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            
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
                  onPressed: () => _showPagamentoDetails(path.context as BuildContext, pagamento),
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
                    _buildDetailRow(Icons.directions_car, 'Vehicle:', reserva.veiculo.matricula ?? 'N/A'),
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
