import 'package:face/screens/face_scan_screen.dart';
import 'package:face/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/user_service.dart';

class HomeScreen extends StatefulWidget {
  final String phone;
  const HomeScreen({super.key, required this.phone});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? username;
  String? email;

  @override
  void initState() {
    super.initState();
    loadUserProfile();
  }

  Future<void> loadUserProfile() async {
    try {
      final profile = await fetchUserProfile(widget.phone);
      setState(() {
        username = profile['username'];
        email = profile['email'];
      });
    } catch (e) {
      debugPrint('Error loading profile: $e');
    }
  }

  Future<void> logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Drawer Header
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.deepPurple),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 32, color: Colors.black87),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    username ?? 'Loading...',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontSize: 18,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    email ?? '',
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onPrimary.withOpacity(0.8),
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w100,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // Drawer Items
            ListTile(
              leading: const Icon(Icons.crop_free),
              title: const Text(
                'Verify',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w400,
                ),
              ),
              onTap: () async {
                // Close drawer first
                Navigator.pop(context);

                await Future.delayed(const Duration(milliseconds: 200));

                // Navigate and wait for result
                final bool? verified = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FaceScanScreen(phone: widget.phone),
                  ),
                );

                // Show verification result
                if (verified != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w400,
                        ),
                        verified
                            ? 'Face verified successfully'
                            : 'Face verification failed',
                      ),
                      backgroundColor: verified ? Colors.green : Colors.red,
                    ),
                  );
                }
              },
            ),

            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text(
                'Settings',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w400,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
              },
            ),

            const Divider(),

            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text(
                'Logout',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w400,
                ),
              ),
              onTap: () {
                logout(context);
              },
            ),
          ],
        ),
      ),

      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: Text(
          'Employee provident Fund',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
        ),
      ),

      body: const Center(
        child: Text(
          "Home Screen",
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}
