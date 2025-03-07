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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New Workshop'),
      content: Form(
        key: _formKey,
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
              onSaved: (value) {
                _nomeOficina = value!;
              },
            ),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Address'),
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
              decoration: const InputDecoration(labelText: 'Phone'),
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
                _telefone = int.parse(value!);
              },
            ),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Notes'),
              onSaved: (value) {
                _obs = value ?? '';
              },
            ),
          ],
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
              Oficina newOficina = Oficina(
                id: 0, // Placeholder, should be replaced with actual ID after creation
                nomeOficina: _nomeOficina,
                endereco: _endereco,
                telefone: _telefone,
                obs: _obs,
              );
              widget.oficinaService.createOficina(newOficina).then((_) {
                widget.onOficinaAdded();
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
