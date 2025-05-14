import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:app/models/VehicleHistoryRent.dart';
import 'package:app/services/VehicleHistoryRentService.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import '../../models/Veiculo.dart';

class ManageVehicleHistoryPage extends StatefulWidget {
  final VehicleHistoryRentService service;
  final int veiculoId;

  const ManageVehicleHistoryPage({
    super.key, 
    required this.service,
    required this.veiculoId,
  });

  @override
  State<ManageVehicleHistoryPage> createState() => _ManageVehicleHistoryPageState();
}

class _ManageVehicleHistoryPageState extends State<ManageVehicleHistoryPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<VehicleHistoryRent> historyList = [];
  bool isLoading = true;

  // Form controllers
  final _formKey = GlobalKey<FormState>();
  DateTime? _dataValor;
  double? _valor;
  String? _obs;
  int? _veiculoID;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _veiculoID = widget.veiculoId;
    fetchData();
  }

  Future<void> fetchData() async {
    try {
      final list = await widget.service.getHistoryByVehicleId(widget.veiculoId);
      setState(() {
        historyList = list;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching history: $e');
    }
  }

Future<void> _submitForm() async {
  if (_formKey.currentState!.validate()) {
    _formKey.currentState!.save();

    try {
      final newHistory = VehicleHistoryRent(
        datavalor: _dataValor,
        valor: _valor!, // Já convertido no onSaved
        obs: _obs,
        veiculoID: widget.veiculoId, // Usando diretamente o ID passado
      );

      await widget.service.create(newHistory);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rental history added successfully')));
      
      _formKey.currentState!.reset();
      setState(() {
        _dataValor = null;
        _valor = null;
        _obs = null;
      });
      
      await fetchData();
      _tabController.animateTo(0);
    } catch (e, stackTrace) {
      print('Error saving vehicle history: $e');
      print('Stack trace: $stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving history: ${e.toString()}')));
    }
  }
}

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String formatDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat('yyyy-MM-dd').format(date);
  }

  Future<void> _confirmDelete(int historyId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this history entry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await widget.service.delete(historyId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('History deleted successfully')));
        await fetchData(); // Atualiza a lista após a exclusão
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete history: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vehicle Rental History'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'History'),
            Tab(text: 'Add New'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: List
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  itemCount: historyList.length,
                  itemBuilder: (context, index) {
                    final history = historyList[index];
                    final bool isEven = index.isEven;
                    
                    return Container(
                      color: isEven 
                          ? Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3)
                          : Theme.of(context).colorScheme.surface,
                      child: InkWell(
                        onTap: () {
                          // Adicione ação ao tocar se necessário
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Amount: \$${history.valor.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                  Text(
                                    formatDate(history.datavalor),
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              if (history.obs != null && history.obs!.isNotEmpty)
                                Text(
                                  'Notes: ${history.obs}',
                                  style: TextStyle(
                                    fontStyle: FontStyle.italic,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _confirmDelete(history.id!),
                                  ),
                                ],
                              ),
                              const Divider(height: 16, thickness: 0.5),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
          // Tab 2: Form
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Vehicle ID',
                      filled: true,
                      fillColor: Colors.grey,
                    ),
                    initialValue: widget.veiculoId.toString(),
                    readOnly: true,
                    style: const TextStyle(color: Colors.black87),
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Amount'),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Amount is required';
                      final parsedValue = double.tryParse(value.replaceAll(',', '.'));
                      if (parsedValue == null) return 'Enter a valid number';
                      return null;
                    },
                    onSaved: (value) {
                      _valor = double.parse(value!.replaceAll(',', '.'));
                    },
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Notes'),
                    onSaved: (value) => _obs = value,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Date',
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      controller: TextEditingController(
                        text: _dataValor != null ? formatDate(_dataValor!) : '',
                      ),
                      readOnly: true,
                      onTap: () async {
                        FocusScope.of(context).requestFocus(FocusNode());
                        final selected = await showDatePicker(
                          context: context,
                          initialDate: _dataValor ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (selected != null) {
                          setState(() => _dataValor = selected);
                        }
                      },
                      validator: (value) {
                        if (_dataValor == null) return 'Please select a date';
                        return null;
                      },
                    ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _submitForm,
                    icon: const Icon(Icons.save),
                    label: const Text('Save'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}