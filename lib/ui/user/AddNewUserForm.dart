import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:app/models/User.dart';
import 'package:app/services/UserService.dart';
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
  final TextEditingController _confirmPasswordController =
      TextEditingController();
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
      RoleService roleService = RoleService('http://localhost:5000');
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

 Future<void> _addUser() async {
  if (_formKey.currentState!.validate()) {
    print('✅ Formulário validado com sucesso.');

    try {
      // Captura os valores dos campos
      String? imageBase64;
      if (_imageBytes != null) {
        imageBase64 = base64Encode(_imageBytes!);
        print('🖼️ Imagem convertida para base64.');
      }

      String username = _usernameController.text;
      String firstName = _firstNameController.text;
      String lastName = _lastNameController.text;
      String email = _emailController.text;
      String password = _passwordController.text;
      String address = _addressController.text.isEmpty ? '' : _addressController.text;
      String phone1 = _phone1Controller.text.isEmpty ? '' : _phone1Controller.text;
      String phone2 = _phone2Controller.text.isEmpty ? '' : _phone2Controller.text;
      String state = _state ?? '';
      String gender = _gender ?? '';
      String birthdate = _selectedBirthdate?.toIso8601String() ?? '';

      // Validando campos obrigatórios
      if (username.isEmpty || firstName.isEmpty || lastName.isEmpty || email.isEmpty || password.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('⚠️ Please fill all required fields.')),
        );
        print('❌ Erro: Campos obrigatórios estão vazios.');
        return;
      }

      // Criando o objeto User
      print('🔄 Criando objeto User...');
      User newUser = User(
        id: widget.user?.id ?? 0,
        username: username,
        firstName: firstName,
        lastName: lastName,
        email: email,
        address: address,
        neighborhood: _neighborhoodController.text.isEmpty ? '' : _neighborhoodController.text,
        phone1: phone1,
        phone2: phone2,
        password: password,
        img: imageBase64 ?? '',
        state: state,
        gender: gender,
        birthdate: birthdate,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      print('✅ Usuário criado: ${newUser.toJson()}');

      // Operação de criação/atualização
      if (widget.user == null) { // Se `widget.user` for `null`, criar um novo usuário
        print('🚀 Criando novo usuário...');
        User createdUser = await widget.userService.createUser(newUser);
        print('✅ Usuário criado com sucesso! ID: ${createdUser.id}');

        // Atribuir roles ao usuário
        UserRoleService userRoleService = UserRoleService('http://localhost:5000');
        List<Role> selectedRoles = roles.where((r) => r.selected == true).toList();

        if (selectedRoles.isEmpty) {
          print('⚠️ Nenhuma role selecionada para o usuário.');
        } else {
          print('🛠️ Roles selecionadas para atribuir:');
          for (var role in selectedRoles) {
            print('- Role ID: ${role.id}, Nome: ${role.name}');
          }

          for (var role in selectedRoles) {
            print('🔄 Atribuindo role ${role.id} ao usuário ${createdUser.id}...');
            await userRoleService.assignRoleToUser(createdUser.id, role.id!);
            print('✅ Role ${role.id} atribuída com sucesso!');
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('🎉 User "${newUser.username}" added successfully with roles!')),
        );
      } else {
        // Atualizar usuário existente
        // print('✏️ Atualizando usuário existente ID: ${widget.user!.id}...');
        // await widget.userService.updateUser(newUser);
        // print('✅ Usuário atualizado com sucesso!');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ User "${newUser.username}" updated successfully!')),
        );
      }

      widget.onUserAdded();
      Navigator.of(context).pop();
    } catch (e, stackTrace) {
      print('❌ Erro ao adicionar/editar usuário: $e');
      print('📌 StackTrace: $stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Failed to add/edit user. Please try again.')),
      );
    }
  } else {
    print('❌ Erro: Formulário inválido.');
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
          child: Text(widget.user == null ? 'Add User' : 'Update User'),
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
                        : Image.memory(_imageBytes!, fit: BoxFit.cover),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            TextFormField(
              controller: _firstNameController,
              decoration: const InputDecoration(labelText: 'First Name'),
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
              onTap: () => _selectBirthdate(context),
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

  return ListView.builder(
    itemCount: roles.length,
    itemBuilder: (context, index) {
      // Define a cor alternada com base no índice
      final Color tileColor = index % 2 == 0
          ? const Color.fromARGB(255, 14, 13, 13) // Cor clara para linhas pares
          : const Color.fromARGB(255, 53, 51, 51);        // Cor branca para linhas ímpares

      return Container(
        color: tileColor, // Define a cor do fundo
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
