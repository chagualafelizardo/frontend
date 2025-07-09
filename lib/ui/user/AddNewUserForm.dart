import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:app/models/User.dart';
import 'package:app/services/UserService.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'dart:convert';
import 'package:app/services/RoleService.dart';
import 'package:app/models/Role.dart';
import 'package:app/services/UserRoleService.dart';

class AddNewUserForm extends StatefulWidget {
  final UserService userService;
  final VoidCallback onUserAdded;
  final User? user;

  const AddNewUserForm({
    super.key,
    required this.userService,
    required this.onUserAdded,
    this.user,
  });

  @override
  _AddNewUserFormState createState() => _AddNewUserFormState();
}

class _AddNewUserFormState extends State<AddNewUserForm> {
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
  DateTime? _selectedBirthdate;
  Uint8List? _imageBytes;
  String _state = 'active';
  String _gender = 'male';
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  List<Role> roles = [];
  bool _loadingRoles = true;

  @override
  void initState() {
    super.initState();
    _loadRoles();

    if (widget.user != null) {
      _initializeUserFields();
    }
  }

  void _initializeUserFields() {
    _usernameController.text = widget.user!.username ?? '';
    _firstNameController.text = widget.user!.firstName ?? '';
    _lastNameController.text = widget.user!.lastName ?? '';
    _emailController.text = widget.user!.email ?? '';
    _addressController.text = widget.user!.address ?? '';
    _neighborhoodController.text = widget.user!.neighborhood ?? '';
    _phone1Controller.text = widget.user!.phone1 ?? '';
    _phone2Controller.text = widget.user!.phone2 ?? '';
    _state = widget.user!.state ?? 'inactive';
    _gender = widget.user!.gender ?? 'male';
    _selectedBirthdate = widget.user!.birthdate != null
        ? DateTime.parse(widget.user!.birthdate)
        : null;
    _birthdateController.text = _selectedBirthdate != null
        ? _selectedBirthdate!.toLocal().toString().split(' ')[0]
        : '';
    _imageBytes = widget.user!.img != null
        ? Uint8List.fromList(base64Decode(widget.user!.img!))
        : null;
  }

  Future<void> _loadRoles() async {
    try {
      RoleService roleService = RoleService(dotenv.env['BASE_URL']!);
      List<Role> loadedRoles = await roleService.getRoles();
      setState(() {
        roles = loadedRoles;
        for (var role in roles) {
          role.selected ??= false;
        }
        _loadingRoles = false;
      });
    } catch (e) {
      setState(() {
        _loadingRoles = false;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Failed to load roles.')));
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final imageBytes = await image.readAsBytes();
      final compressedImageBytes = _compressImage(imageBytes);
      setState(() {
        _imageBytes = compressedImageBytes;
      });
    }
  }

  Uint8List _compressImage(Uint8List imageBytes) {
    final img.Image? image = img.decodeImage(imageBytes);
    if (image != null) {
      final img.Image resizedImage =
          img.copyResize(image, width: 600, height: 400);
      return Uint8List.fromList(img.encodeJpg(resizedImage, quality: 80));
    }
    return imageBytes;
  }

  Future<void> _selectBirthdate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedBirthdate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null && pickedDate != _selectedBirthdate) {
      setState(() {
        _selectedBirthdate = pickedDate;
        _birthdateController.text =
            _selectedBirthdate!.toLocal().toString().split(' ')[0];
      });
    }
  }

  // Método _addUser atualizado
  Future<void> _addUser() async {
    // Validar formulário
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validar senha se for novo usuário
    if (widget.user == null && _passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Mostrar diálogo de confirmação
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.user == null ? 'Add New User' : 'Update User'),
        content: Text(widget.user == null 
            ? 'Are you sure you want to add this new user?'
            : 'Are you sure you want to update this user?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Mostrar indicador de carregamento
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      String? imageBase64;
      if (_imageBytes != null) {
        imageBase64 = base64Encode(_imageBytes!);
      }

      User newUser = User(
        id: widget.user?.id ?? 0,
        username: _usernameController.text,
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        email: _emailController.text,
        address: _addressController.text,
        neighborhood: _neighborhoodController.text,
        phone1: _phone1Controller.text,
        phone2: _phone2Controller.text,
        password: _passwordController.text,
        img: imageBase64 ?? '',
        state: _state,
        gender: _gender,
        birthdate: _selectedBirthdate?.toIso8601String() ?? '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.user == null) {
        User createdUser = await widget.userService.createUser(newUser);
        
        // Atribuir roles selecionados
        UserRoleService userRoleService = UserRoleService(dotenv.env['BASE_URL']!);
        List<Role> selectedRoles = roles.where((r) => r.selected == true).toList();
        
        for (var role in selectedRoles) {
          await userRoleService.assignRoleToUser(createdUser.id, role.id);
        }

        // Feedback de sucesso
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('User "${newUser.username}" added successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // await widget.userService.updateUser(newUser);
        // if (mounted) {
        //   ScaffoldMessenger.of(context).showSnackBar(
        //     SnackBar(
        //       content: Text('User "${newUser.username}" updated successfully!'),
        //       backgroundColor: Colors.green,
        //     ),
        //   );
        // }
      }

      // Fechar diálogos e notificar callback
      if (mounted) {
        Navigator.pop(context); // Fechar loading
        widget.onUserAdded();
        Navigator.pop(context); // Fechar o diálogo do formulário
      }

    } catch (e) {
      // Tratamento de erro
      if (mounted) {
        Navigator.pop(context); // Fechar loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.user == null ? 'Add New User' : 'Edit User'),
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
          onPressed: _addUser,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            widget.user == null ? 'Add User' : 'Update User',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
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
                onTap: () => _selectBirthdate(context),
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
            title: Text(roles[index].name ?? 'Role ${index + 1}', style: const TextStyle(color: Colors.white)),
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