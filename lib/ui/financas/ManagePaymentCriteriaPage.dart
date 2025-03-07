import 'package:app/models/PaymentCriteria.dart';
import 'package:app/services/PaymentCriteriaService.dart';
import 'package:app/ui/financas/PaymentCriteria.dart';
import 'package:flutter/material.dart';

class ManagePaymentCriteriaPage extends StatefulWidget {
  final PaymentCriteriaService paymentCriteriaService = PaymentCriteriaService(baseUrl: 'http://localhost:5000');

  ManagePaymentCriteriaPage({super.key});

  @override
  _ManageOnDefinePaymentCriteriaPageState createState() =>
      _ManageOnDefinePaymentCriteriaPageState();
}

class _ManageOnDefinePaymentCriteriaPageState
    extends State<ManagePaymentCriteriaPage> {
  late Future<List<PaymentCriteria>> _paymentCriteriaFuture;

  @override
  void initState() {
    super.initState();
    _loadPaymentCriteria();
  }

  void _loadPaymentCriteria() {
    _paymentCriteriaFuture = widget.paymentCriteriaService.getAllPaymentCriteria();
  }

  void _showForm({PaymentCriteria? paymentCriteria}) async {
    final result = await showDialog<PaymentCriteria>(
      context: context,
      builder: (context) => PaymentCriteriaForm(
        paymentCriteria: paymentCriteria,
      ),
    );

    if (result != null) {
      if (paymentCriteria == null) {
        await widget.paymentCriteriaService.createPaymentCriteria(result);
      } else {
        await widget.paymentCriteriaService.updatePaymentCriteria(result);
      }
      _loadPaymentCriteria();
      setState(() {});
    }
  }

  void _deletePaymentCriteria(int id) async {
    await widget.paymentCriteriaService.deletePaymentCriteria(id);
    _loadPaymentCriteria();
    setState(() {});
  }

  // Função para retornar a cor com base no índice da linha
  Color _getRowColor(int index) {
    return index % 2 == 0 ? const Color.fromARGB(255, 14, 13, 13)! : const Color.fromARGB(255, 109, 108, 108);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Payment Criteria'),
      ),
      body: FutureBuilder<List<PaymentCriteria>>(
        future: _paymentCriteriaFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No payment criteria available.'));
          }

          final paymentCriteriaList = snapshot.data!;
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 16.0,
              columns: const [
                DataColumn(label: Text('ID')),
                DataColumn(label: Text('Activity')),
                DataColumn(label: Text('Payment Type')),
                DataColumn(label: Text('Payment Method')),
                DataColumn(label: Text('Payment Period')),
                DataColumn(label: Text('Amount')),
                DataColumn(label: Text('Actions')),
              ],
              rows: paymentCriteriaList.asMap().entries.map((entry) {
                final index = entry.key;
                final criteria = entry.value;
                return DataRow(
                  color: MaterialStateProperty.resolveWith<Color>(
                    (Set<MaterialState> states) {
                      return _getRowColor(index); // Aplica a cor com base no índice
                    },
                  ),
                  cells: [
                    DataCell(Text(criteria.id.toString())),
                    DataCell(Text(criteria.activity)),
                    DataCell(Text(criteria.paymentType)),
                    DataCell(Text(criteria.paymentMethod)),
                    DataCell(Text(criteria.paymentPeriod)),
                    DataCell(Text('\$${criteria.amount.toStringAsFixed(2)}')),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _showForm(paymentCriteria: criteria),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _deletePaymentCriteria(criteria.id!),
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(),
        tooltip: 'Add Payment Criteria',
        child: const Icon(Icons.add),
      ),
    );
  }
}