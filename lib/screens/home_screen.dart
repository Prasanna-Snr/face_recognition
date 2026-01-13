import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'face_scan_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  Future<void> _openFaceScanScreen() async {
    try {
      // Load cameras only when user clicks Face Verify
      final List<CameraDescription> cameras = await availableCameras();

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FaceScanScreen(cameras: cameras),
        ),
      );
    } catch (e) {
      // Camera error handling
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Camera not available")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text("Employee Provident Funds"),
        centerTitle: true,
      ),

      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 40, color: Colors.blue),
                  ),

                  Text(
                    "Prasanna Sunuwar",
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  Text(
                    "prasannasunuwar03@gmail.com",
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),

            ListTile(
              leading: const Icon(Icons.document_scanner_sharp),
              title: const Text("Face Verify"),
              onTap: () async {
                Navigator.pop(context);
                await _openFaceScanScreen();
              },
            ),
          ],
        ),
      ),

      body: const Center(
        child: Text(
          "Home Screen",
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
