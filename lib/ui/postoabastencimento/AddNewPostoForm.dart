import 'package:flutter/material.dart';
import 'package:app/models/Posto.dart';
import 'package:app/services/PostoService.dart';

class AddNewPostoForm extends StatefulWidget {
  final PostoService postoService;
  final VoidCallback onPostoAdded;

  const AddNewPostoForm({
    Key? key,
    required this.postoService,
    required this.onPostoAdded,
  }) : super(key: key);

  @override
  _AddNewPostoFormState createState() => _AddNewPostoFormState();
}

class _AddNewPostoFormState extends State<AddNewPostoForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _enderecoController = TextEditingController();
  final TextEditingController _telefoneController = TextEditingController();
  final TextEditingController _obsController = TextEditingController();
  bool _isLoading = false;

  Future<void> _addPosto() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);

      final newPosto = Posto(
        id: 0,
        nomePosto: _nomeController.text.trim(),
        endereco: _enderecoController.text.trim(),
        telefone: int.tryParse(_telefoneController.text.trim()) ?? 0,
        obs: _obsController.text.trim(),
      );

      try {
        await widget.postoService.addPosto(newPosto);
        
        if (!mounted) return;
        
        // Primeiro fecha o diálogo
        Navigator.of(context).pop();
        
        // Depois chama o callback
        widget.onPostoAdded();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New Posto'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(labelText: 'Nome Posto'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _enderecoController,
                decoration: const InputDecoration(labelText: 'Endereço'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the address';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _telefoneController,
                decoration: const InputDecoration(labelText: 'Telefone'),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the phone number';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _obsController,
                decoration: const InputDecoration(labelText: 'Observações'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _addPosto,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Add'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _enderecoController.dispose();
    _telefoneController.dispose();
    _obsController.dispose();
    super.dispose();
  }
}