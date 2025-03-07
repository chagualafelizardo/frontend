import 'package:flutter/material.dart';
import 'package:app/models/Posto.dart';
import 'package:app/services/PostoService.dart';
import 'AddNewPostoForm.dart';
import 'EditPostoForm.dart';
import 'ViewPostoPage.dart';

class ManagePostosPage extends StatefulWidget {
  const ManagePostosPage({super.key});

  @override
  _ManagePostosPageState createState() => _ManagePostosPageState();
}

class _ManagePostosPageState extends State<ManagePostosPage> {
  final PostoService postoService = PostoService('http://localhost:5000');
  List<Posto> _postos = [];
  int _currentPage = 1;
  final int _itemsPerPage = 10;

  @override
  void initState() {
    super.initState();
    _fetchPostos();
  }

  Future<void> _fetchPostos() async {
    try {
      List<Posto> postos =
          await postoService.fetchPostos(_currentPage, _itemsPerPage);
      setState(() {
        _postos = postos;
      });
    } catch (e) {
      print('Error fetching postos: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to fetch postos.')),
      );
    }
  }

  void _openAddPostoDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AddNewPostoForm(
          postoService: postoService,
          onPostoAdded: _fetchPostos,
        );
      },
    );
  }

  void _openEditPostoDialog(Posto posto) {
    showDialog(
      context: context,
      builder: (context) {
        return EditPostoForm(
          postoService: postoService,
          posto: posto,
          onPostoUpdated: _fetchPostos,
        );
      },
    );
  }

  Future<void> _confirmDeletePosto(Posto posto) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content:
              Text('Are you sure you want to delete "${posto.nomePosto}"?'),
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
        await postoService.deletePosto(posto.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Posto "${posto.nomePosto}" deleted successfully!'),
          ),
        );
        _fetchPostos();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete posto. Please try again.'),
          ),
        );
      }
    }
  }

  void _viewPostoDetails(Posto posto) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: ViewPostoPage(posto: posto),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Postos'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start, // Align content to the left
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 16.0,
                  columns: const [
                    DataColumn(label: Text('ID')),
                    DataColumn(label: Text('Name')),
                    DataColumn(label: Text('Address')),
                    DataColumn(label: Text('Phone')),
                    DataColumn(label: Text('Notes')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: _postos.asMap().entries.map((entry) {
                    int index = entry.key;
                    Posto posto = entry.value;
                    return DataRow(
                      color: WidgetStateProperty.resolveWith<Color?>(
                          (Set<WidgetState> states) {
                            return index % 2 == 0
                                ? const Color.fromARGB(255, 57, 57, 58) // cor para as linhas pares (mais escuras)
                                : const Color.fromARGB(255, 12, 12, 12); // cor para as linhas ímpares (um pouco mais clara)
                          },
                        ),
                      cells: [
                        DataCell(Text(posto.id.toString())),
                        DataCell(Text(posto.nomePosto)),
                        DataCell(Text(posto.endereco)),
                        DataCell(Text(posto.telefone.toString())),
                        DataCell(Text(posto.obs)),
                        DataCell(Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.visibility),
                              onPressed: () => _viewPostoDetails(posto),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _openEditPostoDialog(posto),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _confirmDeletePosto(posto),
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
              mainAxisAlignment:
                  MainAxisAlignment.start, // Align buttons to the start
              children: [
                ElevatedButton(
                  onPressed: _currentPage > 1
                      ? () {
                          setState(() {
                            _currentPage--;
                            _fetchPostos();
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
                      _fetchPostos();
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
        onPressed: _openAddPostoDialog,
        tooltip: 'Add New Posto',
        child: const Icon(Icons.add),
      ),
    );
  }
}
