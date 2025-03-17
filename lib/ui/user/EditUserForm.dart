import 'dart:typed_data';
import 'dart:convert';
import 'package:app/models/UserRenderImgBase64.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:app/models/User.dart';
import 'package:app/services/UserService.dart';
import 'package:app/services/RoleService.dart';
import 'package:app/models/Role.dart';
import 'package:app/services/UserRoleService.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class EditUserForm extends StatefulWidget {
  final UserService userService;
  final UserBase64 user;
  final VoidCallback onUserUpdated;

  const EditUserForm({
    Key? key,
    required this.userService,
    required this.user,
    required this.onUserUpdated,
  }) : super(key: key);

  @override
  _EditUserFormState createState() => _EditUserFormState();
}

class _EditUserFormState extends State<EditUserForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _neighborhoodController = TextEditingController();
  final TextEditingController _phone1Controller = TextEditingController();
  final TextEditingController _phone2Controller = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _birthdateController = TextEditingController();

  Uint8List? _imageBytes;
  String _state = 'active';
  String _gender = 'male';
  DateTime? _selectedBirthdate;

  List<Role> roles = [];
  bool _loadingRoles = true;

  @override
  void initState() {
    super.initState();
    _initializeUserFields();
    _loadRoles();
  }

  void _initializeUserFields() {
    _usernameController.text = widget.user.username ?? '';
    _firstNameController.text = widget.user.firstName ?? '';
    _lastNameController.text = widget.user.lastName ?? '';
    _emailController.text = widget.user.email ?? '';
    _addressController.text = widget.user.address ?? '';
    _neighborhoodController.text = widget.user.neighborhood ?? '';
    _phone1Controller.text = widget.user.phone1 ?? '';
    _phone2Controller.text = widget.user.phone2 ?? '';
    _state = widget.user.state ?? 'active';
    _gender = widget.user.gender ?? 'male';
    _selectedBirthdate = widget.user.birthdate;
    _birthdateController.text = DateFormat('yyyy-MM-dd').format(widget.user.birthdate);

    if (widget.user.imgBase64 != null) {
      _imageBytes = base64Decode(widget.user.imgBase64!);
    }
  }

  Future<void> _loadRoles() async {
    try {
      RoleService roleService = RoleService(dotenv.env['BASE_URL']!);
      List<Role> loadedRoles = await roleService.getRoles();
      print('Roles carregadas: ${loadedRoles.length}');

      // Carrega as roles do usuário a partir do campo `roles`
      List<Role> userRoles = widget.user.roles ?? [];
      print('Roles do usuário: ${userRoles.length}');

      setState(() {
        roles = loadedRoles.map((role) {
          // Marca como selecionada apenas se o usuário tiver essa role
          role.selected = userRoles.any((userRole) => userRole.id == role.id);
          return role;
        }).toList();
        _loadingRoles = false;
      });
    } catch (e) {
      print('Erro ao carregar roles: $e');
      setState(() {
        _loadingRoles = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load roles.')),
      );
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final imageBytes = await image.readAsBytes();
      setState(() {
        _imageBytes = imageBytes;
      });
    }
  }

  Future<void> _pickBirthdate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthdate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedBirthdate) {
      setState(() {
        _selectedBirthdate = picked;
        _birthdateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _saveUser() async {
    if (_formKey.currentState?.validate() ?? false) {
      // Verifica se as senhas coincidem
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Passwords do not match')),
        );
        return;
      }

      final updatedUser = UserBase64(
        id: widget.user.id,
        username: _usernameController.text,
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        email: _emailController.text,
        address: _addressController.text,
        neighborhood: _neighborhoodController.text,
        phone1: _phone1Controller.text,
        phone2: _phone2Controller.text,
        state: _state,
        gender: _gender,
        imgBase64: _imageBytes != null
            ? base64Encode(_imageBytes!)
            : widget.user.imgBase64,
        birthdate: _selectedBirthdate ?? DateTime.now(),
      );

      try {
        // Atualiza o usuário
        await widget.userService.updateUser(widget.user.id as User, updatedUser);

        // Atualiza as roles do usuário
        UserRoleService userRoleService = UserRoleService(dotenv.env['BASE_URL']!);
        List<Role> selectedRoles = roles.where((r) => r.selected == true).toList();

        // Remove todas as roles atuais do usuário
        await userRoleService.removeAllRolesFromUser(widget.user.id);

        // Atribui as novas roles selecionadas
        for (var role in selectedRoles) {
          await userRoleService.assignRoleToUser(widget.user.id, role.id!);
        }

        // Notifica que o usuário foi atualizado
        widget.onUserUpdated();
        Navigator.of(context).pop();
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update user: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit User'),
      content: SizedBox(
        width: 600,
        height: 800,
        child: DefaultTabController(
          length: 2,
          child: Column(
            children: [
              const TabBar(
                tabs: [
                  Tab(text: 'User Data'),
                  Tab(text: 'Roles'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildUserDataForm(),
                    _buildRolesList(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: _saveUser,
          child: const Text('Save'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  Widget _buildUserDataForm() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: ClipOval(
                    child: Container(
                      width: 100,
                      height: 100,
                      color: Colors.grey[300],
                      child: _imageBytes == null
                          ? const Center(child: Text('Select Image'))
                          : Image.memory(
                              _imageBytes!,
                              fit: BoxFit.cover,
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Username'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a username';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(labelText: 'First Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a first name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(labelText: 'Last Name'),
              ),
              const SizedBox(height: 20),
              const Text("Gender", style: TextStyle(fontSize: 16)),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Radio<String>(
                    value: 'M',
                    groupValue: _gender,
                    onChanged: (value) {
                      setState(() {
                        _gender = value!;
                      });
                    },
                  ),
                  const Text("Male"),
                  Radio<String>(
                    value: 'F',
                    groupValue: _gender,
                    onChanged: (value) {
                      setState(() {
                        _gender = value!;
                      });
                    },
                  ),
                  const Text("Female"),
                ],
              ),
              TextFormField(
                controller: _birthdateController,
                readOnly: true,
                onTap: _pickBirthdate,
                decoration: const InputDecoration(labelText: 'Birthdate'),
              ),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Address'),
              ),
              TextFormField(
                controller: _neighborhoodController,
                decoration: const InputDecoration(labelText: 'Neighborhood'),
              ),
              TextFormField(
                controller: _phone1Controller,
                decoration: const InputDecoration(labelText: 'Phone 1'),
              ),
              TextFormField(
                controller: _phone2Controller,
                decoration: const InputDecoration(labelText: 'Phone 2'),
              ),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              TextFormField(
                controller: _confirmPasswordController,
                decoration: const InputDecoration(labelText: 'Confirm Password'),
                obscureText: true,
              ),
              DropdownButtonFormField<String>(
                value: _state,
                items: ['active', 'inactive']
                    .map((state) =>
                        DropdownMenuItem(value: state, child: Text(state)))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _state = value!;
                  });
                },
                decoration: const InputDecoration(labelText: 'State'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRolesList() {
    if (_loadingRoles) {
      return const Center(child: CircularProgressIndicator());
    }

    print('Roles para renderizar: ${roles.length}'); // Log para depuração

    return ListView.builder(
      itemCount: roles.length,
      itemBuilder: (context, index) {
        final Color tileColor = index % 2 == 0
            ? const Color.fromARGB(255, 14, 13, 13) // Cor clara para linhas pares
            : const Color.fromARGB(255, 53, 51, 51); // Cor branca para linhas ímpares

        return Container(
          color: tileColor,
          child: CheckboxListTile(
            title: Text(roles[index].name ?? 'Role ${index + 1}'),
            value: roles[index].selected ?? false,
            onChanged: (bool? newValue) {
              setState(() {
                roles[index].selected = newValue;
              });
            },
          ),
        );
      },
    );
  }
}