import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/chart_data.dart';
import '../utils/logger.dart';
import 'api_service.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  final ApiService _apiService = ApiService();

  // Cache for analytics data
  Map<String, dynamic> _expenseCache = {};
  Map<String, dynamic> _vendorCache = {};
  Map<String, dynamic> _categoryCache = {};
  Map<String, dynamic> _taxCache = {};

  // Cache expiration duration
  final Duration _cacheDuration = const Duration(minutes: 15);

  // Cache timestamps
  DateTime? _expenseCacheTime;
  DateTime? _vendorCacheTime;
  DateTime? _categoryCacheTime;
  DateTime? _taxCacheTime;

  // Period options for expense summary
  static const List<String> periodOptions = [
    'daily',
    'weekly',
    'monthly',
    'quarterly',
    'yearly',
  ];

  // Get expense summaries by time period
  Future<Map<String, dynamic>> getExpenseSummary({
    required String period, // 'monthly', 'quarterly', 'yearly'
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    // Check if we have valid cached data
    final cacheKey =
        '${period}_${startDate?.toIso8601String()}_${endDate?.toIso8601String()}';
    if (_expenseCache.containsKey(cacheKey) &&
        _expenseCacheTime != null &&
        DateTime.now().difference(_expenseCacheTime!) < _cacheDuration) {
      return _expenseCache[cacheKey];
    }

    try {
      final rawData = await _apiService.getExpenseSummary(
        period: period,
        startDate: startDate,
        endDate: endDate,
      );

      // Process the data to match our expected format
      final processedData = _processExpenseData(rawData, period);

      // Cache the result
      _expenseCache[cacheKey] = processedData;
      _expenseCacheTime = DateTime.now();

      return processedData;
    } catch (e) {
      AppLogger.error(
        'Error getting expense summary: $e',
        context: 'AnalyticsService',
      );
      if (kDebugMode) {
        print('Error getting expense summary: $e');
      }
      return {
        'total': 0.0,
        'averagePerPeriod': 0.0,
        'periodsData': <Map<String, dynamic>>[],
      };
    }
  }

  // Process expense data from the API response
  Map<String, dynamic> _processExpenseData(
    Map<String, dynamic> rawData,
    String period,
  ) {
    final total = (rawData['totalAmount'] ?? 0.0).toDouble();
    final List<dynamic> monthlyData = rawData['monthlyData'] ?? [];
    final List<Map<String, dynamic>> periodsData = [];

    // Each item in monthlyData is [year, month, amount]
    for (var item in monthlyData) {
      if (item.length < 3) continue;

      int year = item[0] is int ? item[0] : 0;
      int month = item[1] is int ? item[1] : 0;
      double amount = item[2] is num ? (item[2] as num).toDouble() : 0.0;

      String label;
      switch (period) {
        case 'monthly':
          label = DateFormat('MMM yyyy').format(DateTime(year, month));
          break;
        case 'quarterly':
          int quarter = ((month - 1) ~/ 3) + 1;
          label = 'Q$quarter $year';
          break;
        case 'yearly':
          label = year.toString();
          break;
        default:
          label = DateFormat('MMM yyyy').format(DateTime(year, month));
      }

      // Add or update period data
      bool found = false;
      for (var periodData in periodsData) {
        if (periodData['label'] == label) {
          periodData['amount'] = (periodData['amount'] ?? 0.0) + amount;
          found = true;
          break;
        }
      }

      if (!found) {
        periodsData.add({'label': label, 'amount': amount});
      }
    }

    // Calculate average
    double averagePerPeriod = periodsData.isEmpty
        ? 0.0
        : total / periodsData.length;

    return {
      'total': total,
      'averagePerPeriod': averagePerPeriod,
      'periodsData': periodsData,
    };
  }

  // Convert expense summary data to ChartData objects
  Future<List<ChartData>> getExpenseChartData({
    required String period,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final data = await getExpenseSummary(
        period: period,
        startDate: startDate,
        endDate: endDate,
      );

      final List<ChartData> chartData = [];
      final formatter = NumberFormat.currency(symbol: '\$');

      if (data.containsKey('periodsData')) {
        final List<dynamic> periodsData = data['periodsData'];

        for (var item in periodsData) {
          chartData.add(
            ChartData(
              label: item['label'] ?? '',
              value: (item['amount'] ?? 0.0).toDouble(),
              formattedValue: formatter.format(
                (item['amount'] ?? 0.0).toDouble(),
              ),
              color: _getChartColor(chartData.length),
              count: item['count'],
            ),
          );
        }
      }

      return chartData;
    } catch (e) {
      AppLogger.error(
        'Error converting expense data to chart format: $e',
        context: 'AnalyticsService',
      );
      return [];
    }
  }

  // Get vendor analysis data
  Future<List<VendorAnalysis>> getVendorAnalysis({
    DateTime? startDate,
    DateTime? endDate,
    int limit = 10,
  }) async {
    // Check if we have valid cached data
    final cacheKey =
        'vendors_${startDate?.toIso8601String()}_${endDate?.toIso8601String()}_$limit';
    if (_vendorCache.containsKey(cacheKey) &&
        _vendorCacheTime != null &&
        DateTime.now().difference(_vendorCacheTime!) < _cacheDuration) {
      return _parseVendorData(_vendorCache[cacheKey]);
    }

    try {
      final data = await _apiService.getVendorAnalysis(
        startDate: startDate,
        endDate: endDate,
        limit: limit,
      );

      // Cache the result
      _vendorCache[cacheKey] = data;
      _vendorCacheTime = DateTime.now();

      // Parse the response
      return _parseVendorData(data);
    } catch (e) {
      AppLogger.error(
        'Error getting vendor analysis: $e',
        context: 'AnalyticsService',
      );
      if (kDebugMode) {
        print('Error getting vendor analysis: $e');
      }
      return [];
    }
  }

  // Parse vendor data from API response
  List<VendorAnalysis> _parseVendorData(Map<String, dynamic> data) {
    List<VendorAnalysis> results = [];
    if (data.containsKey('vendorSpending')) {
      for (var item in data['vendorSpending']) {
        // Backend returns [vendorName, amount] arrays
        results.add(
          VendorAnalysis(
            vendorName: item[0]?.toString() ?? 'Unknown',
            totalSpent: item[1] is num ? (item[1] as num).toDouble() : 0.0,
            invoiceCount: 1, // Not provided by backend
            averageAmount: item[1] is num
                ? (item[1] as num).toDouble()
                : 0.0, // Same as totalSpent
          ),
        );
      }
    }
    return results;
  }

  // Convert vendor analysis to chart data
  Future<List<ChartData>> getVendorChartData({
    DateTime? startDate,
    DateTime? endDate,
    int limit = 10,
  }) async {
    try {
      final vendors = await getVendorAnalysis(
        startDate: startDate,
        endDate: endDate,
        limit: limit,
      );

      final List<ChartData> chartData = [];
      final formatter = NumberFormat.currency(symbol: '\$');

      for (int i = 0; i < vendors.length; i++) {
        final vendor = vendors[i];
        chartData.add(
          ChartData(
            label: vendor.vendorName,
            value: vendor.totalSpent,
            formattedValue: formatter.format(vendor.totalSpent),
            color: _getChartColor(i),
            count: vendor.invoiceCount,
            additionalData: {
              'averageAmount': vendor.averageAmount,
              'topCategory': vendor.topCategory,
            },
          ),
        );
      }

      return chartData;
    } catch (e) {
      AppLogger.error(
        'Error converting vendor data to chart format: $e',
        context: 'AnalyticsService',
      );
      return [];
    }
  }

  // Get category reports
  Future<List<CategoryAnalysis>> getCategoryAnalysis({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    // Check if we have valid cached data
    final cacheKey =
        'categories_${startDate?.toIso8601String()}_${endDate?.toIso8601String()}';
    if (_categoryCache.containsKey(cacheKey) &&
        _categoryCacheTime != null &&
        DateTime.now().difference(_categoryCacheTime!) < _cacheDuration) {
      return _parseCategoryData(_categoryCache[cacheKey]);
    }

    try {
      final data = await _apiService.getCategoryAnalysis(
        startDate: startDate,
        endDate: endDate,
      );

      // Cache the result
      _categoryCache[cacheKey] = data;
      _categoryCacheTime = DateTime.now();

      // Parse the response
      return _parseCategoryData(data);
    } catch (e) {
      AppLogger.error(
        'Error getting category analysis: $e',
        context: 'AnalyticsService',
      );
      if (kDebugMode) {
        print('Error getting category analysis: $e');
      }
      return [];
    }
  }

  // Parse category data from API response
  List<CategoryAnalysis> _parseCategoryData(Map<String, dynamic> data) {
    List<CategoryAnalysis> results = [];
    // Backend returns categorySpending as a list of [category, amount] arrays
    if (data.containsKey('categorySpending')) {
      // Calculate total for percentage
      double total = 0;
      for (var item in data['categorySpending']) {
        if (item[1] is num) {
          total += (item[1] as num).toDouble();
        }
      }

      // Create category analysis objects
      for (var item in data['categorySpending']) {
        double amount = item[1] is num ? (item[1] as num).toDouble() : 0.0;
        double percentage = total > 0 ? (amount / total) * 100 : 0.0;

        results.add(
          CategoryAnalysis(
            category: item[0]?.toString() ?? 'Uncategorized',
            totalAmount: amount,
            invoiceCount: 1, // Not provided by backend
            percentage: percentage,
          ),
        );
      }
    }
    return results;
  }

  // Convert category analysis to chart data
  Future<List<ChartData>> getCategoryChartData({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final categories = await getCategoryAnalysis(
        startDate: startDate,
        endDate: endDate,
      );

      final List<ChartData> chartData = [];
      final formatter = NumberFormat.currency(symbol: '\$');

      for (int i = 0; i < categories.length; i++) {
        final category = categories[i];
        chartData.add(
          ChartData(
            label: category.category,
            value: category.totalAmount,
            formattedValue: formatter.format(category.totalAmount),
            color: _getChartColor(i),
            count: category.invoiceCount,
            percentage: category.percentage,
          ),
        );
      }

      return chartData;
    } catch (e) {
      AppLogger.error(
        'Error converting category data to chart format: $e',
        context: 'AnalyticsService',
      );
      return [];
    }
  }

  // Get tax reporting data
  Future<TaxReport> getTaxReport({required int year, String? quarter}) async {
    // Check if we have valid cached data
    final cacheKey = 'tax_${year}_$quarter';
    if (_taxCache.containsKey(cacheKey) &&
        _taxCacheTime != null &&
        DateTime.now().difference(_taxCacheTime!) < _cacheDuration) {
      return TaxReport.fromJson(_taxCache[cacheKey]);
    }

    try {
      final data = await _apiService.getTaxReport(year: year, quarter: quarter);

      // Cache the result
      _taxCache[cacheKey] = data;
      _taxCacheTime = DateTime.now();

      return TaxReport.fromJson(data);
    } catch (e) {
      AppLogger.error(
        'Error getting tax report: $e',
        context: 'AnalyticsService',
      );
      if (kDebugMode) {
        // Error already logged through AppLogger above
      }
      return TaxReport(totalTaxable: 0.0, totalTaxPaid: 0.0, items: []);
    }
  }

  // Convert tax report data to chart data for visualization
  Future<List<ChartData>> getTaxChartData({
    required int year,
    String? quarter,
  }) async {
    try {
      final taxReport = await getTaxReport(year: year, quarter: quarter);
      final List<ChartData> chartData = [];
      final formatter = NumberFormat.currency(symbol: '\$');

      for (int i = 0; i < taxReport.items.length; i++) {
        final item = taxReport.items[i];
        chartData.add(
          ChartData(
            label: item.category,
            value: item.taxableAmount,
            formattedValue: formatter.format(item.taxableAmount),
            color: _getChartColor(i),
            additionalData: {
              'taxPaid': item.taxPaid,
              'taxPaidFormatted': formatter.format(item.taxPaid),
            },
          ),
        );
      }

      return chartData;
    } catch (e) {
      AppLogger.error(
        'Error converting tax data to chart format: $e',
        context: 'AnalyticsService',
      );
      return [];
    }
  }

  // Get available years for reporting
  Future<List<int>> getAvailableYears() async {
    try {
      // We can use the invoice service endpoint for this
      final data = await _apiService.getAnalytics();

      if (data.containsKey('availableYears')) {
        return List<int>.from(data['availableYears']);
      }

      // If not available, return current and previous years
      final currentYear = DateTime.now().year;
      return [currentYear, currentYear - 1, currentYear - 2];
    } catch (e) {
      AppLogger.error(
        'Error getting available years: $e',
        context: 'AnalyticsService',
      );

      // Fallback to current year only
      return [DateTime.now().year];
    }
  }

  // Get a color for chart items based on index
  Color _getChartColor(int index) {
    final List<Color> chartColors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.amber,
      Colors.cyan,
      Colors.indigo,
      Colors.deepPurple,
    ];

    return chartColors[index % chartColors.length];
  }

  // Clear all cached data
  void clearCache() {
    _expenseCache.clear();
    _vendorCache.clear();
    _categoryCache.clear();
    _taxCache.clear();

    _expenseCacheTime = null;
    _vendorCacheTime = null;
    _categoryCacheTime = null;
    _taxCacheTime = null;

    AppLogger.info('Analytics cache cleared', context: 'AnalyticsService');
  }
}

// Model classes for analytics data

class VendorAnalysis {
  final String vendorName;
  final double totalSpent;
  final int invoiceCount;
  final double averageAmount;
  final String? topCategory;

  VendorAnalysis({
    required this.vendorName,
    required this.totalSpent,
    required this.invoiceCount,
    required this.averageAmount,
    this.topCategory,
  });

  factory VendorAnalysis.fromJson(Map<String, dynamic> json) {
    return VendorAnalysis(
      vendorName: json['vendorName'] ?? '',
      totalSpent: (json['totalSpent'] ?? 0.0).toDouble(),
      invoiceCount: json['invoiceCount'] ?? 0,
      averageAmount: (json['averageAmount'] ?? 0.0).toDouble(),
      topCategory: json['topCategory'],
    );
  }
}

class CategoryAnalysis {
  final String category;
  final double totalAmount;
  final int invoiceCount;
  final double percentage;

  CategoryAnalysis({
    required this.category,
    required this.totalAmount,
    required this.invoiceCount,
    required this.percentage,
  });

  factory CategoryAnalysis.fromJson(Map<String, dynamic> json) {
    return CategoryAnalysis(
      category: json['category'] ?? 'Uncategorized',
      totalAmount: (json['totalAmount'] ?? 0.0).toDouble(),
      invoiceCount: json['invoiceCount'] ?? 0,
      percentage: (json['percentage'] ?? 0.0).toDouble(),
    );
  }
}

class TaxReportItem {
  final String category;
  final double taxableAmount;
  final double taxPaid;

  TaxReportItem({
    required this.category,
    required this.taxableAmount,
    required this.taxPaid,
  });

  factory TaxReportItem.fromJson(Map<String, dynamic> json) {
    return TaxReportItem(
      category: json['category'] ?? 'Uncategorized',
      taxableAmount: (json['taxableAmount'] ?? 0.0).toDouble(),
      taxPaid: (json['taxPaid'] ?? 0.0).toDouble(),
    );
  }
}

class TaxReport {
  final double totalTaxable;
  final double totalTaxPaid;
  final List<TaxReportItem> items;

  TaxReport({
    required this.totalTaxable,
    required this.totalTaxPaid,
    required this.items,
  });

  factory TaxReport.fromJson(Map<String, dynamic> json) {
    List<TaxReportItem> items = [];
    if (json['items'] != null) {
      for (var item in json['items']) {
        items.add(TaxReportItem.fromJson(item));
      }
    }

    return TaxReport(
      totalTaxable: (json['totalTaxable'] ?? 0.0).toDouble(),
      totalTaxPaid: (json['totalTaxPaid'] ?? 0.0).toDouble(),
      items: items,
    );
  }
}
