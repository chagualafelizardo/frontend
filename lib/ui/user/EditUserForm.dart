import 'dart:typed_data';
import 'dart:convert';
import 'package:app/models/UserRenderImgBase64.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:app/models/User.dart';
import 'package:app/services/UserService.dart';

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
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _birthdateController = TextEditingController();

  Uint8List? _imageBytes;
  String _state = 'active';
  String _gender = 'male';
  DateTime? _selectedBirthdate;

  @override
  void initState() {
    super.initState();

    // Inicializar controladores com valores atuais do usuário
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
    // Formatando a data de nascimento se já existir uma
    _selectedBirthdate = widget.user.birthdate;
    _birthdateController.text =
        DateFormat('yyyy-MM-dd').format(widget.user.birthdate);
  
    if (widget.user.imgBase64 != null) {
      _imageBytes = base64Decode(widget.user.imgBase64!);
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

  void _saveUser() {
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

      widget.userService
          .updateUser(widget.user.id as User, updatedUser)
          .then((_) {
        widget.onUserUpdated();
        Navigator.of(context).pop();
      }).catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update user: $error')),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit User'),
      content: SizedBox(
        width: 600,
        height: 600,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                GestureDetector(
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
                TextFormField(
                  controller: TextEditingController(text: _gender),
                  decoration: const InputDecoration(labelText: 'Gender'),
                  onChanged: (value) {
                    setState(() {
                      _gender = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a gender';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _birthdateController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Birthdate',
                    hintText: 'Select your birthdate',
                  ),
                  onTap: _pickBirthdate,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a birthdate';
                    }
                    return null;
                  },
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
                  controller: TextEditingController(text: _state),
                  decoration: const InputDecoration(labelText: 'State'),
                  onChanged: (value) {
                    setState(() {
                      _state = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a state';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration:
                      const InputDecoration(labelText: 'Confirm Password'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
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
}
