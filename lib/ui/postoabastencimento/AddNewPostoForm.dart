import 'package:flutter/material.dart';
import 'package:app/models/Posto.dart';
import 'package:app/services/PostoService.dart';

class AddNewPostoForm extends StatefulWidget {
  final PostoService postoService;
  final Function onPostoAdded;

  const AddNewPostoForm({super.key, 
    required this.postoService,
    required this.onPostoAdded,
  });

  @override
  _AddNewPostoFormState createState() => _AddNewPostoFormState();
}

class _AddNewPostoFormState extends State<AddNewPostoForm> {
  final _formKey = GlobalKey<FormState>();
  String _nomePosto = '';
  String _endereco = '';
  String _telefone = '';
  String _obs = '';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New Posto'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextFormField(
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
              Posto newPosto = Posto(
                id: 0,
                nomePosto: _nomePosto,
                endereco: _endereco,
                telefone: int.parse(_telefone),
                obs: _obs,
              );
              widget.postoService.addPosto(newPosto).then((_) {
                widget.onPostoAdded();
                Navigator.of(context).pop();
              });
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
