import 'package:flutter/material.dart';

import 'circle_data.dart';

class LinePainter extends CustomPainter {
  final Map<int, CircleData> circles;
  final Map<int, Set<int>> connections;

  const LinePainter(this.circles, this.connections);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1.0;

    for (final circleId in connections.keys) {
      final cons = connections[circleId];
      final startCircle = circles[circleId];
      if (cons == null || startCircle == null) continue;

      for (final otherCircleId in cons) {
        final endCircle = circles[otherCircleId];
        if (endCircle == null) continue;

        canvas.drawLine(
          startCircle.position,
          endCircle.position,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
