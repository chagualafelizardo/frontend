import 'package:flutter/material.dart';
import 'package:app/models/Item.dart';
import 'package:app/services/ItemService.dart';

class AddNewItemForm extends StatefulWidget {
  final ItemService itemService;
  final Function onItemAdded;

  const AddNewItemForm({super.key, required this.itemService, required this.onItemAdded});

  @override
  _AddNewItemFormState createState() => _AddNewItemFormState();
}

class _AddNewItemFormState extends State<AddNewItemForm> {
  final _formKey = GlobalKey<FormState>();
  String _itemName = '';
  String? _itemNotes;
  bool? selected;

  bool _isLoading = false;

  Future<void> _addItem() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    _formKey.currentState!.save();

    setState(() {
      _isLoading = true;
    });

    try {
      Item newItem = Item(
        // Remover a linha do 'id', se ele não for necessário aqui
        item: _itemName,
        obs: _itemNotes,
        selected: false,
      );

      await widget.itemService.addItem(newItem);
      widget.onItemAdded();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Item "${newItem.item}" added successfully!')),
      );

      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to add item. Please try again.')),
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
                'Add New Item',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
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
                decoration: const InputDecoration(labelText: 'Notes (Optional)'),
                onSaved: (value) {
                  _itemNotes = value;
                },
              ),
              const SizedBox(height: 16),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _addItem,
                      child: const Text('Add Item'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
