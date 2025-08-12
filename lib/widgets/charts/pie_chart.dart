import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/chart_data.dart';

class PieChartWidget extends StatelessWidget {
  final List<ChartData> data;
  final bool showLabels;
  final bool showPercentages;
  final bool showLegend;

  const PieChartWidget({
    Key? key,
    required this.data,
    this.showLabels = true,
    this.showPercentages = false,
    this.showLegend = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        // Calculate the size of the pie chart
        final pieChartSize = min(width, height) * 0.7;

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: pieChartSize,
              height: pieChartSize,
              child: CustomPaint(
                painter: _PieChartPainter(
                  data: data,
                  showLabels: showLabels,
                  showPercentages: showPercentages,
                ),
              ),
            ),
            if (showLegend) ...[
              const SizedBox(height: 16),
              _buildLegend(context),
            ],
          ],
        );
      },
    );
  }

  Widget _buildLegend(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: data.map((item) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: item.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(item.label, style: const TextStyle(fontSize: 12)),
          ],
        );
      }).toList(),
    );
  }
}

class _PieChartPainter extends CustomPainter {
  final List<ChartData> data;
  final bool showLabels;
  final bool showPercentages;

  _PieChartPainter({
    required this.data,
    this.showLabels = true,
    this.showPercentages = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Calculate total value
    final total = data.fold(0.0, (sum, item) => sum + item.value);

    // Draw pie segments
    var startAngle = -pi / 2; // Start from the top (12 o'clock)

    for (var item in data) {
      final sweepAngle = 2 * pi * (item.value / total);

      final paint = Paint()
        ..color = item.color
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      // Draw labels if needed
      if (showLabels || showPercentages) {
        final midAngle = startAngle + (sweepAngle / 2);
        final x = center.dx + (radius * 0.7 * cos(midAngle));
        final y = center.dy + (radius * 0.7 * sin(midAngle));

        final textPainter = TextPainter(
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
        );

        String label = '';
        if (showLabels && showPercentages) {
          final percentage = (item.value / total) * 100;
          label = '${percentage.toStringAsFixed(1)}%';
        } else if (showLabels) {
          label = item.label;
        } else if (showPercentages) {
          final percentage = (item.value / total) * 100;
          label = '${percentage.toStringAsFixed(1)}%';
        }

        textPainter.text = TextSpan(
          text: label,
          style: TextStyle(
            color: _isColorDark(item.color) ? Colors.white : Colors.black,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        );

        textPainter.layout();

        final offset = Offset(
          x - textPainter.width / 2,
          y - textPainter.height / 2,
        );

        textPainter.paint(canvas, offset);
      }

      startAngle += sweepAngle;
    }
  }

  bool _isColorDark(Color color) {
    final luminance =
        0.299 * color.red + 0.587 * color.green + 0.114 * color.blue;
    return luminance < 128;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
