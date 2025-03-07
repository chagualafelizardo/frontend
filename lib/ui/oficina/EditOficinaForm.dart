import 'package:flutter/material.dart';
import 'package:app/models/Oficina.dart';
import 'package:app/services/OficinaService.dart';

class EditOficinaForm extends StatefulWidget {
  final OficinaService oficinaService;
  final Oficina oficina;
  final Function onOficinaUpdated;

  const EditOficinaForm({super.key, 
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

  @override
  void initState() {
    super.initState();
    _nomeOficina = widget.oficina.nomeOficina;
    _endereco = widget.oficina.endereco;
    _telefone = widget.oficina.telefone.toString(); // Converte int para String
    _obs = widget.oficina.obs;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
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
                onSaved: (value) {
                  _nomeOficina = value!;
                },
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
                onSaved: (value) {
                  _endereco = value!;
                },
              ),
              TextFormField(
                initialValue: _telefone,
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
                  _telefone = value!;
                },
              ),
              TextFormField(
                initialValue: _obs,
                decoration: const InputDecoration(labelText: 'Notes'),
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
              Oficina updatedOficina = Oficina(
                id: widget.oficina.id,
                nomeOficina: _nomeOficina,
                endereco: _endereco,
                telefone: int.parse(_telefone), // Converte String para int
                obs: _obs,
              );
              widget.oficinaService.updateOficina(updatedOficina).then((_) {
                widget.onOficinaUpdated();
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
