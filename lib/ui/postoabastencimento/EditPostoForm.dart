import 'package:flutter/material.dart';
import 'package:app/models/Posto.dart';
import 'package:app/services/PostoService.dart';

class EditPostoForm extends StatefulWidget {
  final PostoService postoService;
  final Posto posto;
  final Function onPostoUpdated;

  const EditPostoForm({super.key, 
    required this.postoService,
    required this.posto,
    required this.onPostoUpdated,
  });

  @override
  _EditPostoFormState createState() => _EditPostoFormState();
}

class _EditPostoFormState extends State<EditPostoForm> {
  final _formKey = GlobalKey<FormState>();
  late String _nomePosto;
  late String _endereco;
  late String _telefone;
  late String _obs;

  @override
  void initState() {
    super.initState();
    _nomePosto = widget.posto.nomePosto;
    _endereco = widget.posto.endereco;
    _telefone = widget.posto.telefone.toString();
    _obs = widget.posto.obs;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Posto'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextFormField(
                initialValue: _nomePosto,
                decoration: const InputDecoration(labelText: 'Nome Posto'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the name';
                  }
                  return null;
                },
                onSaved: (value) {
                  _nomePosto = value!;
                },
              ),
              TextFormField(
                initialValue: _endereco,
                decoration: const InputDecoration(labelText: 'Endereço'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the address';
                  }
                  return null;
                },
                onSaved: (value) {
                  _endereco = value!;
                },
              ),
              TextFormField(
                initialValue: _telefone,
                decoration: const InputDecoration(labelText: 'Telefone'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the phone number';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
                onSaved: (value) {
                  _telefone = value!;
                },
              ),
              TextFormField(
                initialValue: _obs,
                decoration: const InputDecoration(labelText: 'Observações'),
                onSaved: (value) {
                  _obs = value ?? '';
                },
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              _formKey.currentState!.save();
              Posto updatedPosto = Posto(
                id: widget.posto.id,
                nomePosto: _nomePosto,
                endereco: _endereco,
                telefone: int.parse(_telefone),
                obs: _obs,
              );
              widget.postoService.updatePosto(updatedPosto).then((_) {
                widget.onPostoUpdated();
                Navigator.of(context).pop();
              });
            }
          },
          child: const Text('Update'),
        ),
      ],
    );
  }
}
