
import 'package:flutter/material.dart';
import 'package:app/services/ItensEntregaService.dart';
import 'package:app/models/ItensEntrega.dart';
import 'AddNewItensEntregaForm.dart';
import 'EditItensEntregaForm.dart';
import 'ViewItensEntregaPage.dart';

class ManageItensEntregaPage extends StatefulWidget {
  const ManageItensEntregaPage({super.key});

  @override
  _ManageItensEntregaPageState createState() => _ManageItensEntregaPageState();
}

class _ManageItensEntregaPageState extends State<ManageItensEntregaPage> {
  final ItensEntregaService itensEntregaService =
      ItensEntregaService('http://localhost:5000'); // Certifique-se de que o URL base está configurado corretamente no serviço
  List<ItensEntrega> _itensEntrega = [];
  int _currentPage = 1;
  final int _itemsPerPage = 10;

  @override
  void initState() {
    super.initState();
    _fetchItensEntrega();
  }


Future<void> _fetchItensEntrega() async {
  try {
    List<ItensEntrega> itens = await itensEntregaService.getAllItensEntrega();
    setState(() {
      _itensEntrega = itens;
    });
  } catch (e) {
    print('Erro ao buscar os itens de entrega: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Falha ao buscar os itens de entrega.')),
    );
  }
}


  // Future<void> _fetchItensEntrega() async {
  //   try {
  //     List<ItensEntrega> itens = await itensEntregaService.getAllItensEntrega();
  //     setState(() {
  //       _itensEntrega = itens;
  //     });
  //   } catch (e) {
  //     print('Error fetching items: $e');
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('Failed to fetch items.')),
  //     );
  //   }
  // }

  void _openAddItemDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AddNewItensEntregaForm(
          itensEntregaService: itensEntregaService,
          onItemAdded: _fetchItensEntrega,
        );
      },
    );
  }

  void _openEditItemDialog(ItensEntrega item) {
    showDialog(
      context: context,
      builder: (context) {
        return EditItensEntregaForm(
          itensEntregaService: itensEntregaService,
          item: item,
          onItemUpdated: _fetchItensEntrega,
        );
      },
    );
  }

  Future<void> _confirmDeleteItem(ItensEntrega item) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: Text('Are you sure you want to delete "${item.item}"?'),
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
        await itensEntregaService.deleteItensEntrega(item.id!);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Item "${item.item}" deleted successfully!')),
        );
        _fetchItensEntrega();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Failed to delete item. Please try again.')),
        );
      }
    }
  }

  void _viewItemDetails(ItensEntrega item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ViewItensEntregaPage(item: item),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Itens Entrega'),
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
                    DataColumn(label: Text('Item Name')),
                    DataColumn(label: Text('Notes')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: _itensEntrega.asMap().entries.map((entry) {
                    int index = entry.key;
                    ItensEntrega item = entry.value;
                    return DataRow(
                      color: WidgetStateProperty.resolveWith<Color?>(
                          (Set<WidgetState> states) {
                            return index % 2 == 0
                                ? const Color.fromARGB(255, 52, 52, 53) // cor para as linhas pares (mais escuras)
                                : const Color.fromARGB(255, 8, 8, 8); // cor para as linhas ímpares (um pouco mais clara)
                          },
                        ),
                      cells: [
                        DataCell(Text(item.id.toString())),
                        DataCell(Text(item.item ?? 'No Name')),
                        DataCell(Text(item.obs ?? '')),
                        DataCell(Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.visibility),
                              onPressed: () => _viewItemDetails(item),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _openEditItemDialog(item),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _confirmDeleteItem(item),
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
                            _fetchItensEntrega();
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
                      _fetchItensEntrega();
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
        onPressed: _openAddItemDialog,
        tooltip: 'Add New Item',
        child: const Icon(Icons.add),
      ),
    );
  }
}
