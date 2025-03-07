import 'package:flutter/material.dart';
import 'package:app/services/ItensEntregaService.dart';

class AddNewItensEntregaForm extends StatefulWidget {
  final ItensEntregaService itensEntregaService;
  final VoidCallback onItemAdded;

  const AddNewItensEntregaForm({
    super.key,
    required this.itensEntregaService,
    required this.onItemAdded,
  });

  @override
  State<AddNewItensEntregaForm> createState() => _AddNewItensEntregaFormState();
}

class _AddNewItensEntregaFormState extends State<AddNewItensEntregaForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _itemController = TextEditingController();
  final TextEditingController _obsController = TextEditingController();

 Future<void> _addItem() async {
  if (_formKey.currentState!.validate()) {
    try {
      await widget.itensEntregaService.createItensEntrega(
        _itemController.text,
        _obsController.text.isNotEmpty ? _obsController.text : null,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item added successfully!')),
      );
      widget.onItemAdded();
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to add item.')),
      );
    }
  }
}


  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New Item'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _itemController,
              decoration: const InputDecoration(labelText: 'Item Name'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an item name.';
                }
                return null;
              },
            ),
            TextFormField(
              controller: _obsController,
              decoration: const InputDecoration(labelText: 'Notes'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _addItem,
          child: const Text('Add'),
        ),
      ],
    );
  }
}
