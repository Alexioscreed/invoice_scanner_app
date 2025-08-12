import 'package:flutter/material.dart';
import '../../models/chart_data.dart';

class DataTableWidget extends StatelessWidget {
  final List<ChartData> data;
  final List<String> columns;
  final bool showCount;
  final bool showPercentage;
  final String? additionalValueKey;
  final String? additionalFormattedValueKey;

  const DataTableWidget({
    Key? key,
    required this.data,
    required this.columns,
    this.showCount = false,
    this.showPercentage = false,
    this.additionalValueKey,
    this.additionalFormattedValueKey,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: _buildColumns(),
          rows: _buildRows(),
          columnSpacing: 20,
          headingRowColor: MaterialStateProperty.resolveWith<Color>(
            (Set<MaterialState> states) =>
                Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
          ),
          dataRowMinHeight: 48,
          dataRowMaxHeight: 64,
        ),
      ),
    );
  }

  List<DataColumn> _buildColumns() {
    return columns.map((column) {
      return DataColumn(
        label: Text(
          column,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      );
    }).toList();
  }

  List<DataRow> _buildRows() {
    return data.map((item) {
      return DataRow(cells: _buildCells(item));
    }).toList();
  }

  List<DataCell> _buildCells(ChartData item) {
    final cells = <DataCell>[];

    // First column is always the label
    cells.add(DataCell(Text(item.label)));

    // Second column is the value (usually an amount)
    cells.add(DataCell(Text(item.formattedValue)));

    // Third column can be count, percentage, or additional value
    if (columns.length > 2) {
      if (showCount && item.count != null) {
        cells.add(DataCell(Text(item.count.toString())));
      } else if (showPercentage && item.percentage != null) {
        cells.add(DataCell(Text('${item.percentage!.toStringAsFixed(1)}%')));
      } else if (additionalValueKey != null &&
          item.additionalData != null &&
          item.additionalData!.containsKey(additionalValueKey)) {
        final additionalValue = item.additionalData![additionalValueKey];
        final displayValue =
            additionalFormattedValueKey != null &&
                item.additionalData!.containsKey(additionalFormattedValueKey)
            ? item.additionalData![additionalFormattedValueKey]
            : additionalValue.toString();

        cells.add(DataCell(Text(displayValue)));
      } else {
        cells.add(const DataCell(Text('')));
      }
    }

    return cells;
  }
}
