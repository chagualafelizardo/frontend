import 'dart:typed_data';
import 'dart:convert';
import 'package:app/models/UserRenderImgBase64.dart';
import 'package:app/models/UserRole.dart';
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
  print('[DEBUG] _saveUser() iniciado');
  
  if (_formKey.currentState?.validate() ?? false) {
    print('[DEBUG] Validação do formulário OK');
    
    // Verifica se as senhas coincidem
    if (_passwordController.text != _confirmPasswordController.text) {
      print('[DEBUG] Erro: Senhas não coincidem');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    print('[DEBUG] Criando objeto updatedUser');
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
      password:_passwordController.text,
      state: _state,
      gender: _gender,
      imgBase64: _imageBytes != null
          ? base64Encode(_imageBytes!)
          : widget.user.imgBase64,
      birthdate: _selectedBirthdate ?? DateTime.now(),
    );

    print('[DEBUG] updatedUser criado: ${updatedUser}');

    try {
      print('[DEBUG] Chamando updateUser()');
      // Atualiza o usuário
      await widget.userService.updateUser(widget.user.id, updatedUser);
      print('[DEBUG] Usuário atualizado com sucesso');

      // Atualiza as roles do usuário
      UserRoleService userRoleService = UserRoleService(dotenv.env['BASE_URL']!);
      List<Role> selectedRoles = roles.where((r) => r.selected == true).toList();
      print('[DEBUG] Roles selecionadas: ${selectedRoles.map((r) => r.id).toList()}');

      print('[DEBUG] Removendo todas as roles atuais');
      // Remove todas as roles atuais do usuário
      bool removed = await userRoleService.removeAllRolesFromUser(widget.user.id);
      if (!removed) {
        print('[WARNING] Não foi possível remover todas as roles');
      } else {
        print('[DEBUG] Todas as roles removidas com sucesso');
      }

      // Atribui as novas roles selecionadas
      print('[DEBUG] Atribuindo novas roles');
      for (var role in selectedRoles) {
        print('[DEBUG] Atribuindo role: ${role.id}');
        UserRole? result = await userRoleService.assignRoleToUser(widget.user.id, role.id);
        if (result == null) {
          print('[WARNING] Falha ao atribuir role: ${role.id}');
        } else {
          print('[DEBUG] Role ${role.id} atribuída com sucesso');
        }
      }

      // Notifica que o usuário foi atualizado
      print('[DEBUG] Operação concluída com sucesso');
      widget.onUserUpdated();
      Navigator.of(context).pop();
    } catch (error) {
      print('[ERROR] Erro ao atualizar usuário: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update user: $error')),
      );
    }
  } else {
    print('[DEBUG] Validação do formulário falhou');
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
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: const Text('Save'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            backgroundColor: Colors.grey[300],
            foregroundColor: Colors.black87,
          ),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  Widget _buildUserDataForm() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: _imageBytes != null
                        ? MemoryImage(_imageBytes!)
                        : null,
                    child: _imageBytes == null
                        ? const Icon(Icons.camera_alt, size: 40, color: Colors.grey)
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildStyledTextField(
                controller: _usernameController,
                labelText: 'Username',
                icon: Icons.person,
              ),
              const SizedBox(height: 16),
              _buildStyledTextField(
                controller: _firstNameController,
                labelText: 'First Name',
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 16),
              _buildStyledTextField(
                controller: _lastNameController,
                labelText: 'Last Name',
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 16),
              const Text(
                "Gender",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildGenderRadio('M', 'Male'),
                  const SizedBox(width: 20),
                  _buildGenderRadio('F', 'Female'),
                ],
              ),
              const SizedBox(height: 16),
              _buildStyledTextField(
                controller: _birthdateController,
                labelText: 'Birthdate',
                icon: Icons.calendar_today,
                readOnly: true,
                onTap: _pickBirthdate,
              ),
              const SizedBox(height: 16),
              _buildStyledTextField(
                controller: _emailController,
                labelText: 'Email',
                icon: Icons.email,
              ),
              const SizedBox(height: 16),
              _buildStyledTextField(
                controller: _addressController,
                labelText: 'Address',
                icon: Icons.location_on,
              ),
              const SizedBox(height: 16),
              _buildStyledTextField(
                controller: _neighborhoodController,
                labelText: 'Neighborhood',
                icon: Icons.location_city,
              ),
              const SizedBox(height: 16),
              _buildStyledTextField(
                controller: _phone1Controller,
                labelText: 'Phone 1',
                icon: Icons.phone,
              ),
              const SizedBox(height: 16),
              _buildStyledTextField(
                controller: _phone2Controller,
                labelText: 'Phone 2',
                icon: Icons.phone,
              ),
              const SizedBox(height: 16),
              _buildStyledTextField(
                controller: _passwordController,
                labelText: 'Password',
                icon: Icons.lock,
                obscureText: true,
              ),
              const SizedBox(height: 16),
              _buildStyledTextField(
                controller: _confirmPasswordController,
                labelText: 'Confirm Password',
                icon: Icons.lock,
                obscureText: true,
              ),
              const SizedBox(height: 16),
              _buildStyledDropdown(
                value: _state,
                items: ['active', 'inactive'],
                labelText: 'State',
                icon: Icons.flag,
                onChanged: (value) {
                  setState(() {
                    _state = value!;
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStyledTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    bool readOnly = false,
    bool obscureText = false,
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: const TextStyle(color: Colors.black87),
          prefixIcon: Icon(icon, color: Colors.black54),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        style: const TextStyle(color: Colors.black87), // Cor do texto digitado
        readOnly: readOnly,
        obscureText: obscureText,
        onTap: onTap,
      ),
    );
  }

  Widget _buildStyledDropdown({
    required String value,
    required List<String> items,
    required String labelText,
    required IconData icon,
    required Function(String?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        items: items
            .map((item) => DropdownMenuItem(value: item, child: Text(item, style: const TextStyle(color: Colors.black87))))
            .toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: const TextStyle(color: Colors.black87),
          prefixIcon: Icon(icon, color: Colors.black54),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        style: const TextStyle(color: Colors.black87), // Cor do texto selecionado
      ),
    );
  }

  Widget _buildGenderRadio(String value, String label) {
    return Row(
      children: [
        Radio<String>(
          value: value,
          groupValue: _gender,
          onChanged: (value) {
            setState(() {
              _gender = value!;
            });
          },
        ),
        Text(label, style: const TextStyle(color: Colors.black87)),
      ],
    );
  }

  Widget _buildRolesList() {
    if (_loadingRoles) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      itemCount: roles.length,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: CheckboxListTile(
            title: Text(roles[index].name ?? 'Role ${index + 1}', style: const TextStyle(color: Color.fromARGB(221, 250, 249, 249))),
            value: roles[index].selected ?? false,
            onChanged: (bool? newValue) {
              setState(() {
                roles[index].selected = newValue!;
              });
            },
          ),
        );
      },
    );
  }
}