import 'package:flutter/material.dart';
import 'package:app/services/OficinaService.dart';
import 'package:app/models/Oficina.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'AddNewOficinaForm.dart';
import 'EditOficinaForm.dart';
import 'ViewOficinaPage.dart';

class ManageOficinasPage extends StatefulWidget {
  const ManageOficinasPage({super.key});

  @override
  _ManageOficinasPageState createState() => _ManageOficinasPageState();
}

class _ManageOficinasPageState extends State<ManageOficinasPage> {
  final OficinaService oficinaService = OficinaService(dotenv.env['BASE_URL']!);
  List<Oficina> _oficinas = [];
  int _currentPage = 1;
  final int _itemsPerPage = 10;

  @override
  void initState() {
    super.initState();
    _fetchOficinas();
  }

  Future<void> _fetchOficinas() async {
    try {
      List<Oficina> oficinas =
          await oficinaService.fetchOficinas(_currentPage, _itemsPerPage);
      setState(() {
        _oficinas = oficinas;
      });
    } catch (e) {
      print('Error fetching workshops: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to fetch workshops.')),
      );
    }
  }

  void _openAddOficinaDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AddNewOficinaForm(
          oficinaService: oficinaService,
          onOficinaAdded: _fetchOficinas,
        );
      },
    );
  }

  void _openEditOficinaDialog(Oficina oficina) {
    showDialog(
      context: context,
      builder: (context) {
        return EditOficinaForm(
          oficinaService: oficinaService,
          oficina: oficina,
          onOficinaUpdated: _fetchOficinas,
        );
      },
    );
  }

  Future<void> _confirmDeleteOficina(Oficina oficina) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content:
              Text('Are you sure you want to delete "${oficina.nomeOficina}"?'),
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
        await oficinaService.deleteOficina(oficina.id.toString());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Workshop "${oficina.nomeOficina}" deleted successfully!')),
        );
        _fetchOficinas();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Failed to delete workshop. Please try again.')),
        );
      }
    }
  }

  void _viewOficinaDetails(Oficina oficina) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: ViewOficinaPage(oficina: oficina),
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
        title: const Text('Manage Workshops'),
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
                  rows: _oficinas.asMap().entries.map((entry) {
                    int index = entry.key;
                    Oficina oficina = entry.value;
                    return DataRow(
                      color: WidgetStateProperty.resolveWith<Color?>(
                          (Set<WidgetState> states) {
                            return index % 2 == 0
                                ? const Color.fromARGB(255, 51, 51, 51) // cor para as linhas pares (mais escuras)
                                : const Color.fromARGB(255, 5, 5, 5); // cor para as linhas ímpares (um pouco mais clara)
                          },
                        ),
                      cells: [
                        DataCell(Text(oficina.id.toString())),
                        DataCell(Text(oficina.nomeOficina)),
                        DataCell(Text(oficina.endereco)),
                        DataCell(Text(oficina.telefone.toString())),
                        DataCell(Text(oficina.obs)),
                        DataCell(Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.visibility),
                              onPressed: () => _viewOficinaDetails(oficina),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _openEditOficinaDialog(oficina),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _confirmDeleteOficina(oficina),
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
                            _fetchOficinas();
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
                      _fetchOficinas();
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
        onPressed: _openAddOficinaDialog,
        tooltip: 'Add New Workshop',
        child: const Icon(Icons.add),
      ),
    );
  }
}
