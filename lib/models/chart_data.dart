import 'package:flutter/material.dart';

/// Model class representing data points for charts and reports
class ChartData {
  /// Label for this data point (e.g., month name, category name)
  final String label;

  /// Numeric value of this data point
  final double value;

  /// Pre-formatted string representation of the value (e.g., $123.45)
  final String formattedValue;

  /// Optional color to use when rendering this data point
  final Color color;

  /// Optional count information (e.g., number of invoices)
  final int? count;

  /// Optional percentage value (e.g., for pie charts)
  final double? percentage;

  /// Optional additional data associated with this data point
  final Map<String, dynamic>? additionalData;

  ChartData({
    required this.label,
    required this.value,
    required this.formattedValue,
    required this.color,
    this.count,
    this.percentage,
    this.additionalData,
  });

  /// Create a ChartData instance from a JSON object
  factory ChartData.fromJson(Map<String, dynamic> json, {Color? defaultColor}) {
    return ChartData(
      label: json['label'] ?? '',
      value: (json['value'] ?? 0.0).toDouble(),
      formattedValue: json['formattedValue'] ?? '\$0.00',
      color: defaultColor ?? Colors.blue,
      count: json['count'],
      percentage: json['percentage'] != null
          ? (json['percentage'] as num).toDouble()
          : null,
      additionalData: json['data'],
    );
  }

  /// Convert this ChartData instance to a JSON object
  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'value': value,
      'formattedValue': formattedValue,
      'count': count,
      'percentage': percentage,
      'data': additionalData,
    };
  }
}
