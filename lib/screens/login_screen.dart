import 'dart:convert';
import 'package:face/widgets/custom_button.dart';
import 'package:face/widgets/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';
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
  final String _backendUrl = "http://192.168.18.11:8000";

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
        await prefs.setString(
          'username',
          (resBody['username'] ?? "").toString(),
        );
        await prefs.setString(
          'email',
          (resBody['email'] ?? "").toString(),
        );

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
          SnackBar(
            content: Text(resBody['detail']?.toString() ?? 'Login failed'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child:SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 30,horizontal: 15),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
          
                  // Illustration
                  SvgPicture.asset(
                    'assets/images/login_illustration.svg',
                    height: 150,
                  ),
                  const SizedBox(height: 30),
          
                  // Login Form
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        CustomTextField(
                          hintText: "Phone Number",
                          prefixIcon: Icons.phone,
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          maxLength: 10,
                          validator: (val) =>
                          val == null || val.length != 10
                              ? "Enter valid phone number"
                              : null,
                        ),
                        const SizedBox(height: 16),
          
                        CustomTextField(
                          hintText: "Password",
                          prefixIcon: Icons.lock,
                          controller: _passwordController,
                          isPassword: true,
                          maxLength: 16,
                          validator: (val) =>
                          val == null || val.length < 6
                              ? "Enter password (min 6 chars)"
                              : null,
                        ),
                        const SizedBox(height: 32),
          
                        // Login Button or Loading
                        _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : CustomButton(
                          text: "Login",
                          onPressed: _loginUser,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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
