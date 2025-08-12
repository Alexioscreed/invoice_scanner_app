import 'package:flutter/material.dart';
import '../../models/chart_data.dart';

class BarChartWidget extends StatelessWidget {
  final List<ChartData> data;
  final int maxItems;
  final bool showLabels;
  final bool showValues;
  final double barWidth;

  const BarChartWidget({
    Key? key,
    required this.data,
    this.maxItems = 10,
    this.showLabels = false,
    this.showValues = true,
    this.barWidth = 20.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    // Limit the number of items to display
    final displayData = data.length > maxItems
        ? data.sublist(0, maxItems)
        : data;

    // Calculate the maximum value for scaling
    final maxValue = displayData
        .map((e) => e.value)
        .reduce((a, b) => a > b ? a : b);

    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight;
        final width = constraints.maxWidth;
        final itemWidth = width / displayData.length;
        final actualBarWidth = barWidth > itemWidth - 10
            ? itemWidth - 10
            : barWidth;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Container(
            width: displayData.length * itemWidth > width
                ? displayData.length * itemWidth
                : width,
            padding: const EdgeInsets.only(top: 20, bottom: 30),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: displayData.map((item) {
                final barHeight = (item.value / maxValue) * (height - 60);

                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (showValues)
                      Text(
                        item.formattedValue,
                        style: const TextStyle(fontSize: 10),
                      ),
                    const SizedBox(height: 4),
                    Container(
                      width: actualBarWidth,
                      height: barHeight,
                      decoration: BoxDecoration(
                        color: item.color,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    if (showLabels) ...[
                      const SizedBox(height: 8),
                      SizedBox(
                        width: itemWidth - 4,
                        child: Text(
                          item.label,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ],
                  ],
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}
