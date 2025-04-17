import 'package:flutter/material.dart';
import 'package:app/models/Role.dart';
import 'package:app/services/RoleService.dart';

class EditRoleForm extends StatefulWidget {
  final RoleService roleService;
  final Role role;
  final VoidCallback onRoleUpdated;

  const EditRoleForm(
      {super.key, required this.roleService,
      required this.role,
      required this.onRoleUpdated});

  @override
  _EditRoleFormState createState() => _EditRoleFormState();
}

class _EditRoleFormState extends State<EditRoleForm> {
  late TextEditingController _nameController;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.role.name);
  }

  Future<void> _updateRole() async {
    if (_formKey.currentState!.validate()) {
      Role? updatedRole = await widget.roleService
          .updateRole(widget.role.id, _nameController.text);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Role "${updatedRole?.name}" updated successfully!')),
      );
      widget.onRoleUpdated();
      Navigator.of(context).pop(); // Close the dialog
        }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      width: 400, // Defina a largura desejada aqui
      height: 300, // Defina a altura desejada aqui
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
              onPressed: _updateRole,
              child: const Text('Update Role'),
            ),
          ],
        ),
      ),
    );
  }
}
