import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app_init_service.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();

    // immediately splash show
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startSplash();
    });
  }

  Future<void> _startSplash() async {
    // Background init async start garne
    _initializeApp();

    // Optional: extra splash wait
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => isLoggedIn ? const HomeScreen() : const LoginScreen(),
      ),
    );
  }

  Future<void> _initializeApp() async {
    await AppInitService.init(); // Firebase, SharedPreferences, FCM init
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/logo.png',height: 250),
            const SizedBox(height: 20),
            const Text('Employee Provident Funds', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
