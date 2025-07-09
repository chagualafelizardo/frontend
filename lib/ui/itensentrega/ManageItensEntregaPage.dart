import 'package:flutter/material.dart';
import 'package:app/services/ItensEntregaService.dart';
import 'package:app/models/ItensEntrega.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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
      ItensEntregaService(dotenv.env['BASE_URL']!);
  List<ItensEntrega> _itensEntrega = [];
  int _currentPage = 1;
  final int _itemsPerPage = 10;
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';
  bool _isDeleting = false;
  int? _deletingItemId;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      await _fetchItensEntrega();
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _fetchItensEntrega() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      List<ItensEntrega> itens = await itensEntregaService.getAllItensEntrega();
      if (!mounted) return;
      
      setState(() {
        _itensEntrega = itens;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _errorMessage = 'Failed to fetch items: ${e.toString()}';
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
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        setState(() {
          _isDeleting = true;
          _deletingItemId = item.id;
        });

        await itensEntregaService.deleteItensEntrega(item.id!);
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${item.item}" deleted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        await _fetchItensEntrega();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isDeleting = false;
            _deletingItemId = null;
          });
        }
      }
    }
  }

void _viewItemDetails(ItensEntrega item) {
  showDialog(
    context: context,
    builder: (context) {
      return ViewItensEntregaPage(item: item);
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
          Text('Loading items...', style: TextStyle(fontSize: 16)),
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
            onPressed: _fetchItensEntrega,
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
          DataColumn(label: Text('Item Name')),
          DataColumn(label: Text('Notes')),
          DataColumn(label: Text('Actions')),
        ],
        rows: _itensEntrega.map((item) {
          return DataRow(
            color: WidgetStateProperty.resolveWith<Color?>(
              (Set<WidgetState> states) {
                return _itensEntrega.indexOf(item) % 2 == 0
                    ? const Color.fromARGB(255, 52, 52, 53)
                    : const Color.fromARGB(255, 8, 8, 8);
              },
            ),
            cells: [
              DataCell(Text(item.id.toString())),
              DataCell(Text(item.item ?? 'No Name')),
              DataCell(Text(item.obs ?? '')),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.visibility),
                      onPressed: () => _viewItemDetails(item),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _openEditItemDialog(item),
                    ),
                    if (_isDeleting && _deletingItemId == item.id)
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    else
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmDeleteItem(item),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Vehicle Delivery Items'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchItensEntrega,
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
                if (!_isLoading && !_hasError && _itensEntrega.isNotEmpty) ...[
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
                                  _fetchItensEntrega();
                                });
                              }
                            : null,
                        child: const Text('Previous'),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: _itensEntrega.length == _itemsPerPage
                            ? () {
                                setState(() {
                                  _currentPage++;
                                  _fetchItensEntrega();
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
                if (!_isLoading && !_hasError && _itensEntrega.isEmpty)
                  const Center(child: Text('No items found')),
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
        onPressed: _openAddItemDialog,
        tooltip: 'Add New Item',
        child: const Icon(Icons.add),
      ),
    );
  }
}