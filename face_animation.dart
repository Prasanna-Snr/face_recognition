import 'package:flutter/material.dart';
import 'dart:math';

class FaceIdEnrollmentScreen extends StatefulWidget {
  @override
  _FaceIdEnrollmentScreenState createState() => _FaceIdEnrollmentScreenState();
}

class _FaceIdEnrollmentScreenState extends State<FaceIdEnrollmentScreen> {
  // progress ranges from 0.0 to 1.0
  double _progress = 0.4;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 1. The Circular Mask for Camera
                ClipOval(
                  child: Container(
                    width: 280,
                    height: 280,
                    color: Colors.grey[900],
                    child: Icon(Icons.person, color: Colors.white, size: 100),
                    // Replace Icon with CameraPreview(controller) when ready
                  ),
                ),
                // 2. The Animated Progress Ring
                CustomPaint(
                  size: Size(320, 320),
                  painter: FaceIdPainter(progress: _progress),
                ),
              ],
            ),
          ),
          SizedBox(height: 60),
          Text(
            _progress < 1.0 ? "Move your head slowly to\ncomplete the circle." : "Scan complete.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500),
          ),
          // Slider for demo purposes to simulate head movement
          Slider(
            value: _progress,
            onChanged: (val) => setState(() => _progress = val),
          )
        ],
      ),
    );
  }
}

class FaceIdPainter extends CustomPainter {
  final double progress;
  FaceIdPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final int tickCount = 60; // Number of bars in the circle
    final double tickLength = 20;

    for (int i = 0; i < tickCount; i++) {
      final double angle = (i * 2 * pi / tickCount) - pi / 2;

      // Determine if this tick should be green (completed) or grey (pending)
      bool isCompleted = (i / tickCount) < progress;

      final Paint paint = Paint()
        ..color = isCompleted ? Colors.greenAccent : Colors.white24
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;

      final p1 = Offset(
        center.dx + (radius - tickLength) * cos(angle),
        center.dy + (radius - tickLength) * sin(angle),
      );
      final p2 = Offset(
        center.dx + radius * cos(angle),
        center.dy + radius * sin(angle),
      );

      canvas.drawLine(p1, p2, paint);
    }
  }

  @override
  bool shouldRepaint(FaceIdPainter oldDelegate) => oldDelegate.progress != progress;
}