import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'home_screen.dart'; // Import your HomeScreen

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;

  // Replace with your backend IP and port
  final String _backendUrl = "http://10.238.8.1:8000";

  // Function to register user
  Future<void> _registerUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Get FCM token from Firebase Messaging
      String? fcmToken = await FirebaseMessaging.instance.getToken();

      // Prepare the data payload to send to backend
      Map<String, dynamic> data = {
        "username": _usernameController.text.trim(),
        "email": _emailController.text.trim(),
        "phone": _phoneController.text.trim(),
        "password": _passwordController.text.trim(),
        "device_token": fcmToken
      };

      // Send HTTP POST request to FastAPI backend
      final response = await http.post(
        Uri.parse("$_backendUrl/users/register"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(data),
      );

      final resBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // If registration is successful, show a message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(resBody['message'])),
        );

        // Navigate to HomeScreen and remove SignUpScreen from stack
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else {
        // Show error message from backend if registration failed
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(resBody['detail'] ?? 'Registration failed')),
        );
      }
    } catch (e) {
      // Show error if HTTP request or token generation fails
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sign Up")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Username input
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: "Username"),
                validator: (val) => val == null || val.isEmpty ? "Enter username" : null,
              ),
              const SizedBox(height: 16),

              // Email input
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: "Email"),
                keyboardType: TextInputType.emailAddress,
                validator: (val) =>
                val == null || !val.contains("@") ? "Enter valid email" : null,
              ),
              const SizedBox(height: 16),

              // Phone input
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: "Phone"),
                keyboardType: TextInputType.phone,
                validator: (val) =>
                val == null || val.length < 7 ? "Enter valid phone number" : null,
              ),
              const SizedBox(height: 16),

              // Password input
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: "Password"),
                obscureText: true,
                validator: (val) =>
                val == null || val.length < 6 ? "Password too short" : null,
              ),
              const SizedBox(height: 32),

              // Register button or loading indicator
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                onPressed: _registerUser,
                child: const Text("Register"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
