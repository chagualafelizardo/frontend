import 'package:flutter/material.dart';
import 'package:app/services/ItensEntregaService.dart';
import 'package:app/models/ItensEntrega.dart';

class EditItensEntregaForm extends StatefulWidget {
  final ItensEntregaService itensEntregaService;
  final ItensEntrega item;
  final VoidCallback onItemUpdated;

  const EditItensEntregaForm({
    super.key,
    required this.itensEntregaService,
    required this.item,
    required this.onItemUpdated,
  });

  @override
  State<EditItensEntregaForm> createState() => _EditItensEntregaFormState();
}

class _EditItensEntregaFormState extends State<EditItensEntregaForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _itemController;
  late TextEditingController _obsController;

  @override
  void initState() {
    super.initState();
    _itemController = TextEditingController(text: widget.item.item);
    _obsController = TextEditingController(text: widget.item.obs);
  }

  Future<void> _updateItem() async {
    if (_formKey.currentState!.validate()) {
      try {
        await widget.itensEntregaService.updateItensEntrega(widget.item.id!, {
          'item': _itemController.text,
          'obs': _obsController.text,
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item updated successfully!')),
        );
        widget.onItemUpdated();
        Navigator.of(context).pop();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update item.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Item'),
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
          onPressed: _updateItem,
          child: const Text('Update'),
        ),
      ],
    );
  }
}
