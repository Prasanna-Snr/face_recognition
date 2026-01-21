import 'dart:convert';
import 'package:face/screens/home_screen.dart';
import 'package:face/widgets/custom_button.dart';
import 'package:face/widgets/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool loading = false;

  // ---------------- LOGIN METHOD ----------------
  Future<void> login() async {
    // Validate form first
    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);

    try {
      final response = await http.post(
        Uri.parse('http://172.16.0.212:8000/users/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "phone": _phoneController.text.trim(),
          "password": _passwordController.text.trim(),
        }),
      );

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('phone', _phoneController.text.trim());

        // Navigate to HomeScreen
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => HomeScreen(phone: _phoneController.text.trim()),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Invalid phone or password',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('server down')));
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ---------------- BUILD METHOD ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ---------------- Illustration ----------------
                SvgPicture.asset(
                  'assets/images/login_illustration.svg',
                  height: 150,
                ),
                const SizedBox(height: 30),

                // ---------------- Login Form ----------------
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      CustomTextField(
                        hintText: "Phone Number",
                        prefixIcon: Icons.phone,
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        maxLength: 10,
                        validator: (val) => val == null || val.length != 10
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
                        validator: (val) => val == null || val.length < 6
                            ? "Enter password"
                            : null,
                      ),
                      const SizedBox(height: 32),

                      // ---------------- Login Button ----------------
                      loading
                          ? const Center(child: CircularProgressIndicator())
                          : CustomButton(
                              text: "Login",
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  login();
                                }
                              },
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
}
