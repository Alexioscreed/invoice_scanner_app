import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/chart_data.dart';

class LineChartWidget extends StatelessWidget {
  final List<ChartData> data;
  final bool showPoints;
  final bool showLabels;
  final bool showGrid;
  final bool smoothCurve;
  final Color lineColor;
  final double pointRadius;

  const LineChartWidget({
    Key? key,
    required this.data,
    this.showPoints = true,
    this.showLabels = true,
    this.showGrid = true,
    this.smoothCurve = true,
    this.lineColor = Colors.blue,
    this.pointRadius = 4.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    // Sort data by index
    final sortedData = List<ChartData>.from(data);

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            // Grid
            if (showGrid)
              CustomPaint(
                size: Size(constraints.maxWidth, constraints.maxHeight),
                painter: _GridPainter(),
              ),

            // Line chart
            CustomPaint(
              size: Size(constraints.maxWidth, constraints.maxHeight),
              painter: _LineChartPainter(
                data: sortedData,
                showPoints: showPoints,
                showLabels: showLabels,
                smoothCurve: smoothCurve,
                lineColor: lineColor,
                pointRadius: pointRadius,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..strokeWidth = 1.0;

    // Draw horizontal lines
    for (int i = 1; i < 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Draw vertical lines
    for (int i = 1; i < 6; i++) {
      final x = size.width * i / 6;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LineChartPainter extends CustomPainter {
  final List<ChartData> data;
  final bool showPoints;
  final bool showLabels;
  final bool smoothCurve;
  final Color lineColor;
  final double pointRadius;

  _LineChartPainter({
    required this.data,
    this.showPoints = true,
    this.showLabels = true,
    this.smoothCurve = true,
    this.lineColor = Colors.blue,
    this.pointRadius = 4.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    // Find the maximum value for scaling
    final maxValue = data.map((e) => e.value).reduce(math.max);
    final padding = size.height * 0.1;

    // Calculate x and y positions for each data point
    final points = <Offset>[];

    for (int i = 0; i < data.length; i++) {
      final x = i * size.width / (data.length - 1);
      final y =
          size.height -
          (data[i].value / maxValue) * (size.height - padding * 2) -
          padding;
      points.add(Offset(x, y));
    }

    // Draw the line
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);

    if (smoothCurve) {
      // Draw a smooth curve
      for (int i = 0; i < points.length - 1; i++) {
        final p0 = i > 0 ? points[i - 1] : points[i];
        final p1 = points[i];
        final p2 = points[i + 1];
        final p3 = i < points.length - 2 ? points[i + 2] : p2;

        // Catmull-Rom to Cubic Bezier
        final cp1x = p1.dx + (p2.dx - p0.dx) / 6;
        final cp1y = p1.dy + (p2.dy - p0.dy) / 6;
        final cp2x = p2.dx - (p3.dx - p1.dx) / 6;
        final cp2y = p2.dy - (p3.dy - p1.dy) / 6;

        path.cubicTo(cp1x, cp1y, cp2x, cp2y, p2.dx, p2.dy);
      }
    } else {
      // Draw straight lines
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
    }

    canvas.drawPath(path, linePaint);

    // Draw points
    if (showPoints) {
      final pointPaint = Paint()
        ..color = lineColor
        ..style = PaintingStyle.fill;

      for (var point in points) {
        canvas.drawCircle(point, pointRadius, pointPaint);
      }
    }

    // Draw labels
    if (showLabels) {
      final textPainter = TextPainter(
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );

      // X-axis labels
      for (
        int i = 0;
        i < data.length;
        i += math.max(1, (data.length / 6).round())
      ) {
        final x = i * size.width / (data.length - 1);
        final label = data[i].label;

        textPainter.text = TextSpan(
          text: label,
          style: const TextStyle(color: Colors.black54, fontSize: 10),
        );

        textPainter.layout();

        final offset = Offset(
          x - textPainter.width / 2,
          size.height - textPainter.height,
        );

        textPainter.paint(canvas, offset);
      }

      // Y-axis labels
      for (int i = 0; i <= 4; i++) {
        final y = size.height - (i / 4) * (size.height - padding * 2) - padding;
        final value = maxValue * (i / 4);

        textPainter.text = TextSpan(
          text: i == 0 ? '0' : value.toStringAsFixed(value < 10 ? 1 : 0),
          style: const TextStyle(color: Colors.black54, fontSize: 10),
        );

        textPainter.layout();

        final offset = Offset(0, y - textPainter.height / 2);

        textPainter.paint(canvas, offset);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
