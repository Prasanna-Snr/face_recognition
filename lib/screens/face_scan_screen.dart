import 'dart:convert';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../widgets/face_id_ring_painter.dart';
import 'home_screen.dart';

class FaceScanScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  const FaceScanScreen({super.key, required this.cameras});

  @override
  State<FaceScanScreen> createState() => _FaceScanScreenState();
}

class _FaceScanScreenState extends State<FaceScanScreen> {
  CameraController? _controller;
  bool _isProcessing = false;
  String _statusMessage = "Center your face and tap Verify";

  // Correct Python FastAPI server URL
  final String pythonServerUrl = "http://192.168.1.72:8000/faces/verify";

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final front = widget.cameras
        .firstWhere((c) => c.lensDirection == CameraLensDirection.front);
    _controller =
        CameraController(front, ResolutionPreset.medium, enableAudio: false);
    await _controller!.initialize();
    if (mounted) setState(() {});
  }

  // --------------------
  // Main face verification
  // --------------------
  Future<void> _verifyFace() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _statusMessage = "Capturing face and sending to server...";
    });

    try {
      // 1️⃣ Take picture
      final XFile photo = await _controller!.takePicture();

      // 2️⃣ Prepare multipart request
      var request = http.MultipartRequest('POST', Uri.parse(pythonServerUrl));
      request.files.add(await http.MultipartFile.fromPath('file', photo.path));

      // 3️⃣ Send request and get response
      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var result = json.decode(responseData);

      // 4️⃣ Handle verification
      if (result['verified'] == true) {
        setState(() => _statusMessage = "Identity Verified: ${result['name']}");
        await Future.delayed(const Duration(seconds: 1));

        if (mounted) {
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => const HomeScreen()));
        }
      } else {
        setState(() {
          _isProcessing = false;
          _statusMessage = "Face not recognized. Try again.";
        });
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _statusMessage = "Connection Error: Is Python server running?";
      });
      debugPrint("Face verification error: $e");
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                ClipOval(
                  child: Container(
                    width: 250,
                    height: 250,
                    color: Colors.black,
                    child: FittedBox(
                      fit: BoxFit.cover, // Keeps natural aspect ratio and fills the oval
                      child: SizedBox(
                        width: _controller!.value.previewSize!.height, // notice height first
                        height: _controller!.value.previewSize!.width,  // width second
                        child: CameraPreview(_controller!),
                      ),
                    ),
                  ),
                ),

                SizedBox(
                  width: 300,
                  height: 300,
                  child: CustomPaint(
                    painter: FaceIdRingPainter(
                      progress: _isProcessing ? 0.8 : 1.0,
                      activeColor: _isProcessing ? Colors.blue : Colors.white24,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          Text(
            _statusMessage,
            style: const TextStyle(color: Colors.white, fontSize: 18),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: _isProcessing ? null : _verifyFace,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding:
              const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
            ),
            child: _isProcessing
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white),
            )
                : const Text("Verify Identity"),
          ),
        ],
      ),
    );
  }
}
