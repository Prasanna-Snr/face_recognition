// login_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';
import 'sign_up_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  final String _backendUrl = "http://10.238.8.1:8000";

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    if (isLoggedIn && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }

  Future<void> _loginUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String? fcmToken = await FirebaseMessaging.instance.getToken();

      Map<String, dynamic> data = {
        "phone": _phoneController.text.trim(),
        "password": _passwordController.text.trim(),
      };

      final response = await http.post(
        Uri.parse("$_backendUrl/users/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(data),
      );

      final resBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();

        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('phone', _phoneController.text.trim());
        await prefs.setString('username', (resBody['username'] ?? "").toString());
        await prefs.setString('email', (resBody['email'] ?? "").toString());

        if (fcmToken != null) {
          await http.post(
            Uri.parse("$_backendUrl/register-token"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "phone": _phoneController.text.trim(),
              "token": fcmToken,
            }),
          );
        }

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(resBody['detail']?.toString() ?? 'Login failed')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: "Phone"),
                keyboardType: TextInputType.phone,
                validator: (val) =>
                val == null || val.length < 7 ? "Enter valid phone number" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: "Password"),
                obscureText: true,
                validator: (val) =>
                val == null || val.length < 6 ? "Password too short" : null,
              ),
              const SizedBox(height: 32),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                onPressed: _loginUser,
                child: const Text("Login"),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SignUpScreen()),
                  );
                },
                child: const Text("Sign up"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
