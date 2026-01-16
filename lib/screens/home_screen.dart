import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:camera/camera.dart';
import 'face_scan_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? username;
  String? email;
  Uint8List? firstFaceBytes;
  final String backendUrl = "http://192.168.18.11:8000";

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Uint8List? decodeBase64Image(String? base64) {
    if (base64 == null || base64.isEmpty) return null;
    try {
      return base64Decode(base64);
    } catch (e) {
      print("Base64 decode error: $e");
      return null;
    }
  }

  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final phone = prefs.getString('phone');
    if (phone == null) return;

    final res = await http.get(Uri.parse("$backendUrl/users/$phone"));

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);

      Uint8List? bytes;
      if (data['faces'] != null && data['faces'].isNotEmpty) {
        bytes = decodeBase64Image(data['faces'][0]); // first face
      }

      setState(() {
        username = data['username'];
        email = data['email'];
        firstFaceBytes = bytes;
      });
    } else {
      print("Failed to fetch user data: ${res.body}");
    }
  }

  Widget profileAvatar() {
    if (firstFaceBytes == null) {
      return const CircleAvatar(radius: 40, child: Icon(Icons.person));
    }

    return CircleAvatar(
      radius: 40,
      backgroundImage: MemoryImage(firstFaceBytes!),
    );
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  // Camera only load when Face Verify tapped
  Future<void> _openFaceScanScreen() async {
    try {
      final List<CameraDescription> cameras = await availableCameras();
      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FaceScanScreen(cameras: cameras),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Camera not available")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text("Home"),
        centerTitle: true,
        // foregroundColor: Colors.white,
        // backgroundColor: Colors.blue,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,

          children: [
            UserAccountsDrawerHeader(
              // decoration: BoxDecoration(
              //   color: Colors.blue
              // ),
              accountName: Text(username ?? ''),
              accountEmail: Text(email ?? ''),
              currentAccountPicture: profileAvatar(),
            ),
            ListTile(
              leading: const Icon(Icons.verified_user),
              title: const Text("Face Verify"),
              onTap: () async {
                Navigator.pop(context);
                await _openFaceScanScreen();
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text("Logout"),
              onTap: logout,
            ),
          ],
        ),
      ),
      body: const Center(child: Text("Welcome!")),
    );
  }
}
