import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../providers/analytics_provider.dart';
import '../widgets/charts/bar_chart.dart';
import '../widgets/charts/pie_chart.dart';
import '../widgets/charts/line_chart.dart';
import '../widgets/charts/data_table_widget.dart';
import '../widgets/common/loading_indicator.dart';
import '../widgets/common/error_message.dart';

class ReportingScreen extends StatefulWidget {
  static const routeName = '/reporting';

  const ReportingScreen({Key? key}) : super(key: key);

  @override
  _ReportingScreenState createState() => _ReportingScreenState();
}

class _ReportingScreenState extends State<ReportingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTimeRange? _selectedDateRange;
  final DateFormat _dateFormat = DateFormat('MMM dd, yyyy');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // Initialize date range to last 3 months
    final now = DateTime.now();
    _selectedDateRange = DateTimeRange(
      start: DateTime(now.year, now.month - 3, now.day),
      end: now,
    );

    // Initialize the provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<AnalyticsProvider>(context, listen: false);
      provider.setDateRange(_selectedDateRange?.start, _selectedDateRange?.end);
      provider.init().then((_) {
        _loadTabData(0); // Load data for the first tab
      });
    });

    // Listen to tab changes
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        return;
      }
      _loadTabData(_tabController.index);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Load data for the selected tab
  void _loadTabData(int tabIndex) {
    final provider = Provider.of<AnalyticsProvider>(context, listen: false);

    switch (tabIndex) {
      case 0: // Expense Summary
        provider.loadExpenseData();
        break;
      case 1: // Vendor Analysis
        provider.loadVendorData();
        break;
      case 2: // Category Analysis
        provider.loadCategoryData();
        break;
      case 3: // Tax Reporting
        provider.loadTaxData();
        break;
    }
  }

  // Show date picker
  Future<void> _selectDateRange() async {
    final initialDateRange =
        _selectedDateRange ??
        DateTimeRange(
          start: DateTime.now().subtract(const Duration(days: 30)),
          end: DateTime.now(),
        );

    final pickedDateRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(DateTime.now().year - 5),
      lastDate: DateTime.now(),
      initialDateRange: initialDateRange,
      saveText: 'Apply',
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
              onPrimary: Colors.white,
              onSurface:
                  Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDateRange != null) {
      setState(() {
        _selectedDateRange = pickedDateRange;
      });

      // Update provider
      final provider = Provider.of<AnalyticsProvider>(context, listen: false);
      provider.setDateRange(pickedDateRange.start, pickedDateRange.end);

      // Reload data for the current tab
      _loadTabData(_tabController.index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Data',
            onPressed: () {
              final provider = Provider.of<AnalyticsProvider>(
                context,
                listen: false,
              );
              provider.refreshData();
            },
          ),
          IconButton(
            icon: const Icon(Icons.date_range),
            tooltip: 'Select Date Range',
            onPressed: _selectDateRange,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Expense Summary'),
            Tab(text: 'Vendor Analysis'),
            Tab(text: 'Category Analysis'),
            Tab(text: 'Tax Reporting'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Date range display
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.calendar_today, size: 16),
                const SizedBox(width: 8),
                Text(
                  _selectedDateRange != null
                      ? '${_dateFormat.format(_selectedDateRange!.start)} - ${_dateFormat.format(_selectedDateRange!.end)}'
                      : 'All Time',
                  style: themeData.textTheme.bodyMedium,
                ),
              ],
            ),
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildExpenseSummary(),
                _buildVendorAnalysis(),
                _buildCategoryAnalysis(),
                _buildTaxReporting(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Build expense summary tab
  Widget _buildExpenseSummary() {
    return Consumer<AnalyticsProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const LoadingIndicator(message: 'Loading expense summary...');
        }

        if (provider.error != null) {
          return ErrorMessage(
            message: provider.error!,
            onRetry: () => provider.loadExpenseData(),
          );
        }

        if (provider.expenseData.isEmpty) {
          return const Center(
            child: Text('No expense data available for the selected period.'),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Period selector
              _buildPeriodSelector(provider),
              const SizedBox(height: 16),

              // Line chart
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Expenses Over Time',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 250,
                        child: LineChartWidget(data: provider.expenseData),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Data table
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Expense Summary',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      DataTableWidget(
                        data: provider.expenseData,
                        columns: const ['Period', 'Amount'],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Build vendor analysis tab
  Widget _buildVendorAnalysis() {
    return Consumer<AnalyticsProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const LoadingIndicator(message: 'Loading vendor analysis...');
        }

        if (provider.error != null) {
          return ErrorMessage(
            message: provider.error!,
            onRetry: () => provider.loadVendorData(),
          );
        }

        if (provider.vendorData.isEmpty) {
          return const Center(
            child: Text('No vendor data available for the selected period.'),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bar chart
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Top Vendors by Spend',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 300,
                        child: BarChartWidget(
                          data: provider.vendorData,
                          maxItems: 10,
                          showLabels: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Data table
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Vendor Details',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      DataTableWidget(
                        data: provider.vendorData,
                        columns: const ['Vendor', 'Amount', 'Invoices'],
                        showCount: true,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Build category analysis tab
  Widget _buildCategoryAnalysis() {
    return Consumer<AnalyticsProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const LoadingIndicator(
            message: 'Loading category analysis...',
          );
        }

        if (provider.error != null) {
          return ErrorMessage(
            message: provider.error!,
            onRetry: () => provider.loadCategoryData(),
          );
        }

        if (provider.categoryData.isEmpty) {
          return const Center(
            child: Text('No category data available for the selected period.'),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pie chart
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Expense Distribution by Category',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 300,
                        child: PieChartWidget(
                          data: provider.categoryData,
                          showLabels: true,
                          showPercentages: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Data table
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Category Details',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      DataTableWidget(
                        data: provider.categoryData,
                        columns: const ['Category', 'Amount', 'Percentage'],
                        showPercentage: true,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Build tax reporting tab
  Widget _buildTaxReporting() {
    return Consumer<AnalyticsProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const LoadingIndicator(message: 'Loading tax report...');
        }

        if (provider.error != null) {
          return ErrorMessage(
            message: provider.error!,
            onRetry: () => provider.loadTaxData(),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Year and quarter selector
              _buildTaxPeriodSelector(provider),
              const SizedBox(height: 16),

              if (provider.taxData.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text(
                      'No tax data available for the selected period.',
                    ),
                  ),
                )
              else
                Column(
                  children: [
                    // Bar chart
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Taxable Expenses by Category',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 300,
                              child: BarChartWidget(
                                data: provider.taxData,
                                showLabels: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Data table
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tax Report Details',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            DataTableWidget(
                              data: provider.taxData,
                              columns: const [
                                'Category',
                                'Taxable Amount',
                                'Tax Paid',
                              ],
                              additionalValueKey: 'taxPaid',
                              additionalFormattedValueKey: 'taxPaidFormatted',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  // Build period selector for expense summary
  Widget _buildPeriodSelector(AnalyticsProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Period', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: provider.periodOptions.map((period) {
                  final isSelected = provider.selectedPeriod == period;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(_capitalizeFirstLetter(period)),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          provider.setPeriod(period);
                          provider.loadExpenseData();
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build year and quarter selector for tax reporting
  Widget _buildTaxPeriodSelector(AnalyticsProvider provider) {
    final quarters = ['Q1', 'Q2', 'Q3', 'Q4', 'All'];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tax Period', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    decoration: const InputDecoration(
                      labelText: 'Year',
                      border: OutlineInputBorder(),
                    ),
                    value: provider.selectedYear,
                    items: provider.availableYears.map((year) {
                      return DropdownMenuItem<int>(
                        value: year,
                        child: Text(year.toString()),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        provider.setYear(value);
                        provider.loadTaxData();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    decoration: const InputDecoration(
                      labelText: 'Quarter',
                      border: OutlineInputBorder(),
                    ),
                    value: provider.selectedQuarter ?? 'All',
                    items: quarters.map((quarter) {
                      return DropdownMenuItem<String?>(
                        value: quarter == 'All' ? null : quarter,
                        child: Text(quarter),
                      );
                    }).toList(),
                    onChanged: (value) {
                      provider.setQuarter(value == 'All' ? null : value);
                      provider.loadTaxData();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _capitalizeFirstLetter(String text) {
    if (text.isEmpty) return '';
    return text[0].toUpperCase() + text.substring(1);
  }
}
