import 'package:flutter/material.dart';
import 'package:app/services/ItemService.dart';
import 'package:app/models/Item.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'AddNewItemForm.dart';
import 'EditItemForm.dart';
import 'ViewItemPage.dart'; // Certifique-se de importar o ViewItemPage

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

  @override
  void initState() {
    super.initState();
    _fetchItems();
  }

  Future<void> _fetchItems() async {
    try {
      List<Item> items =
          await itemService.fetchItems(_currentPage, _itemsPerPage);
      setState(() {
        _items = items;
      });
    } catch (e) {
      print('Error fetching items: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to fetch items.')),
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
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ViewItemPage(item: item),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Items'),
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
                  rows: _items.asMap().entries.map((entry) {
                    int index = entry.key;
                    Item item = entry.value;
                    return DataRow(
                      color: WidgetStateProperty.resolveWith<Color?>(
                          (Set<WidgetState> states) {
                            return index % 2 == 0
                                ? const Color.fromARGB(255, 61, 61, 61) // cor para as linhas pares (mais escuras)
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
                            _fetchItems();
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
                      _fetchItems();
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
