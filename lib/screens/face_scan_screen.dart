import 'dart:convert';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/face_id_ring_painter.dart';
import '../notification_helper.dart'; // notification helper use garne

class FaceScanScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  const FaceScanScreen({super.key, required this.cameras});

  @override
  State<FaceScanScreen> createState() => _FaceScanScreenState();
}

class _FaceScanScreenState extends State<FaceScanScreen> {
  CameraController? _controller; // camera controller
  bool _isProcessing = false; // face verify gariraheko ho ki hoina
  String _statusMessage = "Center your face and tap Verify"; // user lai message

  String pythonServerUrl = "http://192.168.18.11:8000/faces/verify"; // backend url
  String loggedInPhone = ""; // login gareko user ko phone store garna

  @override
  void initState() {
    super.initState();
    _initCamera(); // camera initialize garna
    _loadUserPhone(); // login user ko phone load garna
  }

  // SharedPreferences bata phone load garne
  Future<void> _loadUserPhone() async {
    final prefs = await SharedPreferences.getInstance();
    loggedInPhone = prefs.getString('phone') ?? "";
  }

  // Front camera initialize garne function
  Future<void> _initCamera() async {
    final frontCamera = widget.cameras.firstWhere(
            (c) => c.lensDirection == CameraLensDirection.front);
    _controller = CameraController(
        frontCamera, ResolutionPreset.medium, enableAudio: false);
    await _controller!.initialize();
    if (mounted) setState(() {}); // UI update garna
  }

  // Face verify garne function
  Future<void> _verifyFace() async {
    if (_isProcessing) return; // already processing bhaye ignore garne

    if (loggedInPhone.isEmpty) {
      setState(() => _statusMessage = "User phone not found."); // phone missing
      return;
    }

    // processing start
    setState(() {
      _isProcessing = true;
      _statusMessage = "Verifying face...";
    });

    try {
      final photo = await _controller!.takePicture(); // camera bata photo

      // HTTP request prepare garne
      final request =
      http.MultipartRequest('POST', Uri.parse(pythonServerUrl));
      request.files.add(await http.MultipartFile.fromPath('file', photo.path));
      request.fields['phone'] = loggedInPhone;

      // request send garne
      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final result = jsonDecode(responseData);

      // backend response handle
      if (result['verified'] == true) {
        setState(() {
          _statusMessage = "Face verified successfully"; // success message
          _isProcessing = false;
        });

        // foreground notification
        await NotificationHelper.show(
          title: "Face Verified",
          body: "Identity confirmed",
        );
      } else {
        setState(() {
          _statusMessage = "Face not recognized. Try again."; // fail message
          _isProcessing = false;
        });

        // foreground notification
        await NotificationHelper.show(
          title: "Verification Failed",
          body: "Face does not match",
        );
      }
    } catch (e) {
      setState(() {
        _statusMessage = "Server error"; // network or backend error
        _isProcessing = false;
      });

      // foreground notification for error
      await NotificationHelper.show(
        title: "Error",
        body: "Unable to verify face",
      );
    }
  }

  @override
  void dispose() {
    _controller?.dispose(); // camera dispose garne
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // camera initialize vako chaina bhaye loading
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
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
                // Face ring painter
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
          // status message
          Text(
            _statusMessage,
            style: const TextStyle(color: Colors.white, fontSize: 18),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          // verify button
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
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
                : const Text("Verify Identity"),
          ),
        ],
      ),
    );
  }
}