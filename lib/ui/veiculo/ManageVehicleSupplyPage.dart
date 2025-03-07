import 'package:flutter/material.dart';
import 'package:app/services/VehicleSupplyService.dart';
import 'package:app/models/VehicleSupply.dart';
import 'AddNewVehicleSupplyForm.dart';
import 'EditVehicleSupplyForm.dart';

class ManageVehicleSupplyPage extends StatefulWidget {
  const ManageVehicleSupplyPage({super.key});

  @override
  _ManageVehicleSupplyPageState createState() => _ManageVehicleSupplyPageState();
}

class _ManageVehicleSupplyPageState extends State<ManageVehicleSupplyPage> {
  final VehicleSupplyService vehicleSupplyService = VehicleSupplyService(baseUrl:'http://localhost:5000');
  List<VehicleSupply> _supplies = [];
  int _currentPage = 1;
  final int _itemsPerPage = 10;

  @override
  void initState() {
    super.initState();
    _fetchSupplies();
  }

  Future<void> _fetchSupplies() async {
    try {
      List<VehicleSupply> supplies =
          await vehicleSupplyService.getAllVehicleSupplies();
      setState(() {
        _supplies = supplies;
      });
    } catch (e) {
      print('Error fetching vehicle supplies: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to fetch vehicle supplies.')),
      );
    }
  }

  void _openAddSupplyDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AddNewVehicleSupplyForm(
          vehicleSupplyService: vehicleSupplyService,
          onSupplyAdded: _fetchSupplies,
        );
      },
    );
  }

  void _openEditSupplyDialog(VehicleSupply supply) {
    showDialog(
      context: context,
      builder: (context) {
        return EditVehicleSupplyForm(
          vehicleSupplyService: vehicleSupplyService,
          supply: supply,
          onSupplyUpdated: _fetchSupplies, veiculoId: '',
        );
      },
    );
  }

  Future<void> _confirmDeleteSupply(VehicleSupply supply) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: Text('Are you sure you want to delete "${supply.name}"?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        await vehicleSupplyService.deleteVehicleSupply(supply.id!);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Supply "${supply.name}" deleted successfully!')),
        );
        _fetchSupplies();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Failed to delete supply. Please try again.')),
        );
      }
    }
  }

  // void _viewSupplyDetails(VehicleSupply supply) {
  //   showDialog(
  //     context: context,
  //     builder: (context) {
  //       return AlertDialog(
  //         content: ViewVehicleSupplyPage(supply: supply, veiculoId: '',),
  //         actions: [
  //           TextButton(
  //             onPressed: () {
  //               Navigator.of(context).pop();
  //             },
  //             child: const Text('Close'),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Vehicle Supplies'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 16.0,
                  columns: const [
                    DataColumn(label: Text('ID')),
                    DataColumn(label: Text('Name')),
                    DataColumn(label: Text('Description')),
                    DataColumn(label: Text('Quantity')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: _supplies.asMap().entries.map((entry) {
                    int index = entry.key;
                    VehicleSupply supply = entry.value;
                    return DataRow(
                      color: WidgetStateProperty.resolveWith<Color?>(
                          (Set<WidgetState> states) {
                            return index % 2 == 0
                                ? const Color.fromARGB(255, 10, 10, 10) // cor para as linhas pares (mais escuras)
                                : const Color.fromARGB(255, 49, 49, 49); // cor para as linhas ímpares (um pouco mais clara)
                          },
                        ),
                      cells: [
                        DataCell(Text(supply.id.toString())),
                        DataCell(Text(supply.name)),
                        DataCell(Text(supply.description!)),
                        DataCell(Text(supply.stock.toString())),
                        DataCell(Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.visibility),
                              onPressed: () => "_viewSupplyDetails(supply)",
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _openEditSupplyDialog(supply),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _confirmDeleteSupply(supply),
                            ),
                          ],
                        )),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                ElevatedButton(
                  onPressed: _currentPage > 1
                      ? () {
                          setState(() {
                            _currentPage--;
                            _fetchSupplies();
                          });
                        }
                      : null,
                  child: const Text('Previous'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _currentPage++;
                      _fetchSupplies();
                    });
                  },
                  child: const Text('Next'),
                ),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddSupplyDialog,
        tooltip: 'Add New Supply',
        child: const Icon(Icons.add),
      ),
    );
  }
}
