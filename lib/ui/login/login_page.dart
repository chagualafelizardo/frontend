import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:app/controllers/menu_app_controller.dart';
import 'package:app/screens/main/main_screen.dart';
import 'package:flutter/material.dart';
import 'package:app/services/LoginService.dart';
import 'package:provider/provider.dart';
import 'signup_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _emailErrorMessage = '';
  String _passwordErrorMessage = '';
  String _generalErrorMessage = '';
  bool _obscurePassword = true;
  bool _isLoading = false; // Novo estado para controlar o carregamento
  bool _showReconnectDialog = false;

  Future<void> login(BuildContext context, String email, String password) async {
    setState(() {
      _isLoading = true;
      _emailErrorMessage = '';
      _passwordErrorMessage = '';
      _generalErrorMessage = '';
      _showReconnectDialog = false;
    });

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _isLoading = false;
        if (email.isEmpty) _emailErrorMessage = 'Please enter your email.';
        if (password.isEmpty) _passwordErrorMessage = 'Please enter your password.';
      });
      return;
    }

    try {
      final user = await LoginService.checkUser(email, password)
          .timeout(const Duration(seconds: 30)); // Timeout de 30 segundos
      
      if (!mounted) return;

      setState(() => _isLoading = false);
      handleLoginResult(context, user);
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _showReconnectDialog = true;
      });
    } catch (error) {
      print('Error during login: $error');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _generalErrorMessage = 'An error occurred during login. Please try again.';
      });
    }
  }

  // Adicione este método para mostrar o diálogo de reconexão
  void _showReconnectPrompt(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Connection Timeout'),
          content: const Text('The connection to the server timed out. Would you like to try again?'),
          actions: <Widget>[
            TextButton(
              child: const Text('No'),
              onPressed: () {
                Navigator.of(context).pop();
                setState(() => _showReconnectDialog = false);
              },
            ),
            TextButton(
              child: const Text('Yes'),
              onPressed: () {
                Navigator.of(context).pop();
                setState(() => _showReconnectDialog = false);
                // Tenta reconectar automaticamente
                login(context, _emailController.text, _passwordController.text);
              },
            ),
          ],
        );
      },
    );
  }

  void handleLoginResult(BuildContext context, Map<String, dynamic>? user) {
  if (user != null && user.containsKey('username')) {
    String userName = user['username'];
    Uint8List? userImageBytes;
    if (user['img'] != null) {
      userImageBytes = base64Decode(user['img']);
    }

    // Coloque o Provider no contexto mais alto
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => MenuAppController()),  // Coloque o seu MenuAppController aqui
          ],
          child: MainScreen(userName: userName),
        ),
      ),
    );
  } else {
    setState(() {
      _generalErrorMessage = 'Invalid email or password.';
    });
  }
}

  @override
  Widget build(BuildContext context) {
    if (_showReconnectDialog) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showReconnectPrompt(context);
      });
    }
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/car_rental.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(
            color: Colors.black.withOpacity(0.5),
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _header(context),
                        if (_generalErrorMessage.isNotEmpty)
                          _generalErrorText(context),
                        _inputField(context),
                        _forgotPassword(context),
                        _signup(context),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    Widget _header(BuildContext context) {
      return const Column(
        children: [
          Text(
            "Welcome Back",
            style: TextStyle(
                fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          SizedBox(height: 10),
          Text(
            "Enter your credentials to login",
            style: TextStyle(color: Colors.white),
          ),
        ],
      );
    }

    Widget _inputField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_emailErrorMessage.isNotEmpty)
          _errorText(context, _emailErrorMessage),
        TextField(
          controller: _emailController,
          style: const TextStyle(color: Colors.black), // Cor do texto
          decoration: InputDecoration(
            hintText: "Email",
            hintStyle: TextStyle(color: Colors.grey[500]), // Cor da dica de texto
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
            fillColor: Colors.grey[800], // Cor de fundo alterada
            filled: true,
            prefixIcon: const Icon(Icons.person, color: Colors.white), // Ícone branco
          ),
        ),
        const SizedBox(height: 10),
        if (_passwordErrorMessage.isNotEmpty)
          _errorText(context, _passwordErrorMessage),
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          style: const TextStyle(color: Colors.black),
          decoration: InputDecoration(
            hintText: "Password",
            hintStyle: TextStyle(color: Colors.grey[500]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
            fillColor: Colors.grey[800],
            filled: true,
            prefixIcon: const Icon(Icons.lock, color: Colors.white),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility : Icons.visibility_off,
                color: Colors.white,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
          ),
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: _isLoading
              ? null // Desabilita o botão durante o carregamento
              : () {
                  login(context, _emailController.text, _passwordController.text);
                },
          style: ElevatedButton.styleFrom(
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: Colors.orangeAccent,
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text(
                  "Login",
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                  ),
                ),
        ),
      ],
    );
  }


    Widget _errorText(BuildContext context, String message) {
      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        child: Text(
          message,
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    Widget _generalErrorText(BuildContext context) {
      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        child: Text(
          _generalErrorMessage,
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    Widget _forgotPassword(BuildContext context) {
      return TextButton(
        onPressed: () {},
        child: const Text(
          "Forgot password?",
          style: TextStyle(color: Colors.orangeAccent),
        ),
      );
    }

    Widget _signup(BuildContext context) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "Don't have an account? ",
            style: TextStyle(color: Colors.white),
          ),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SignupPage()),
              );
            },
            child: const Text(
              "Sign Up",
              style: TextStyle(color: Colors.orangeAccent),
            ),
          ),
        ],
      );
    }
  }