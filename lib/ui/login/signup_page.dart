import 'package:flutter/material.dart';
import 'package:app/ui/login/login_page.dart';
import 'package:app/services/RoleService.dart';
import 'package:app/services/UserService.dart';
import 'package:app/models/User.dart';
import 'package:flutter/services.dart' show ByteData, rootBundle;
import 'dart:convert';

class SignupPage extends StatefulWidget {
  const SignupPage({Key? key}) : super(key: key);

  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  String _selectedUserType = ''; // Role padrão
  List<String> _roles = [];
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final DateTime _currentDateTime = DateTime.now();
  bool _isLoading = false;
  String _gender = ''; // Variável para seleção de gênero
  String? _defaultImageBase64;

  @override
  void initState() {
    super.initState();
    _fetchUserRoles();
    _loadDefaultImage();
  }

  Future<void> _fetchUserRoles() async {
    try {
      final roles = await RoleService('http://localhost:5000').getRoles();
      setState(() {
        _roles = roles.map((role) => role.name).toList();
        if (_roles.isNotEmpty) {
          _selectedUserType = _roles[0];
        }
      });
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load user roles: $error')),
      );
    }
  }

  Future<void> _loadDefaultImage() async {
    final ByteData imageData = await rootBundle.load('images/user_default.png');
    final List<int> imageBytes = imageData.buffer.asUint8List();
    setState(() {
      _defaultImageBase64 = base64Encode(imageBytes);
    });
  }

  Future<void> saveUser() async {
    if (_defaultImageBase64 == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Default image not loaded')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = User(
        id: 0, // ou um valor adequado, se disponível
        username: _usernameController.text,
        firstName: _usernameController.text,
        lastName: _usernameController.text,
        gender: _gender,
        birthdate: _currentDateTime.toIso8601String(),
        address: ' ', // ou um valor adequado, se disponível
        neighborhood: ' ', // ou um valor adequado, se disponível
        email: _emailController.text,
        phone1: _contactController.text,
        phone2: _contactController.text,
        password: _passwordController.text,
        img: _defaultImageBase64!, // Mantido como String base64
        state: 'inactive',
        createdAt: _currentDateTime, // Valor DateTime
        // updatedAt: _currentDateTime, roles: [], // Valor DateTime
      );

      final userService = UserService('http://localhost:5000');
      await userService.createUser(user);

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User registered successfully')));
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => const LoginPage()));
    } catch (error) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to save user: $error')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const Text("Sign up",
                        style: TextStyle(
                            fontSize: 30, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    const Text("Create your account",
                        style: TextStyle(fontSize: 15, color: Colors.grey)),
                    const SizedBox(height: 30),
                    TextFormField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        hintText: "Username",
                        prefixIcon: const Icon(Icons.person),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide.none),
                        filled: true,
                        fillColor: const Color.fromARGB(255, 10, 10, 10),
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Please enter your username'
                          : null,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        hintText: "Email",
                        prefixIcon: const Icon(Icons.email),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide.none),
                        filled: true,
                        fillColor:const Color.fromARGB(255, 10, 10, 10),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                          return 'Please enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _contactController,
                      decoration: InputDecoration(
                        hintText: "Contact",
                        prefixIcon: const Icon(Icons.phone),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide.none),
                        filled: true,
                        fillColor: const Color.fromARGB(255, 10, 10, 10),
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Please enter your contact number'
                          : null,
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      value:
                          _selectedUserType.isEmpty ? null : _selectedUserType,
                      decoration: InputDecoration(
                        hintText: "Select user role",
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide.none),
                        filled: true,
                        fillColor: const Color.fromARGB(255, 10, 10, 10),
                      ),
                      hint: const Text("Select a user role"),
                      items: _roles.map((String userType) {
                        return DropdownMenuItem<String>(
                          value: userType,
                          child: Text(userType),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          _selectedUserType = newValue ?? '';
                        });
                      },
                      validator: (value) =>
                          value == null ? 'Please select a user role' : null,
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
                    if (_gender.isEmpty)
                      const Text(
                        'Please select your gender',
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        hintText: "Password",
                        prefixIcon: const Icon(Icons.lock),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide.none),
                        filled: true,
                        fillColor: const Color.fromARGB(255, 10, 10, 10),
                      ),
                      obscureText: true,
                      validator: (value) => value == null || value.isEmpty
                          ? 'Please enter your password'
                          : null,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _confirmPasswordController,
                      decoration: InputDecoration(
                        hintText: "Confirm Password",
                        prefixIcon: const Icon(Icons.lock),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide.none),
                        filled: true,
                        fillColor: const Color.fromARGB(255, 10, 10, 10),
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please confirm your password';
                        }
                        if (value != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          saveUser();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18)),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: const Text('Sign Up'),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                  builder: (context) => const LoginPage()));
                        },
                        child: const Text("Already have an account? Log in"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
