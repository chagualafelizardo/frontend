import 'package:flutter/material.dart';
import 'package:app/services/ItemService.dart';
import 'package:app/models/Item.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'AddNewItemForm.dart';
import 'EditItemForm.dart';
import 'ViewItemPage.dart';

class ManageItemsPage extends StatefulWidget {
  const ManageItemsPage({super.key});

  @override
  _ManageItemsPageState createState() => _ManageItemsPageState();
}

class _ManageItemsPageState extends State<ManageItemsPage> {
  final ItemService itemService = ItemService(dotenv.env['BASE_URL']!);
  List<Item> _items = [];
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
      await _fetchItems();
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _fetchItems() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      List<Item> items = await itemService.fetchItems(_currentPage, _itemsPerPage);
      if (!mounted) return;
      
      setState(() {
        _items = items;
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
        return AddNewItemForm(
          itemService: itemService,
          onItemAdded: _fetchItems,
        );
      },
    );
  }

  void _openEditItemDialog(Item item) {
    showDialog(
      context: context,
      builder: (context) {
        return EditItemForm(
          itemService: itemService,
          item: item,
          onItemUpdated: _fetchItems,
        );
      },
    );
  }

  Future<void> _confirmDeleteItem(Item item) async {
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
        await itemService.deleteItem(item.id.toString());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Item "${item.item}" deleted successfully!')),
        );
        _fetchItems();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Failed to delete item. Please try again.')),
        );
      }
    }
  }

void _viewItemDetails(Item item) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 400,
              minWidth: 300,
            ),
            child: ViewItemPage(item: item),
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
            onPressed: _fetchItems,
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
        rows: _items.map((item) {
          return DataRow(
            color: WidgetStateProperty.resolveWith<Color?>(
              (Set<WidgetState> states) {
                return _items.indexOf(item) % 2 == 0
                    ? const Color.fromARGB(255, 61, 61, 61)
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
        title: const Text('Manage Items'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchItems,
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
                if (!_isLoading && !_hasError && _items.isNotEmpty) ...[
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
                                  _fetchItems();
                                });
                              }
                            : null,
                        child: const Text('Previous'),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: _items.length == _itemsPerPage
                            ? () {
                                setState(() {
                                  _currentPage++;
                                  _fetchItems();
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
                if (!_isLoading && !_hasError && _items.isEmpty)
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