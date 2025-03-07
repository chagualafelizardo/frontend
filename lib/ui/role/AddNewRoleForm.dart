import 'package:flutter/material.dart';
import 'package:app/models/Role.dart';
import 'package:app/services/RoleService.dart';

class AddNewRoleForm extends StatefulWidget {
  final RoleService roleService;
  final VoidCallback onRoleAdded;

  const AddNewRoleForm({super.key, required this.roleService, required this.onRoleAdded});

  @override
  _AddNewRoleFormState createState() => _AddNewRoleFormState();
}

class _AddNewRoleFormState extends State<AddNewRoleForm> {
  final TextEditingController _nameController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  Future<void> _addRole() async {
    if (_formKey.currentState!.validate()) {
      Role? newRole = await widget.roleService.addRole(_nameController.text);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Role "${newRole?.name}" added successfully!')),
      );
      widget.onRoleAdded();
      Navigator.of(context).pop(); // Close the dialog
        }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      width: 400, // Defina a largura desejada aqui
      height:
          350, // Defina a altura desejada aqui (aumentada para incluir o título)
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Barra de título
          const Text(
            'Add New Role',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20), // Espaço entre o título e o formulário
          // Formulário
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Role Name'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a name.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _addRole,
                  child: const Text('Add Role'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
