import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;

class FaceScanScreen extends StatefulWidget {
  final String phone;
  const FaceScanScreen({super.key, required this.phone});

  @override
  _FaceScanScreenState createState() => _FaceScanScreenState();
}

class _FaceScanScreenState extends State<FaceScanScreen> {
  final FaceDetector faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: true,
      enableClassification: true,
      minFaceSize: 0.3,
      performanceMode: FaceDetectorMode.fast,
    ),
  );

  late CameraController cameraController;
  bool isCameraInitialized = false;
  bool isDetecting = false;
  bool isFrontCamera = true;
  List<String> challengeActions = ['smile', 'blink', 'lookRight', 'lookLeft'];
  int currentActionIndex = 0;
  bool waitingForNeutral = false;

  double? smilingProbability;
  double? leftEyeOpenProbability;
  double? rightEyeOpenProbability;
  double? headEulerAngleY;

  @override
  void initState() {
    super.initState();
    initializeCamera();
    challengeActions.shuffle();
  }

  Future<void> initializeCamera() async {
    final cameras = await availableCameras();
    final frontCamera = cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front,
    );
    cameraController = CameraController(
      frontCamera,
      ResolutionPreset.high,
      enableAudio: false,
    );
    await cameraController.initialize();
    if (mounted) {
      setState(() {
        isCameraInitialized = true;
      });
      startFaceDetection();
    }
  }

  void startFaceDetection() {
    if (isCameraInitialized) {
      cameraController.startImageStream((CameraImage image) {
        if (!isDetecting) {
          isDetecting = true;
          detectFaces(image).then((_) {
            isDetecting = false;
          });
        }
      });
    }
  }

  Future<void> detectFaces(CameraImage image) async {
    try {
      final WriteBuffer allBytes = WriteBuffer();
      for (Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      final inputImage = InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: InputImageRotation.rotation270deg,
          format: InputImageFormat.nv21,
          bytesPerRow: image.planes[0].bytesPerRow,
        ),
      );

      final faces = await faceDetector.processImage(inputImage);

      if (!mounted) return;
      if (faces.isNotEmpty) {
        final face = faces.first;
        setState(() {
          smilingProbability = face.smilingProbability;
          leftEyeOpenProbability = face.leftEyeOpenProbability;
          rightEyeOpenProbability = face.rightEyeOpenProbability;
          headEulerAngleY = face.headEulerAngleY;
        });
        await checkChallenge(face);
      }
    } catch (e) {
      debugPrint('Error in face detection: $e');
    }
  }

  Future<void> checkChallenge(Face face) async {
    if (waitingForNeutral) {
      if (isNeutralPosition(face)) {
        waitingForNeutral = false;
      } else {
        return;
      }
    }

    String currentAction = challengeActions[currentActionIndex];
    bool actionCompleted = false;

    switch (currentAction) {
      case 'smile':
        actionCompleted = face.smilingProbability != null &&
            face.smilingProbability! > 0.5;
        break;
      case 'blink':
        actionCompleted = (face.leftEyeOpenProbability != null &&
            face.leftEyeOpenProbability! < 0.3) ||
            (face.rightEyeOpenProbability != null &&
                face.rightEyeOpenProbability! < 0.3);
        break;
      case 'lookRight':
        actionCompleted = face.headEulerAngleY != null &&
            face.headEulerAngleY! < -10;
        break;
      case 'lookLeft':
        actionCompleted = face.headEulerAngleY != null &&
            face.headEulerAngleY! > 10;
        break;
    }

    if (actionCompleted) {
      currentActionIndex++;
      if (currentActionIndex >= challengeActions.length) {
        currentActionIndex = 0;
        if (mounted) {
          // Capture image after liveness success
          final XFile image = await cameraController.takePicture();
          // Call backend for face + phone verification
          final verified = await verifyFaceBackend(image);
          Navigator.pop(context, verified);
        }
      } else {
        waitingForNeutral = true;
      }
    }
  }

  bool isNeutralPosition(Face face) {
    return (face.smilingProbability == null ||
        face.smilingProbability! < 0.1) &&
        (face.leftEyeOpenProbability == null ||
            face.leftEyeOpenProbability! > 0.7) &&
        (face.rightEyeOpenProbability == null ||
            face.rightEyeOpenProbability! > 0.7) &&
        (face.headEulerAngleY == null ||
            (face.headEulerAngleY! > -10 && face.headEulerAngleY! < 10));
  }

  Future<bool> verifyFaceBackend(XFile image) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://172.16.0.212:8000/faces/verify'),
      );

      request.fields['phone'] = widget.phone;
      request.fields['liveness'] = 'true';
      request.files.add(await http.MultipartFile.fromPath('file', image.path));

      final response = await request.send();
      final respStr = await response.stream.bytesToString();
      final data = jsonDecode(respStr);

      if (data['authorized'] == true) {
        return true;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Face not recognized!',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        );
        return false;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error verifying face: $e',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      );
      return false;
    }
  }

  @override
  void dispose() {
    cameraController.stopImageStream();
    faceDetector.close();
    cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        // toolbarHeight: 70,
        centerTitle: true,
        title: const Text(
          "Verify Your Identity",
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
        ),
      ),
      body: isCameraInitialized
          ? Stack(
        children: [
          // *** FIXED: Original selfie camera preview WITHOUT flip ***
          FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: cameraController.value.previewSize!.height,
              height: cameraController.value.previewSize!.width,
              child: CameraPreview(cameraController),
            ),
          ),
          // *** END OF CHANGE ***

          CustomPaint(painter: HeadMaskPainter(), child: Container()),
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(8),
              color: Colors.black54,
              child: Column(
                children: [
                  Text(
                    'Please ${getActionDescription(challengeActions[currentActionIndex])}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w400,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      )
          : const Center(child: CircularProgressIndicator()),
    );
  }


  String getActionDescription(String action) {
    switch (action) {
      case 'smile':
        return 'smile';
      case 'blink':
        return 'blink';
      case 'lookRight':
        return 'look right';
      case 'lookLeft':
        return 'look left';
      default:
        return '';
    }
  }
}

class HeadMaskPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.4;

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addOval(Rect.fromCircle(center: center, radius: radius))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
