import 'package:flutter/material.dart';
import 'package:app/services/VehicleSupplyService.dart';
import 'package:app/models/VehicleSupply.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'AddNewVehicleSupplyForm.dart';
import 'EditVehicleSupplyForm.dart';

class ManageVehicleSupplyPage extends StatefulWidget {
  const ManageVehicleSupplyPage({super.key});

  @override
  _ManageVehicleSupplyPageState createState() => _ManageVehicleSupplyPageState();
}

class _ManageVehicleSupplyPageState extends State<ManageVehicleSupplyPage> {
  final VehicleSupplyService vehicleSupplyService = VehicleSupplyService(baseUrl: dotenv.env['BASE_URL']!);
  List<VehicleSupply> _supplies = [];
  int _currentPage = 1;
  final int _itemsPerPage = 10;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      await _fetchSupplies();
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchSupplies() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      List<VehicleSupply> supplies = await vehicleSupplyService.getAllVehicleSupplies();
      setState(() {
        _supplies = supplies;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Failed to fetch supplies: ${e.toString()}';
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<bool> _openAddSupplyDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AddNewVehicleSupplyForm(
          vehicleSupplyService: vehicleSupplyService,
          onSupplyAdded: () {
            _fetchSupplies();
            Navigator.of(context).pop(true);
          },
        );
      },
    );
    return result ?? false;
  }

  

  void _openEditSupplyDialog(VehicleSupply supply) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        contentPadding: const EdgeInsets.all(20),
        content: EditVehicleSupplyForm(
          vehicleSupplyService: vehicleSupplyService,
          supply: supply,
          onSupplyUpdated: _fetchSupplies,
          veiculoId: '',
        ),
      ),
    );
  }

  Future<void> _confirmDeleteSupply(VehicleSupply supply) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete', style: TextStyle(color: Colors.red)),
          content: Text('Are you sure you want to delete "${supply.name}"?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        setState(() => _isLoading = true);
        await vehicleSupplyService.deleteVehicleSupply(supply.id!);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${supply.name}" deleted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        await _fetchSupplies();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Widget _buildDataTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 16.0,
        headingRowColor: WidgetStateProperty.resolveWith<Color>(
          (states) => Theme.of(context).primaryColor.withOpacity(0.1),
        ),
        columns: const [
          DataColumn(label: Text('ID', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Name', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Description', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Quantity', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
        ],
        rows: _supplies.map((supply) {
          return DataRow(
            color: WidgetStateProperty.resolveWith<Color?>(
              (states) => _supplies.indexOf(supply) % 2 == 0
                  ? const Color.fromARGB(255, 122, 122, 122)
                  : const Color.fromARGB(255, 41, 40, 40),
            ),
            cells: [
              DataCell(Text(supply.id.toString())),
              DataCell(Text(supply.name)),
              DataCell(Text(supply.description ?? 'N/A')),
              DataCell(Text(supply.stock.toString())),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _openEditSupplyDialog(supply),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _confirmDeleteSupply(supply),
                    ),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 20),
          Text('Loading supplies...', style: TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 50),
          const SizedBox(height: 20),
          Text(_errorMessage, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _fetchSupplies,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inventory_2_outlined, size: 50, color: Colors.grey),
          const SizedBox(height: 20),
          const Text('No supplies found', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: _openAddSupplyDialog,
            child: const Text('Add New Supply'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Vehicle Supplies'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchSupplies,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!_isLoading && !_hasError && _supplies.isNotEmpty) ...[
                  Expanded(child: _buildDataTable()),
                ],
                if (_isLoading) Expanded(child: _buildLoadingIndicator()),
                if (_hasError) Expanded(child: _buildErrorWidget()),
                if (!_isLoading && !_hasError && _supplies.isEmpty) 
                  Expanded(child: _buildEmptyState()),
              ],
            ),
          ),
          if (_isLoading)
            const ModalBarrier(
              dismissible: false,
              color: Colors.black54,
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Mostrar loading
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const Center(child: CircularProgressIndicator()),
          );

          try {
            await _openAddSupplyDialog(); // Agora pode usar await pois a função retorna Future<void>
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error: ${e.toString()}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          } finally {
            // Fechar loading
            if (mounted) {
              Navigator.of(context).pop();
            }
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}