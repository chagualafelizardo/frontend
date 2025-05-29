import 'package:app/services/TipoMultasService.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:app/models/TipoMulta.dart';

class ManageTipoMultaPage extends StatefulWidget {
  const ManageTipoMultaPage({super.key});

  @override
  State<ManageTipoMultaPage> createState() => _ManageTipoMultaPageState();
}

class _ManageTipoMultaPageState extends State<ManageTipoMultaPage> {
  final TipoMultaService tipoMultaService = TipoMultaService(dotenv.env['BASE_URL']!);
  List<TipoMulta> _tiposMulta = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTiposMulta();
  }

  Future<void> _fetchTiposMulta() async {
    try {
      final data = await tipoMultaService.fetchAll();
      setState(() {
        _tiposMulta = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load fine types: $e')),
      );
    }
  }

  void _showAddDialog() {
    _showTipoMultaDialog(
      context: context,
      title: 'Add Fine Type',
      tipoMulta: null,
      onSave: (description, valor) async {
        await tipoMultaService.create(TipoMulta(description: description, valorpagar: valor));
        _fetchTiposMulta();
        return 'Fine type added successfully';
      },
    );
  }

  void _showEditDialog(TipoMulta tipoMulta) {
    _showTipoMultaDialog(
      context: context,
      title: 'Edit Fine Type',
      tipoMulta: tipoMulta,
      onSave: (description, valor) async {
        final updated = tipoMulta.copyWith(description: description, valorpagar: valor);
        await tipoMultaService.update(updated);
        _fetchTiposMulta();
        return 'Fine type updated successfully';
      },
    );
  }

  void _showViewDialog(TipoMulta tipoMulta) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('View Fine Type'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('ID', tipoMulta.id?.toString() ?? 'N/A'),
              _buildDetailRow('Description', tipoMulta.description),
              _buildDetailRow('Amount', tipoMulta.valorpagar.toStringAsFixed(2)),
              if (tipoMulta.createdAt != null)
                _buildDetailRow('Created At', tipoMulta.createdAt!.toIso8601String()),
              if (tipoMulta.updatedAt != null)
                _buildDetailRow('Updated At', tipoMulta.updatedAt!.toIso8601String()),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value),
          const Divider(),
        ],
      ),
    );
  }

  void _showTipoMultaDialog({
    required BuildContext context,
    required String title,
    required Future<String> Function(String description, double valor) onSave,
    TipoMulta? tipoMulta,
  }) {
    String description = tipoMulta?.description ?? '';
    String valorStr = tipoMulta?.valorpagar.toStringAsFixed(2) ?? '';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: 'Description'),
                controller: TextEditingController(text: description),
                onChanged: (value) => description = value,
              ),
              TextField(
                decoration: const InputDecoration(labelText: 'Amount to Pay'),
                keyboardType: TextInputType.number,
                controller: TextEditingController(text: valorStr),
                onChanged: (value) => valorStr = value,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  final double valor = double.parse(valorStr);
                  final message = await onSave(description, valor);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(message)),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDelete(TipoMulta tipo) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Fine Type'),
        content: Text('Are you sure you want to delete "${tipo.description}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await tipoMultaService.delete(tipo.id!);
        _fetchTiposMulta();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fine type deleted successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting fine type: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Fine Types')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _tiposMulta.isEmpty
              ? const Center(child: Text('No fine types found.'))
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('ID', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Description', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Amount', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    dividerThickness: 1,
                    dataRowColor: MaterialStateProperty.resolveWith<Color?>(
                      (Set<MaterialState> states) {
                        if (states.contains(MaterialState.selected)) {
                          return Theme.of(context).colorScheme.primary.withOpacity(0.1);
                        }
                        return null; // Let the row-level color handle it
                      },
                    ),
                    rows: _tiposMulta.asMap().entries.map((entry) {
                      final index = entry.key;
                      final tipo = entry.value;
                      
                      // Define your color scheme
                      final Color evenRowColor = Theme.of(context).brightness == Brightness.light
                          ? Colors.grey[100]! // Light mode - light grey
                          : Colors.grey[850]!; // Dark mode - dark grey
                      
                      final Color oddRowColor = Theme.of(context).brightness == Brightness.light
                          ? Colors.grey[50]!  // Light mode - very light grey
                          : Colors.grey[900]!; // Dark mode - very dark grey

                      return DataRow(
                        color: MaterialStateProperty.resolveWith<Color?>(
                          (Set<MaterialState> states) {
                            if (states.contains(MaterialState.selected)) {
                              return Theme.of(context).colorScheme.primary.withOpacity(0.1);
                            }
                            return index.isEven ? evenRowColor : oddRowColor;
                          },
                        ),
                        cells: [
                          DataCell(Text(tipo.id?.toString() ?? '', style: TextStyle(
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ))),
                          DataCell(Text(tipo.description, style: TextStyle(
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ))),
                          DataCell(Text(tipo.valorpagar.toStringAsFixed(2), style: TextStyle(
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ))),
                          DataCell(Row(
                            children: [
                              IconButton(
                                icon: Icon(Icons.visibility, 
                                  color: Theme.of(context).brightness == Brightness.light
                                    ? Colors.blue[700]
                                    : Colors.blue[200]),
                                onPressed: () => _showViewDialog(tipo),
                              ),
                              IconButton(
                                icon: Icon(Icons.edit,
                                  color: Theme.of(context).brightness == Brightness.light
                                    ? Colors.orange[700]
                                    : Colors.orange[200]),
                                onPressed: () => _showEditDialog(tipo),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete,
                                  color: Theme.of(context).brightness == Brightness.light
                                    ? Colors.red[700]
                                    : Colors.red[200]),
                                onPressed: () => _confirmDelete(tipo),
                              ),
                            ],
                          )),
                        ],
                      );
                    }).toList(),
                  ),
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        tooltip: 'Add Fine Type',
        child: const Icon(Icons.add),
      ),
    );
  }
}