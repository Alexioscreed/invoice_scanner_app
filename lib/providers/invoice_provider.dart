import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/invoice.dart';
import '../services/invoice_service.dart';

class InvoiceProvider with ChangeNotifier {
  final InvoiceService _invoiceService = InvoiceService();

  List<Invoice> _invoices = [];
  List<Invoice> _filteredInvoices = [];
  Invoice? _selectedInvoice;
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  String _statusFilter = 'all';
  String _sortBy = 'date';
  bool _sortAscending = false;

  List<Invoice> get invoices => _filteredInvoices;
  Invoice? get selectedInvoice => _selectedInvoice;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  String get statusFilter => _statusFilter;
  String get sortBy => _sortBy;
  bool get sortAscending => _sortAscending;

  // Summary statistics
  double get totalAmount =>
      _invoices.fold(0.0, (sum, invoice) => sum + invoice.totalAmount);
  int get totalCount => _invoices.length;
  int get paidCount => _invoices.where((i) => i.status == 'paid').length;
  int get pendingCount => _invoices.where((i) => i.status == 'pending').length;
  int get overdueCount => _invoices.where((i) => i.status == 'overdue').length;

  Future<void> loadInvoices() async {
    _setLoading(true);
    _setError(null);

    try {
      _invoices = await _invoiceService.getAllInvoices();
      _applyFilters();
      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  Future<void> searchInvoices(String query) async {
    _setLoading(true);
    _setError(null);

    try {
      _invoices = await _invoiceService.searchInvoices(query);
      _searchQuery = query;
      _applyFilters();
      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  Future<Invoice?> createInvoice(Invoice invoice) async {
    _setLoading(true);
    _setError(null);

    try {
      final createdInvoice = await _invoiceService.createInvoice(invoice);
      _invoices.insert(0, createdInvoice);
      _applyFilters();
      _setLoading(false);
      return createdInvoice;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return null;
    }
  }

  Future<Invoice?> updateInvoice(Invoice invoice) async {
    _setLoading(true);
    _setError(null);

    try {
      final updatedInvoice = await _invoiceService.updateInvoiceObject(invoice);
      final index = _invoices.indexWhere((i) => i.id == invoice.id);
      if (index != -1) {
        _invoices[index] = updatedInvoice;
        if (_selectedInvoice?.id == invoice.id) {
          _selectedInvoice = updatedInvoice;
        }
        _applyFilters();
      }
      _setLoading(false);
      return updatedInvoice;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return null;
    }
  }

  Future<bool> deleteInvoice(String invoiceId) async {
    _setLoading(true);
    _setError(null);

    try {
      await _invoiceService.deleteInvoiceById(invoiceId);
      _invoices.removeWhere((i) => i.id.toString() == invoiceId);
      if (_selectedInvoice?.id.toString() == invoiceId) {
        _selectedInvoice = null;
      }
      _applyFilters();
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<void> loadInvoiceById(String invoiceId) async {
    _setLoading(true);
    _setError(null);

    try {
      _selectedInvoice = await _invoiceService.getInvoiceById(invoiceId);
      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  Future<String?> exportInvoices(
    String format, {
    List<String>? invoiceIds,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      final filePath = await _invoiceService.exportInvoicesAsFile(
        format,
        invoiceIds: invoiceIds,
      );
      _setLoading(false);
      return filePath;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return null;
    }
  }

  Future<Invoice?> processOcrDocument(String filePath) async {
    _setLoading(true);
    _setError(null);

    try {
      final invoice = await _invoiceService.processOcrDocument(filePath);
      _setLoading(false);
      return invoice;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return null;
    }
  }

  Future<Invoice?> uploadInvoiceFile(File file) async {
    _setLoading(true);
    _setError(null);

    try {
      final invoice = await _invoiceService.processOcrDocument(file.path);
      _invoices.add(invoice);
      _applyFilters();
      _setLoading(false);
      return invoice;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return null;
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  void setStatusFilter(String status) {
    _statusFilter = status;
    _applyFilters();
  }

  void setSorting(String sortBy, bool ascending) {
    _sortBy = sortBy;
    _sortAscending = ascending;
    _applyFilters();
  }

  void selectInvoice(Invoice? invoice) {
    _selectedInvoice = invoice;
    notifyListeners();
  }

  void clearSelection() {
    _selectedInvoice = null;
    notifyListeners();
  }

  void _applyFilters() {
    List<Invoice> filtered = List.from(_invoices);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((invoice) {
        return invoice.invoiceNumber.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ) ||
            invoice.vendorName.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ) ||
            invoice.description?.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ==
                true;
      }).toList();
    }

    // Apply status filter
    if (_statusFilter != 'all') {
      filtered = filtered
          .where((invoice) => invoice.status == _statusFilter)
          .toList();
    }

    // Apply sorting
    switch (_sortBy) {
      case 'date':
        filtered.sort(
          (a, b) => _sortAscending
              ? a.invoiceDate.compareTo(b.invoiceDate)
              : b.invoiceDate.compareTo(a.invoiceDate),
        );
        break;
      case 'amount':
        filtered.sort(
          (a, b) => _sortAscending
              ? a.totalAmount.compareTo(b.totalAmount)
              : b.totalAmount.compareTo(a.totalAmount),
        );
        break;
      case 'vendor':
        filtered.sort(
          (a, b) => _sortAscending
              ? a.vendorName.compareTo(b.vendorName)
              : b.vendorName.compareTo(a.vendorName),
        );
        break;
      case 'number':
        filtered.sort(
          (a, b) => _sortAscending
              ? a.invoiceNumber.compareTo(b.invoiceNumber)
              : b.invoiceNumber.compareTo(a.invoiceNumber),
        );
        break;
    }

    _filteredInvoices = filtered;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void refresh() {
    loadInvoices();
  }
}
