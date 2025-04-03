import 'package:app/models/DetalhesManutencao.dart';
import 'package:app/models/VehicleSupply.dart';
import 'package:app/services/DetalhesManutencaoService.dart';
import 'package:flutter/material.dart';
import 'package:app/models/Manutencao.dart';
import 'package:app/models/Item.dart';
import 'package:app/services/ManutencaoService.dart';
import 'package:app/services/VehicleSupplyService.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ManageManutencoesPage extends StatefulWidget {
  const ManageManutencoesPage({super.key});

  @override
  _ManageManutencoesPageState createState() => _ManageManutencoesPageState();
}

class _ManageManutencoesPageState extends State<ManageManutencoesPage> {
  final ManutencaoService manutencaoService = ManutencaoService(dotenv.env['BASE_URL']!);
  final VehicleSupplyService vehicleSupplyService = VehicleSupplyService(baseUrl: dotenv.env['BASE_URL']!);
  final DetalhesManutencaoService detalhesManutencaoService = DetalhesManutencaoService(dotenv.env['BASE_URL']!);

  List<Manutencao> _manutencoes = [];
  List<Manutencao> _manutencoesConcluidas = [];
  List<DetalhesManutencao> _detalhesManutencoes = []; // Nova lista para detalhes de manutenção
  List<VehicleSupply> _itens = [];
  int _currentPage = 1;
  final int _itemsPerPage = 10;

  @override
  void initState() {
    super.initState();
    _fetchManutencoes();
    _fetchDetalhesManutencoes(); // Buscar detalhes de manutenção ao iniciar
  }

  Future<void> _fetchManutencoes() async {
    try {
      List<Manutencao> manutencoes = await manutencaoService.fetchManutencoes();
      setState(() {
        _manutencoes = manutencoes.where((m) => m.dataSaida == null).toList(); // Em manutenção
        _manutencoesConcluidas = manutencoes.where((m) => m.dataSaida != null).toList(); // Concluídas
      });
    } catch (e) {
      print('Error fetching manutencoes: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to fetch maintenance records.')),
      );
    }
  }

  Future<void> _fetchDetalhesManutencoes() async {
    try {
      List<DetalhesManutencao> detalhes = await detalhesManutencaoService.fetchDetalhesManutencao();
      setState(() {
        _detalhesManutencoes = detalhes;
      });
    } catch (e) {
      print('Error fetching maintenance details: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to fetch maintenance details.')),
      );
    }
  }

  Future<void> _fetchItens() async {
    try {
      List<VehicleSupply> item = await vehicleSupplyService.getAllVehicleSupplies();
      setState(() {
        _itens = item;
      });
    } catch (e) {
      print('Error fetching items: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to fetch items.')),
      );
    }
  }

  void _openAddManutencaoDialog() {
    // showDialog(
    //   context: context,
    //   builder: (context) {
    //     return AddNewManutencaoForm(
    //       manutencaoService: manutencaoService,
    //       onManutencaoAdded: _fetchManutencoes,
    //     );
    //   },
    // );
  }

  Future<void> _confirmDeleteManutencao(Manutencao manutencao) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text('Are you sure you want to delete this maintenance record?'),
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
        await manutencaoService.deleteManutencao(manutencao.id!);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Maintenance record deleted successfully!'),
          ),
        );
        _fetchManutencoes();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete maintenance record. Please try again.'),
          ),
        );
      }
    }
  }

  void _viewDetalhesManutencao(DetalhesManutencao detalhe) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Maintenance Details'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ID: ${detalhe.id}'),
                Text('Item: ${detalhe.item}'),
                Text('Notes: ${detalhe.obs}'),
                Text('Maintenance ID: ${detalhe.manutencaoID}'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmDeleteDetalhesManutencao(DetalhesManutencao detalhe) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text('Are you sure you want to delete this maintenance detail?'),
          actions: [
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
        await detalhesManutencaoService.deleteDetalhesManutencao(detalhe.id!);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Maintenance detail deleted successfully!'),
          ),
        );
        _fetchDetalhesManutencoes(); // Atualiza a lista após a exclusão
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete maintenance detail. Please try again.'),
          ),
        );
      }
    }
  }

  void _viewManutencaoDetails(Manutencao manutencao) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ID: ${manutencao.id}'),
                Text('Entry Date: ${manutencao.dataEntrada}'),
                Text('Exit Date: ${manutencao.dataSaida ?? "N/A"}'),
                Text('Vehicle ID: ${manutencao.veiculoID}'),
                Text('Workshop ID: ${manutencao.oficinaID}'),
                Text('Service ID: ${manutencao.atendimentoID}'),
                Text('Notes: ${manutencao.obs ?? "N/A"}'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _openAdvanceManutencaoDialog(Manutencao manutencao) async {
  await _fetchItens(); // Carrega os itens disponíveis

  // Controlador para o campo de observações
  TextEditingController obsController = TextEditingController();

  showDialog(
  context: context,
  builder: (context) {
    return StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Advance Maintenance',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          content: SizedBox(
            width: 400, // Definir um tamanho fixo para melhor UX
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Vehicle ID: ${manutencao.veiculoID}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Service ID: ${manutencao.atendimentoID}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Items for Replacement:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 200, // Definir altura fixa para evitar expansão excessiva
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListView.builder(
                      itemCount: _itens.length,
                      itemBuilder: (context, index) {
                        final item = _itens[index];
                        return Container(
                          decoration: BoxDecoration(
                            color: index.isEven
                                ? const Color.fromARGB(255, 63, 63, 63)
                                : const Color.fromARGB(255, 12, 12, 12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: CheckboxListTile(
                            title: Text(item.description!),
                            value: item.selected,
                            onChanged: (value) {
                              setState(() {
                                item.selected = value ?? false;
                              });
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Observations:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: obsController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Enter observations...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                List<VehicleSupply> itensSelecionados =
                    _itens.where((item) => item.selected).toList();
                String observacoes = obsController.text.trim();

                await _saveItensManutencao(manutencao, itensSelecionados, observacoes);
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  },
);

}

  Future<void> _saveItensManutencao(Manutencao manutencao, List<VehicleSupply> itensSelecionados, String observacoes) async {
  try {
    // Para cada item selecionado, crie um detalhe de manutenção
    for (var item in itensSelecionados) {
      final detalhe = DetalhesManutencao(
        item: item.description!,
        manutencaoID: manutencao.id!,
        obs: observacoes, // Inclui as observações
      );

      await detalhesManutencaoService.createDetalhesManutencao(detalhe);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Items and observations saved successfully!'),
      ),
    );

    _fetchManutencoes();
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Failed to save items and observations. Please try again.'),
      ),
    );
    print('Error saving items and observations: $e');
  }
}

  // Função para retornar a cor com base no índice da linha
  Color _getRowColor(int index) {
    return index % 2 == 0 ? const Color.fromARGB(255, 14, 13, 13) : const Color.fromARGB(255, 58, 58, 58)!;
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // Número de abas
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Manage Maintenance'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'In Progress'), // Primeira aba
              Tab(text: 'Completed'), // Segunda aba
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Primeira aba: Veículos em manutenção
            Padding(
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
                          DataColumn(label: Text('Entry Date')),
                          DataColumn(label: Text('Exit Date')),
                          DataColumn(label: Text('Vehicle ID')),
                          DataColumn(label: Text('Workshop ID')),
                          DataColumn(label: Text('Service ID')),
                          DataColumn(label: Text('Notes')),
                          DataColumn(label: Text('Actions')),
                        ],
                        rows: _manutencoes.asMap().entries.map((entry) {
                          final index = entry.key;
                          final manutencao = entry.value;
                          return DataRow(
                            color: MaterialStateProperty.resolveWith<Color>(
                              (Set<MaterialState> states) {
                                return _getRowColor(index);
                              },
                            ),
                            cells: [
                              DataCell(Text(manutencao.id.toString())),
                              DataCell(Text(manutencao.dataEntrada.toString())),
                              DataCell(Text(manutencao.dataSaida?.toString() ?? 'N/A')),
                              DataCell(Text(manutencao.veiculoID.toString())),
                              DataCell(Text(manutencao.oficinaID.toString())),
                              DataCell(Text(manutencao.atendimentoID.toString())),
                              DataCell(Text(manutencao.obs ?? 'N/A')),
                              DataCell(Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.visibility),
                                    onPressed: () => _viewManutencaoDetails(manutencao),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () => _viewManutencaoDetails(manutencao),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () => _confirmDeleteManutencao(manutencao),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.arrow_forward),
                                    onPressed: () => _openAdvanceManutencaoDialog(manutencao),
                                  ),
                                ],
                              )),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Segunda aba: Detalhes de Manutenção
            Padding(
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
                          DataColumn(label: Text('Item')),
                          DataColumn(label: Text('Notes')),
                          DataColumn(label: Text('Maintenance ID')),
                          DataColumn(label: Text('Actions')),
                        ],
                        rows: _detalhesManutencoes.asMap().entries.map((entry) {
                          final index = entry.key;
                          final detalhe = entry.value;
                          return DataRow(
                            color: MaterialStateProperty.resolveWith<Color?>(
                              (Set<MaterialState> states) {
                                return index.isEven ? const Color.fromARGB(255, 12, 12, 12) : const Color.fromARGB(255, 58, 58, 58)!; // Alternando cores
                              },
                            ),
                            cells: [
                              DataCell(Text(detalhe.id.toString())),
                              DataCell(Text(detalhe.item)),
                              DataCell(Text(detalhe.obs ?? 'N/A')),
                              DataCell(Text(detalhe.manutencaoID.toString())),
                              DataCell(Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.visibility),
                                    onPressed: () => _viewDetalhesManutencao(detalhe),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () => _viewDetalhesManutencao(detalhe),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () => _confirmDeleteDetalhesManutencao(detalhe),
                                  ),
                                ],
                              )),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
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