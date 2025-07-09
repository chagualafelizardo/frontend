import 'package:flutter/material.dart';
import 'package:app/models/Oficina.dart';
import 'package:app/services/OficinaService.dart';

class EditOficinaForm extends StatefulWidget {
  final OficinaService oficinaService;
  final Oficina oficina;
  final Function onOficinaUpdated;

  const EditOficinaForm({
    super.key,
    required this.oficinaService,
    required this.oficina,
    required this.onOficinaUpdated,
  });

  @override
  _EditOficinaFormState createState() => _EditOficinaFormState();
}

class _EditOficinaFormState extends State<EditOficinaForm> {
  final _formKey = GlobalKey<FormState>();
  late String _nomeOficina;
  late String _endereco;
  late String _telefone;
  late String _obs;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nomeOficina = widget.oficina.nomeOficina;
    _endereco = widget.oficina.endereco;
    _telefone = widget.oficina.telefone.toString();
    _obs = widget.oficina.obs;
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      _formKey.currentState!.save();
      
      Oficina updatedOficina = Oficina(
        id: widget.oficina.id,
        nomeOficina: _nomeOficina,
        endereco: _endereco,
        telefone: int.parse(_telefone),
        obs: _obs,
      );

      await widget.oficinaService.updateOficina(updatedOficina);

      if (!mounted) return;
      widget.onOficinaUpdated();
      Navigator.of(context).pop();

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update workshop: ${e.toString()}'),
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
          title: const Text('Edit Workshop'),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextFormField(
                    initialValue: _nomeOficina,
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
                    initialValue: _endereco,
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
                    initialValue: _telefone,
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
                    onSaved: (value) => _telefone = value!,
                  ),
                  TextFormField(
                    initialValue: _obs,
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
              child: const Text('Update'),
            ),
          ],
        ),
        if (_isSubmitting)
          const Center(child: CircularProgressIndicator()),
      ],
    );
  }
}