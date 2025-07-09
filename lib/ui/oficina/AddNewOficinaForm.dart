import 'package:flutter/material.dart';
import 'package:app/models/Oficina.dart';
import 'package:app/services/OficinaService.dart';

class AddNewOficinaForm extends StatefulWidget {
  final OficinaService oficinaService;
  final Function onOficinaAdded;

  const AddNewOficinaForm(
      {super.key, required this.oficinaService, required this.onOficinaAdded});

  @override
  _AddNewOficinaFormState createState() => _AddNewOficinaFormState();
}

class _AddNewOficinaFormState extends State<AddNewOficinaForm> {
  final _formKey = GlobalKey<FormState>();
  String _nomeOficina = '';
  String _endereco = '';
  int _telefone = 0;
  String _obs = '';
  bool _isSubmitting = false;

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSubmitting = true);
    
    try {
      _formKey.currentState!.save();
      Oficina newOficina = Oficina(
        id: 0,
        nomeOficina: _nomeOficina,
        endereco: _endereco,
        telefone: _telefone,
        obs: _obs,
      );
      
      await widget.oficinaService.createOficina(newOficina);
      
      if (!mounted) return;
      widget.onOficinaAdded();
      Navigator.of(context).pop();
      
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add workshop: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AlertDialog(
          title: const Text('Add New Workshop'),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Name'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the name';
                      }
                      return null;
                    },
                    onSaved: (value) => _nomeOficina = value!,
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Address'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the address';
                      }
                      return null;
                    },
                    onSaved: (value) => _endereco = value!,
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Phone'),
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
                    onSaved: (value) => _telefone = int.parse(value!),
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Notes'),
                    maxLines: 3,
                    onSaved: (value) => _obs = value ?? '',
                  ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: _isSubmitting ? null : _submitForm,
              child: const Text('Add'),
            ),
          ],
        ),
        if (_isSubmitting)
          const Center(child: CircularProgressIndicator()),
      ],
    );
  }
}