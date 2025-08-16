import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/invoice_provider.dart';
import '../utils/date_formatter.dart';

class InvoiceListScreen extends StatefulWidget {
  const InvoiceListScreen({super.key});

  @override
  State<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends State<InvoiceListScreen> {
  String _searchQuery = '';
  String _filterCategory = 'All';
  String _sortBy = 'Date';
  bool _isAscending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshInvoices();
    });
  }

  Future<void> _refreshInvoices() async {
    await Provider.of<InvoiceProvider>(context, listen: false).loadInvoices();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoices'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              _showSearchDialog();
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              _showFilterDialog();
            },
          ),
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: () {
              _showSortDialog();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshInvoices,
        child: Consumer<InvoiceProvider>(
          builder: (context, invoiceProvider, child) {
            final invoices = invoiceProvider.getFilteredInvoices(
              searchQuery: _searchQuery,
              category: _filterCategory == 'All' ? null : _filterCategory,
            );

            if (invoices.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.receipt_long, size: 70, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    const Text(
                      'No invoices found',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('Add your first invoice to get started'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        context.go('/add-invoice');
                      },
                      child: const Text('Add Invoice'),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              itemCount: invoices.length,
              padding: const EdgeInsets.all(12),
              itemBuilder: (context, index) {
                final invoice = invoices[index];

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    onTap: () {
                      if (invoice.id != null) {
                        context.go('/invoice-detail/${invoice.id}');
                      }
                    },
                    leading: CircleAvatar(
                      backgroundColor: _getStatusColor(invoice.status),
                      child: Text(
                        invoice.vendorName.isNotEmpty
                            ? invoice.vendorName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(
                      invoice.vendorName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text('Invoice #: ${invoice.invoiceNumber}'),
                        const SizedBox(height: 2),
                        Text(
                          'Date: ${DateFormatter.formatDate(invoice.invoiceDate)}',
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Status: ${invoice.status.toUpperCase()}',
                          style: TextStyle(
                            color: _getStatusColor(invoice.status),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '\$${invoice.totalAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          invoice.category ?? 'Uncategorized',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.go('/add-invoice');
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'overdue':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String tempQuery = _searchQuery;
        return AlertDialog(
          title: const Text('Search Invoices'),
          content: TextField(
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Enter vendor name or invoice number',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (value) {
              tempQuery = value;
            },
            controller: TextEditingController(text: _searchQuery),
          ),
          actions: [
            TextButton(
              child: const Text('CANCEL'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('SEARCH'),
              onPressed: () {
                setState(() {
                  _searchQuery = tempQuery;
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String tempCategory = _filterCategory;
        return AlertDialog(
          title: const Text('Filter by Category'),
          content: Consumer<InvoiceProvider>(
            builder: (context, invoiceProvider, child) {
              final categories = ['All', ...invoiceProvider.getCategories()];
              return SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    return RadioListTile<String>(
                      title: Text(category),
                      value: category,
                      groupValue: tempCategory,
                      onChanged: (value) {
                        tempCategory = value!;
                      },
                    );
                  },
                ),
              );
            },
          ),
          actions: [
            TextButton(
              child: const Text('CANCEL'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('APPLY'),
              onPressed: () {
                setState(() {
                  _filterCategory = tempCategory;
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String tempSortBy = _sortBy;
        bool tempIsAscending = _isAscending;
        return AlertDialog(
          title: const Text('Sort By'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: const Text('Date'),
                value: 'Date',
                groupValue: tempSortBy,
                onChanged: (value) {
                  tempSortBy = value!;
                },
              ),
              RadioListTile<String>(
                title: const Text('Amount'),
                value: 'Amount',
                groupValue: tempSortBy,
                onChanged: (value) {
                  tempSortBy = value!;
                },
              ),
              RadioListTile<String>(
                title: const Text('Vendor'),
                value: 'Vendor',
                groupValue: tempSortBy,
                onChanged: (value) {
                  tempSortBy = value!;
                },
              ),
              const Divider(),
              CheckboxListTile(
                title: const Text('Ascending Order'),
                value: tempIsAscending,
                onChanged: (value) {
                  tempIsAscending = value!;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('CANCEL'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('APPLY'),
              onPressed: () {
                setState(() {
                  _sortBy = tempSortBy;
                  _isAscending = tempIsAscending;
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
