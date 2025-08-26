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

class _InvoiceListScreenState extends State<InvoiceListScreen> with RouteAware {
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh invoices when returning to this screen
    _refreshInvoices();
  }

  Future<void> _refreshInvoices() async {
    final invoiceProvider = Provider.of<InvoiceProvider>(
      context,
      listen: false,
    );
    await invoiceProvider.loadInvoices();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Tailwind slate-50
      appBar: AppBar(
        title: const Text(
          'Invoices',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B), // Tailwind slate-800
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        shadowColor: const Color(0xFF64748B).withOpacity(0.1),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Color(0xFF3B82F6), // Tailwind blue-500
          ),
          onPressed: () {
            // Navigate back to dashboard/home instead of just popping
            if (GoRouter.of(context).canPop()) {
              context.pop();
            } else {
              context.go('/dashboard');
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.search,
              color: Color(0xFF3B82F6), // Tailwind blue-500
            ),
            onPressed: () {
              _showSearchDialog();
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.filter_list,
              color: Color(0xFF3B82F6), // Tailwind blue-500
            ),
            onPressed: () {
              _showFilterDialog();
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.sort,
              color: Color(0xFF3B82F6), // Tailwind blue-500
            ),
            onPressed: () {
              _showSortDialog();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshInvoices,
        color: const Color(0xFF3B82F6), // Tailwind blue-500
        child: Consumer<InvoiceProvider>(
          builder: (context, invoiceProvider, child) {
            // Show loading state
            if (invoiceProvider.isLoading) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF3B82F6), // Tailwind blue-500
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Loading invoices...',
                      style: TextStyle(
                        color: Color(0xFF64748B), // Tailwind slate-500
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              );
            }

            // Show error state
            if (invoiceProvider.error != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2), // Tailwind red-50
                        borderRadius: BorderRadius.circular(60),
                      ),
                      child: const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Color(0xFFEF4444), // Tailwind red-500
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Failed to load invoices',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B), // Tailwind slate-800
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      invoiceProvider.error!,
                      style: const TextStyle(
                        color: Color(0xFF64748B), // Tailwind slate-500
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _refreshInvoices,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(
                          0xFF3B82F6,
                        ), // Tailwind blue-500
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            final invoices = invoiceProvider.getFilteredInvoices(
              searchQuery: _searchQuery,
              category: _filterCategory == 'All' ? null : _filterCategory,
            );

            if (invoices.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF), // Tailwind blue-50
                        borderRadius: BorderRadius.circular(60),
                      ),
                      child: const Icon(
                        Icons.receipt_long,
                        size: 60,
                        color: Color(0xFF3B82F6), // Tailwind blue-500
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'No invoices found',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B), // Tailwind slate-800
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Add your first invoice to get started',
                      style: TextStyle(
                        color: Color(0xFF64748B), // Tailwind slate-500
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF3B82F6), // Tailwind blue-500
                            Color(0xFF1D4ED8), // Tailwind blue-700
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF3B82F6).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () async {
                          final result = await context.push('/add-invoice');
                          if (result == true) {
                            // Rebuild to show provider's updated list without forcing
                            // a full reload which may overwrite local changes.
                            setState(() {});
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Add Invoice',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
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
                    onTap: () async {
                      if (invoice.id != null) {
                        final result = await context.push('/invoice-detail/${invoice.id}');
                        if (result == true) {
                          // Rebuild to show provider's updated list without forcing reload
                          setState(() {});
                        }
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
                    subtitle: Flexible( // Added Flexible widget
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text('Invoice #: ${invoice.invoiceNumber}'),
                          const SizedBox(height: 2),
                          Text('Date: ${DateFormatter.formatDate(invoice.invoiceDate)}'),
                          const SizedBox(height: 2),
                          Text(
                            'Status: ${invoice.status.toUpperCase()}',
                            style: TextStyle(
                              color: _getStatusColor(invoice.status),
                              fontWeight: FontWeight.w600,
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
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min, // Added to prevent overflow
                      children: [
                        Text(invoice.formattedAmount,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 16)),
                        Flexible( // Wrapped IconButton in Flexible to prevent overflow
                          child: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
                            tooltip: 'Delete invoice',
                            padding: EdgeInsets.zero, // Reduced padding to save space
                            constraints: const BoxConstraints(minHeight: 32, minWidth: 32), // Smaller constraints
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Delete invoice'),
                                  content: const Text('Are you sure you want to delete this invoice? This action cannot be undone.'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(true),
                                      child: const Text('Delete', style: TextStyle(color: Color(0xFFEF4444))),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true) {
                                final invoiceProvider = Provider.of<InvoiceProvider>(context, listen: false);
                                final idStr = invoice.id?.toString();
                                if (idStr == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cannot delete invoice without ID')));
                                  return;
                                }
                                final success = await invoiceProvider.deleteInvoice(idStr);
                                if (success) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invoice deleted')));
                                  // refresh list
                                  setState(() {});
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(invoiceProvider.error ?? 'Failed to delete invoice')));
                                }
                              }
                            },
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
          context.push('/add-invoice');
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

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: const Text(
                'Sort By',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B), // Tailwind slate-800
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<String>(
                    title: const Text('Date'),
                    value: 'Date',
                    groupValue: tempSortBy,
                    activeColor: const Color(0xFF3B82F6), // Tailwind blue-500
                    onChanged: (value) {
                      setDialogState(() {
                        tempSortBy = value!;
                      });
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('Amount'),
                    value: 'Amount',
                    groupValue: tempSortBy,
                    activeColor: const Color(0xFF3B82F6), // Tailwind blue-500
                    onChanged: (value) {
                      setDialogState(() {
                        tempSortBy = value!;
                      });
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('Vendor'),
                    value: 'Vendor',
                    groupValue: tempSortBy,
                    activeColor: const Color(0xFF3B82F6), // Tailwind blue-500
                    onChanged: (value) {
                      setDialogState(() {
                        tempSortBy = value!;
                      });
                    },
                  ),
                  const Divider(color: Color(0xFFE2E8F0)), // Tailwind slate-200
                  CheckboxListTile(
                    title: const Text('Ascending Order'),
                    value: tempIsAscending,
                    activeColor: const Color(0xFF3B82F6), // Tailwind blue-500
                    onChanged: (value) {
                      setDialogState(() {
                        tempIsAscending = value ?? false;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  child: const Text(
                    'CANCEL',
                    style: TextStyle(
                      color: Color(0xFF64748B), // Tailwind slate-500
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(
                      0xFF3B82F6,
                    ), // Tailwind blue-500
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('APPLY'),
                  onPressed: () {
                    setState(() {
                      _sortBy = tempSortBy;
                      _isAscending = tempIsAscending;
                    });
                    Navigator.of(context).pop();
                    // Refresh the list with new sorting
                    _refreshInvoices();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
}
