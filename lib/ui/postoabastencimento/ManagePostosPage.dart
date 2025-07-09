import 'package:flutter/material.dart';
import 'package:app/models/Posto.dart';
import 'package:app/services/PostoService.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'AddNewPostoForm.dart';
import 'EditPostoForm.dart';
import 'ViewPostoPage.dart';
import 'ViewPostoPage.dart';

class ManagePostosPage extends StatefulWidget {
  const ManagePostosPage({super.key});

  @override
  _ManagePostosPageState createState() => _ManagePostosPageState();
}

class _ManagePostosPageState extends State<ManagePostosPage> {
  final PostoService postoService = PostoService(dotenv.env['BASE_URL']!);
  List<Posto> _postos = [];
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
      await _fetchPostos();
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchPostos() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      List<Posto> postos = await postoService.fetchPostos(_currentPage, _itemsPerPage);
      if (!mounted) return;
      
      setState(() {
        _postos = postos;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _errorMessage = 'Failed to fetch postos: ${e.toString()}';
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

  Future<bool> _openAddPostoDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: AddNewPostoForm(
          postoService: postoService,
          onPostoAdded: () {
            if (mounted) {
              _fetchPostos();
            }
          },
        ),
      ),
    );
    return result ?? false;
  }

  void _openEditPostoDialog(Posto posto) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: EditPostoForm(
          postoService: postoService,
          posto: posto,
          onPostoUpdated: _fetchPostos,
        ),
      ),
    );
  }

  Future<void> _confirmDeletePosto(Posto posto) async {
    print('[DELETE POSTO] Iniciando processo de exclusão para: ${posto.nomePosto} (ID: ${posto.id})');

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete', style: TextStyle(color: Colors.red)),
          content: Text('Are you sure you want to delete "${posto.nomePosto}"?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                print('[DELETE POSTO] Usuário cancelou a exclusão');
                Navigator.of(context).pop(false);
              },
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                print('[DELETE POSTO] Usuário confirmou a exclusão');
                Navigator.of(context).pop(true);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        print('[DELETE POSTO] Iniciando exclusão no servidor...');
        setState(() => _isLoading = true);

        // Log dos dados antes de deletar
        print('[DELETE POSTO] Dados do posto a ser deletado:');
        print(' - ID: ${posto.id}');
        print(' - Nome: ${posto.nomePosto}');
        print(' - Endereço: ${posto.endereco}');
        print(' - Telefone: ${posto.telefone}');
        print(' - Observações: ${posto.obs}');

        await postoService.deletePosto(posto.id);
        print('[DELETE POSTO] Posto deletado com sucesso no servidor');

        if (!mounted) {
          print('[DELETE POSTO] Widget não está montado, abortando atualização');
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${posto.nomePosto}" deleted successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        print('[DELETE POSTO] Atualizando lista de postos...');
        await _fetchPostos();
        print('[DELETE POSTO] Lista atualizada com sucesso');

      } catch (e) {
        print('[DELETE POSTO ERROR] Erro ao deletar posto: $e');
        if (!mounted) {
          print('[DELETE POSTO WARNING] Widget não está montado, não é possível mostrar erro');
          return;
        }

        String errorMessage = 'Failed to delete: ${e.toString()}';
        if (e.toString().contains('timeout')) {
          errorMessage = 'Connection timeout. Please try again.';
        } else if (e.toString().contains('404')) {
          errorMessage = 'Posto not found on server.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      } finally {
        if (mounted) {
          print('[DELETE POSTO] Finalizando estado de loading');
          setState(() => _isLoading = false);
        } else {
          print('[DELETE POSTO WARNING] Widget não está montado, não é possível atualizar estado');
        }
      }
    } else {
      print('[DELETE POSTO] Exclusão cancelada pelo usuário');
    }
  }

  void _viewPostoDetails(Posto posto) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Station Details'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('ID:', posto.id.toString()),
                _buildDetailRow('Name:', posto.nomePosto),
                _buildDetailRow('Address:', posto.endereco),
                _buildDetailRow('Phone:', posto.telefone.toString()),
                _buildDetailRow('Notes:', posto.obs ?? 'N/A'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

Widget _buildDetailRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
        ),
        Expanded(
          child: Text(value),
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
        headingRowColor: WidgetStateProperty.resolveWith<Color>(
          (states) => Theme.of(context).primaryColor.withOpacity(0.1),
        ),
        columns: const [
          DataColumn(label: Text('ID', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Name', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Address', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Phone', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Notes', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
        ],
        rows: _postos.map((posto) {
          return DataRow(
            color: WidgetStateProperty.resolveWith<Color?>(
              (states) => _postos.indexOf(posto) % 2 == 0
                  ? const Color.fromARGB(255, 83, 83, 83)
                  : const Color.fromARGB(255, 37, 37, 37),
            ),
            cells: [
              DataCell(Text(posto.id.toString())),
              DataCell(Text(posto.nomePosto)),
              DataCell(Text(posto.endereco)),
              DataCell(Text(posto.telefone.toString())),
              DataCell(Text(posto.obs ?? 'N/A')),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.visibility, color: Colors.blue),
                      onPressed: () => _viewPostoDetails(posto),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.orange),
                      onPressed: () => _openEditPostoDialog(posto),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _confirmDeletePosto(posto),
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
          Text('Loading postos...', style: TextStyle(fontSize: 16)),
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
            onPressed: _fetchPostos,
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
          const Icon(Icons.local_gas_station, size: 50, color: Colors.grey),
          const SizedBox(height: 20),
          const Text('No postos found', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: _openAddPostoDialog,
            child: const Text('Add New Posto'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Postos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchPostos,
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
                if (!_isLoading && !_hasError && _postos.isNotEmpty) ...[
                  Expanded(child: _buildDataTable()),
                ],
                if (_isLoading) Expanded(child: _buildLoadingIndicator()),
                if (_hasError) Expanded(child: _buildErrorWidget()),
                if (!_isLoading && !_hasError && _postos.isEmpty) 
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
          await _openAddPostoDialog();
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

