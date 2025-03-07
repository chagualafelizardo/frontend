import 'package:flutter/material.dart';
import 'package:app/models/Item.dart';
import 'package:app/services/ItemService.dart';

class EditItemForm extends StatefulWidget {
  final ItemService itemService;
  final Item item;
  final Function onItemUpdated;

  const EditItemForm({super.key, 
    required this.itemService,
    required this.item,
    required this.onItemUpdated,
  });

  @override
  _EditItemFormState createState() => _EditItemFormState();
}

class _EditItemFormState extends State<EditItemForm> {
  final _formKey = GlobalKey<FormState>();
  late String _itemName;
  String? _itemNotes;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _itemName = widget.item.item ?? '';
    _itemNotes = widget.item.obs;
  }

  Future<void> _editItem() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    _formKey.currentState!.save();

    setState(() {
      _isLoading = true;
    });

    try {
      Item updatedItem = Item(
        id: widget.item.id,
        item: _itemName,
        obs: _itemNotes,
      );

      await widget.itemService.updateItem(updatedItem);
      widget.onItemUpdated();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Item "${updatedItem.item}" updated successfully!')),
      );

      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update item. Please try again.')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Edit Item',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _itemName,
                decoration: const InputDecoration(labelText: 'Item Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an item name.';
                  }
                  return null;
                },
                onSaved: (value) {
                  _itemName = value ?? '';
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _itemNotes,
                decoration: const InputDecoration(labelText: 'Notes (Optional)'),
                onSaved: (value) {
                  _itemNotes = value;
                },
              ),
              const SizedBox(height: 16),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _editItem,
                      child: const Text('Update Item'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
