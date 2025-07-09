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
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchOficinas();
  }

  Future<void> _fetchOficinas() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      List<Oficina> oficinas =
          await oficinaService.fetchOficinas(_currentPage, _itemsPerPage);
      if (!mounted) return;
      
      setState(() {
        _oficinas = oficinas;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _errorMessage = 'Failed to fetch workshops: ${e.toString()}';
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
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 400, // Largura máxima ajustada
              minWidth: 300, // Largura mínima para manter a legibilidade
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Workshop Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Flexible(
                    child: SingleChildScrollView(
                      child: ViewOficinaPage(oficina: oficina),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Close'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }


  Widget _buildLoadingIndicator() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 20),
          Text('Loading workshops...', style: TextStyle(fontSize: 16)),
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
            onPressed: _fetchOficinas,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildDataTable() {
    return SingleChildScrollView(
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
                    ? const Color.fromARGB(255, 51, 51, 51)
                    : const Color.fromARGB(255, 5, 5, 5);
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Workshops'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchOficinas,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!_isLoading && !_hasError && _oficinas.isNotEmpty) ...[
                  Expanded(child: _buildDataTable()),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
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
                        onPressed: _oficinas.length == _itemsPerPage
                            ? () {
                                setState(() {
                                  _currentPage++;
                                  _fetchOficinas();
                                });
                              }
                            : null,
                        child: const Text('Next'),
                      ),
                    ],
                  ),
                ],
                if (_isLoading) Expanded(child: _buildLoadingIndicator()),
                if (_hasError) Expanded(child: _buildErrorWidget()),
                if (!_isLoading && !_hasError && _oficinas.isEmpty)
                  const Center(child: Text('No workshops found')),
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
        onPressed: _openAddOficinaDialog,
        tooltip: 'Add New Workshop',
        child: const Icon(Icons.add),
      ),
    );
  }
}