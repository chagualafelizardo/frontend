import 'package:app/models/Atendimento.dart';
import 'package:app/models/TipoMulta.dart';
import 'package:app/services/AtendimentoService.dart';
import 'package:app/services/TipoMultasService.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:app/models/Multa.dart';
import 'package:app/services/MultaService.dart';
import 'package:intl/intl.dart';

class ManageMultaPage extends StatefulWidget {
  const ManageMultaPage({super.key});

  @override
  State<ManageMultaPage> createState() => _ManageMultaPageState();
}

class _ManageMultaPageState extends State<ManageMultaPage> {
  late final MultaService multaService = MultaService(dotenv.env['BASE_URL']!);
  List<Multa> _multas = [];
  bool _isLoading = true;

  List<int> _atendimentos = []; // Adicione no início da classe
  int? _selectedAtendimentoId;

  @override
  void initState() {
    super.initState();
    _fetchMultas();
  }

  Future<void> _fetchMultas() async {
    try {
      final data = await multaService.fetchMultas();
      setState(() {
        _multas = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load fines: $e')),
      );
    }
  }

 Future<void> _showAddDialog({Multa? multa}) async {
  final valorController = TextEditingController(
    text: multa != null ? multa.valorpagar.toString() : '',
  );
  final observationController = TextEditingController(text: multa?.observation ?? '');

  // Lista e selecionado dos tipos de multa
  List<TipoMulta> tiposMulta = [];
  TipoMulta? _selectedTipoMulta;

  // Lista de atendimentos
  List<Atendimento> atendimentos = [];
  int? _selectedAtendimentoId = multa?.atendimentoId;

  // Instancia o serviço (ajuste a baseUrl conforme necessário)
  final tipoMultaService = TipoMultaService(dotenv.env['BASE_URL']!);

  try {
    tiposMulta = await tipoMultaService.fetchAll();

    // Se estiver editando, tenta setar o tipo selecionado baseado na descrição da multa
  if (multa != null) {
    if (tiposMulta.isNotEmpty) {
      _selectedTipoMulta = tiposMulta.firstWhere(
        (tipo) => tipo.description == multa.description,
        orElse: () => tiposMulta[0], // Sempre retorna um TipoMulta válido
      );
    } else {
      _selectedTipoMulta = null; // Ou defina um valor padrão
    }
  }

  } catch (e) {
    print('Erro ao buscar tipos de multa: $e');
  }

  try {
    atendimentos = await AtendimentoService(dotenv.env['BASE_URL']!).fetchAtendimentos();
  } catch (e) {
    print('Erro ao buscar atendimentos: $e');
  }

  await showDialog(
    context: context,
    builder: (_) => StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          title: Text(multa == null ? 'Add Fine' : 'Edit Fine'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<TipoMulta>(
                  value: _selectedTipoMulta,
                  items: tiposMulta.map((tipo) {
                    return DropdownMenuItem<TipoMulta>(
                      value: tipo,
                      child: Text(tipo.description),
                    );
                  }).toList(),
                  onChanged: (tipo) {
                    setState(() {
                      _selectedTipoMulta = tipo;
                      // Opcional: atualizar valor do valorpagar quando tipo mudar
                      if (tipo != null) {
                        valorController.text = tipo.valorpagar.toString();
                      }
                    });
                  },
                  decoration: const InputDecoration(labelText: 'Select Fine Type'),
                ),
                TextField(
                  controller: valorController,
                  decoration: const InputDecoration(labelText: 'Amount to Pay'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: observationController,
                  decoration: const InputDecoration(labelText: 'Observation'),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: _selectedAtendimentoId,
                  items: atendimentos.map((atendimento) {
                    return DropdownMenuItem<int>(
                      value: atendimento.id,
                      child: Text('Atendimento #${atendimento.id}'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedAtendimentoId = value;
                    });
                  },
                  decoration: const InputDecoration(labelText: 'Select Atendimento'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  if (_selectedTipoMulta == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please select a fine type')),
                    );
                    return;
                  }

                  final double valor = double.parse(valorController.text);

                  final Multa newMulta = Multa(
                    id: multa?.id,
                    description: _selectedTipoMulta!.description, // salva a descrição do tipo de multa
                    valorpagar: valor,
                    observation: observationController.text,
                    atendimentoId: _selectedAtendimentoId,
                  );

                  if (multa == null) {
                    await multaService.createMulta(newMulta);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Fine added successfully')),
                    );
                  } else {
                    await multaService.updateMulta(newMulta);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Fine updated successfully')),
                    );
                  }

                  Navigator.pop(context);
                  _fetchMultas();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error saving fine: $e')),
                  );
                }
              },
              child: Text(multa == null ? 'Add' : 'Update'),
            ),
          ],
        );
      },
    ),
  );
}




  void _confirmDelete(Multa multa) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Fine'),
        content: Text('Are you sure you want to delete "${multa.description}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await multaService.deleteMulta(multa.id!);
        _fetchMultas();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fine deleted successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting fine: $e')),
        );
      }
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat('yyyy-MM-dd').format(date);
  }

void _showViewDialog(Multa multa) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Fine Details'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ID: ${multa.id ?? '-'}'),
          const SizedBox(height: 8),
          Text('Description: ${multa.description}'),
          const SizedBox(height: 8),
          Text('Amount to Pay: ${multa.valorpagar.toStringAsFixed(2)}'),
          const SizedBox(height: 8),
          Text('Observation: ${multa.observation ?? 'N/A'}'),
          const SizedBox(height: 8),
          Text('Created At: ${_formatDate(multa.createdAt)}'),
        ],
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


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Fines')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _multas.isEmpty
              ? const Center(child: Text('No fines found.'))
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('ID', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Description', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Amount', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Observation', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Atendimento ID', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Created At', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      dividerThickness: 1,
                      rows: _multas.asMap().entries.map((entry) {
                        final index = entry.key;
                        final multa = entry.value;

                        // Define row colors for alternating
                        final Color evenRowColor = Theme.of(context).brightness == Brightness.light
                            ? Colors.grey[100]!
                            : Colors.grey[850]!;
                        final Color oddRowColor = Theme.of(context).brightness == Brightness.light
                            ? Colors.grey[50]!
                            : Colors.grey[900]!;

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
                            DataCell(Text(multa.id?.toString() ?? '')),
                            DataCell(Text(multa.description)),
                            DataCell(Text(multa.valorpagar.toStringAsFixed(2))),
                            DataCell(Text(multa.observation!)),
                            DataCell(Text(multa.atendimentoId?.toString() ?? '')),
                            DataCell(Text(_formatDate(multa.createdAt))),
                            DataCell(Row(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.visibility,
                                      color: Theme.of(context).brightness == Brightness.light
                                          ? Colors.blue[700]
                                          : Colors.blue[200]),
                                  onPressed: () => _showViewDialog(multa),
                                ),
                                IconButton(
                                  icon: Icon(Icons.edit,
                                      color: Theme.of(context).brightness == Brightness.light
                                          ? Colors.orange[700]
                                          : Colors.orange[200]),
                                  onPressed: () => _showAddDialog(multa: multa),
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete,
                                      color: Theme.of(context).brightness == Brightness.light
                                          ? Colors.red[700]
                                          : Colors.red[200]),
                                  onPressed: () => _confirmDelete(multa),
                                ),
                              ],
                            )),
                          ],
                        );
                      }).toList(),
                    ),
                  ),

                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(),
        tooltip: 'Add Fine',
        child: const Icon(Icons.add),
      ),
    );
  }
}
