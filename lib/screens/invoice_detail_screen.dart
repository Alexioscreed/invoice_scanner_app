import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/invoice.dart';
import '../providers/invoice_provider.dart';

class InvoiceDetailScreen extends StatefulWidget {
  final Invoice invoice;

  const InvoiceDetailScreen({super.key, required this.invoice});

  @override
  State<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen> {
  late Invoice _invoice;
  bool _isEditing = false;
  final _formKey = GlobalKey<FormState>();
  final _invoiceNumberController = TextEditingController();
  final _vendorController = TextEditingController();
  final _totalAmountController = TextEditingController();
  final _notesController = TextEditingController();
  String _selectedStatus = 'PENDING';
  String _selectedCategory = 'GENERAL';
  DateTime? _invoiceDate;
  DateTime? _dueDate;

  @override
  void initState() {
    super.initState();
    _invoice = widget.invoice;
    _initializeControllers();
  }

  void _initializeControllers() {
    _invoiceNumberController.text = _invoice.invoiceNumber;
    _vendorController.text = _invoice.vendorName;
    _totalAmountController.text = _invoice.totalAmount.toString();
    _notesController.text = _invoice.notes ?? '';
    _selectedStatus = _invoice.status;
    _selectedCategory = _invoice.category ?? 'GENERAL';
    _invoiceDate = _invoice.invoiceDate;
    _dueDate = _invoice.dueDate;
  }

  @override
  void dispose() {
    _invoiceNumberController.dispose();
    _vendorController.dispose();
    _totalAmountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Invoice' : 'Invoice Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            ),
          if (_isEditing) ...[
            IconButton(icon: const Icon(Icons.check), onPressed: _saveInvoice),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => setState(() {
                _isEditing = false;
                _initializeControllers();
              }),
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInvoiceHeader(),
              const SizedBox(height: 24),
              _buildInvoiceDetails(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInvoiceHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Invoice ${_invoice.invoiceNumber}',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                _buildStatusChip(_selectedStatus),
              ],
            ),
            const SizedBox(height: 16),
            if (_isEditing) ...[
              TextFormField(
                controller: _invoiceNumberController,
                decoration: const InputDecoration(
                  labelText: 'Invoice Number',
                  prefixIcon: Icon(Icons.receipt),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Invoice number is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _vendorController,
                decoration: const InputDecoration(
                  labelText: 'Vendor',
                  prefixIcon: Icon(Icons.business),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Vendor is required';
                  }
                  return null;
                },
              ),
            ] else ...[
              _buildDetailRow('Vendor', _invoice.vendorName, Icons.business),
              _buildDetailRow(
                'Amount',
                '\$${_invoice.totalAmount.toStringAsFixed(2)}',
                Icons.attach_money,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceDetails() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Invoice Details',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            if (_isEditing) ...[
              TextFormField(
                controller: _totalAmountController,
                decoration: const InputDecoration(
                  labelText: 'Total Amount',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Total amount is required';
                  }
                  if (double.tryParse(value!) == null) {
                    return 'Please enter a valid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedStatus,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  prefixIcon: Icon(Icons.info),
                ),
                items: ['PENDING', 'PAID', 'OVERDUE', 'CANCELLED']
                    .map(
                      (status) =>
                          DropdownMenuItem(value: status, child: Text(status)),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _selectedStatus = value!),
              ),
            ] else ...[
              _buildDetailRow(
                'Category',
                _invoice.category ?? 'N/A',
                Icons.category,
              ),
              _buildDetailRow(
                'Invoice Date',
                '${_invoice.invoiceDate.day}/${_invoice.invoiceDate.month}/${_invoice.invoiceDate.year}',
                Icons.calendar_today,
              ),
              _buildDetailRow(
                'Due Date',
                _invoice.dueDate != null
                    ? '${_invoice.dueDate!.day}/${_invoice.dueDate!.month}/${_invoice.dueDate!.year}'
                    : 'N/A',
                Icons.event,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text('$label:', style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'PAID':
        color = Colors.green;
        break;
      case 'OVERDUE':
        color = Colors.red;
        break;
      case 'CANCELLED':
        color = Colors.grey;
        break;
      default:
        color = Colors.orange;
    }

    return Chip(
      label: Text(status, style: const TextStyle(color: Colors.white)),
      backgroundColor: color,
    );
  }

  Future<void> _saveInvoice() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final updatedInvoice = Invoice(
        id: _invoice.id,
        invoiceNumber: _invoiceNumberController.text,
        vendorName: _vendorController.text,
        totalAmount: double.parse(_totalAmountController.text),
        status: _selectedStatus,
        category: _selectedCategory,
        invoiceDate: _invoiceDate!,
        dueDate: _dueDate,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        lineItems: _invoice.lineItems,
        filePath: _invoice.filePath,
        createdAt: _invoice.createdAt,
        updatedAt: DateTime.now(),
      );

      final invoiceProvider = Provider.of<InvoiceProvider>(
        context,
        listen: false,
      );
      await invoiceProvider.updateInvoice(updatedInvoice);

      setState(() {
        _invoice = updatedInvoice;
        _isEditing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invoice updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update invoice: $e')));
      }
    }
  }
}
