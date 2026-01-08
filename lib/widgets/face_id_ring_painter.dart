import 'dart:math';
import 'package:flutter/material.dart';

class FaceIdRingPainter extends CustomPainter {
  final double progress;
  final Color activeColor;

  FaceIdRingPainter({required this.progress, this.activeColor = Colors.blue});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const int totalTicks = 80;

    for (int i = 0; i < totalTicks; i++) {
      final double angle = (i * 2 * pi / totalTicks) - pi / 2;
      final bool isActive = (i / totalTicks) < progress;

      final paint = Paint()
        ..color = isActive ? activeColor : const Color(0xFF333333)
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round;

      final start = Offset(center.dx + (radius - 15) * cos(angle), center.dy + (radius - 15) * sin(angle));
      final end = Offset(center.dx + radius * cos(angle), center.dy + radius * sin(angle));

      canvas.drawLine(start, end, paint);
    }
  }

  @override
  bool shouldRepaint(FaceIdRingPainter oldDelegate) => oldDelegate.progress != progress;
}