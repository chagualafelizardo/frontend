import 'package:flutter/material.dart';
import 'package:app/ui/login/login_page.dart';
import 'package:app/services/RoleService.dart';
import 'package:app/services/UserService.dart';
import 'package:app/models/User.dart';
import 'package:flutter/services.dart' show ByteData, rootBundle;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({Key? key}) : super(key: key);

  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  String _selectedUserType = '';
  List<String> _roles = [];
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final DateTime _currentDateTime = DateTime.now();
  bool _isLoading = false;
  String _gender = '';
  String? _defaultImageBase64;

  @override
  void initState() {
    super.initState();
    _fetchUserRoles();
    _loadDefaultImage();
  }

  Future<void> _fetchUserRoles() async {
    try {
      final roles = await RoleService(dotenv.env['BASE_URL']!).getRoles();
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
    final ByteData imageData = await rootBundle.load('assets/images/user_default.png');
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
        id: 0,
        username: _usernameController.text,
        firstName: _usernameController.text,
        lastName: _usernameController.text,
        gender: _gender,
        birthdate: _currentDateTime.toIso8601String(),
        address: ' ',
        neighborhood: ' ',
        email: _emailController.text,
        phone1: _contactController.text,
        phone2: _contactController.text,
        password: _passwordController.text,
        img: _defaultImageBase64!,
        state: 'inactive',
        createdAt: _currentDateTime,
      );

      final userService = UserService(dotenv.env['BASE_URL']!);
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
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Sign Up', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue[700],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const Text(
                      "Sign up",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Create your account",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    _buildTextField(
                      controller: _usernameController,
                      hintText: "Username",
                      icon: Icons.person,
                      validator: (value) => value == null || value.isEmpty
                          ? 'Please enter your username'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _emailController,
                      hintText: "Email",
                      icon: Icons.email,
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
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _contactController,
                      hintText: "Contact",
                      icon: Icons.phone,
                      validator: (value) => value == null || value.isEmpty
                          ? 'Please enter your contact number'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    _buildDropdown(),
                    const SizedBox(height: 16),
                    _buildGenderSelection(),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _passwordController,
                      hintText: "Password",
                      icon: Icons.lock,
                      obscureText: true,
                      validator: (value) => value == null || value.isEmpty
                          ? 'Please enter your password'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _confirmPasswordController,
                      hintText: "Confirm Password",
                      icon: Icons.lock,
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
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate() && _gender.isNotEmpty) {
                          saveUser();
                        } else if (_gender.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please select your gender')),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.blue[700],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Sign Up',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: TextButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const LoginPage()),
                          );
                        },
                        child: const Text(
                          "Already have an account? Log in",
                          style: TextStyle(color: Colors.blue),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    required String? Function(String?)? validator,
    bool obscureText = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.black87),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey[600]),
        prefixIcon: Icon(icon, color: Colors.grey[700]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[400]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[400]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blue, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      ),
      validator: validator,
    );
  }

  Widget _buildDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedUserType.isEmpty ? null : _selectedUserType,
      style: const TextStyle(color: Color.fromARGB(221, 15, 15, 15)),
      decoration: InputDecoration(
        hintText: "Select user role",
        hintStyle: TextStyle(color: Colors.grey[600]),
        prefixIcon: Icon(Icons.person_outline, color: Colors.grey[700]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[400]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[400]!),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
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
      validator: (value) => value == null ? 'Please select a user role' : null,
    );
  }

  Widget _buildGenderSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Gender",
          style: TextStyle(fontSize: 16, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                "Male",
                style: TextStyle(color: Colors.black), 
              ),
              leading: Radio<String>(
                value: 'M',
                groupValue: _gender,
                fillColor: WidgetStateColor.resolveWith((states) => Colors.blue),
                onChanged: (value) {
                  setState(() {
                    _gender = value!;
                  });
                },
              ),
            ),
          ),
            Expanded(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  "Famale",
                  style: TextStyle(color: Colors.black), 
                ),
                leading: Radio<String>(
                  value: 'F',
                  groupValue: _gender,
                  fillColor: WidgetStateColor.resolveWith((states) => Colors.blue),
                  onChanged: (value) {
                    setState(() {
                      _gender = value!;
                    });
                  },
                ),
              ),
            ),
          ],
        ),
        if (_gender.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text(
              'Please select your gender',
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }
}