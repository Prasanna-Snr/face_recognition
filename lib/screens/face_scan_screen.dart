import 'dart:convert';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/face_id_ring_painter.dart';

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

  String pythonServerUrl = "http://10.238.8.1:8000/faces/verify";
  String loggedInPhone = ""; // login user ko phone store garna

  @override
  void initState() {
    super.initState();
    _initCamera();
    _loadUserPhone();
  }

  // Login user ko phone load garne function
  Future<void> _loadUserPhone() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      loggedInPhone = prefs.getString('phone') ?? "";
    });
  }

  // Camera initialize garne function
  Future<void> _initCamera() async {
    final front = widget.cameras
        .firstWhere((c) => c.lensDirection == CameraLensDirection.front);
    _controller =
        CameraController(front, ResolutionPreset.medium, enableAudio: false);
    await _controller!.initialize();
    if (mounted) setState(() {});
  }

  // Face verification function
  Future<void> _verifyFace() async {
    if (_isProcessing) return;

    if (loggedInPhone.isEmpty) {
      setState(() {
        _statusMessage = "User phone not found. Please login again.";
      });
      return;
    }

    setState(() {
      _isProcessing = true;
      _statusMessage = "Capturing face and sending to server...";
    });

    try {
      final XFile photo = await _controller!.takePicture();

      // Multipart request prepare garne
      var request = http.MultipartRequest('POST', Uri.parse(pythonServerUrl));
      request.files.add(await http.MultipartFile.fromPath('file', photo.path));
      request.fields['phone'] = loggedInPhone; // backend ma phone send garne

      // Request send garne and response read garne
      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var result = json.decode(responseData);

      // Verification result handle garne
      if (result['verified'] == true) {
        setState(() {
          _statusMessage = "Face verified. Check notification for details.";
          _isProcessing = false;
        });
      } else {
        setState(() {
          _statusMessage = "Face not recognized. Try again.";
          _isProcessing = false;
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = "Connection Error: Is Python server running?";
        _isProcessing = false;
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
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: _controller!.value.previewSize!.height,
                        height: _controller!.value.previewSize!.width,
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
                      activeColor:
                      _isProcessing ? Colors.blue : Colors.white24,
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
            textAlign: TextAlign.center,
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
