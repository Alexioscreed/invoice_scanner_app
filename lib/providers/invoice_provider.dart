import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
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
      // Debug log: ensure created invoice returned from backend
      print('DEBUG: createInvoice returned id=${createdInvoice.id}');
      _invoices.insert(0, createdInvoice);
      _applyFilters();
      _setLoading(false);
      return createdInvoice;
    } catch (e) {
      final err = e.toString();
      print('ERROR: createInvoice failed: $err');
      _setError(err);
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

  // Added method to fix undefined_method error
  List<Invoice> getFilteredInvoices({String? searchQuery, String? category}) {
    if ((searchQuery == null || searchQuery.isEmpty) && category == null) {
      return _filteredInvoices;
    }

    return _filteredInvoices.where((invoice) {
      bool matchesSearch = true;
      bool matchesCategory = true;

      if (searchQuery != null && searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        matchesSearch =
            invoice.invoiceNumber.toLowerCase().contains(query) ||
            invoice.vendorName.toLowerCase().contains(query) ||
            (invoice.description?.toLowerCase().contains(query) ?? false);
      }

      if (category != null) {
        matchesCategory = invoice.category == category;
      }

      return matchesSearch && matchesCategory;
    }).toList();
  }

  // Added method to fix undefined_method error
  List<String> getCategories() {
    final categories = _invoices
        .map((invoice) => invoice.category)
        .where((category) => category != null && category.isNotEmpty)
        .cast<String>()
        .toSet()
        .toList();

    categories.sort();
    return categories;
  }

  // Method to process PDF/image files and extract invoice data
  Future<Map<String, dynamic>?> processInvoiceFile(File file) async {
    try {
      // Read PDF content
      String extractedText = await _extractTextFromPDF(file);
      print(
        'DEBUG: Extracted PDF text preview: ${extractedText.substring(0, math.min(300, extractedText.length))}...',
      );

      Map<String, dynamic> extractedData = {};

      // Extract invoice number from actual PDF text
      String? invoiceNumber = _extractInvoiceNumberFromText(extractedText);
      extractedData['invoiceNumber'] =
          invoiceNumber ??
          'INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
      print('DEBUG: Extracted invoice number: $invoiceNumber');

      // Extract vendor name from actual PDF text
      String? vendorName = _extractVendorNameFromText(extractedText);
      extractedData['vendorName'] = vendorName ?? 'Unknown Vendor';
      print('DEBUG: Extracted vendor name: $vendorName');

      // Extract total amount from actual PDF text
      double? totalAmount = _extractAmountFromText(extractedText);
      extractedData['totalAmount'] = totalAmount ?? 0.0;
      print('DEBUG: Extracted total amount: $totalAmount');

      // Extract dates from actual PDF text
      DateTime? invoiceDate = _extractDateFromText(extractedText);
      extractedData['invoiceDate'] = invoiceDate ?? DateTime.now();
      extractedData['dueDate'] = (invoiceDate ?? DateTime.now()).add(
        const Duration(days: 30),
      );
      print('DEBUG: Extracted invoice date: $invoiceDate');

      // Smart category detection based on extracted content
      String category = _detectCategoryFromText(extractedText, vendorName);
      extractedData['category'] = category;

      // Set status based on PDF content
      String status = _extractStatusFromText(extractedText);
      extractedData['status'] = status;
      print('DEBUG: Extracted status: $status');

      return extractedData;
    } catch (e) {
      throw Exception('Failed to process invoice file: $e');
    }
  }

  // Extract text from PDF file
  Future<String> _extractTextFromPDF(File file) async {
    try {
      final Uint8List bytes = await file.readAsBytes();
      final PdfDocument document = PdfDocument(inputBytes: bytes);

      String extractedText = '';
      for (int i = 0; i < document.pages.count; i++) {
        final PdfTextExtractor extractor = PdfTextExtractor(document);
        final String pageText = extractor.extractText(
          startPageIndex: i,
          endPageIndex: i,
        );
        extractedText += pageText + '\n';
      }

      document.dispose();
      return extractedText;
    } catch (e) {
      // If PDF extraction fails, return filename for basic extraction
      return file.path.split('/').last;
    }
  }

  // Extract invoice number from PDF text
  String? _extractInvoiceNumberFromText(String text) {
    final patterns = [
      // Match "Invoice No: 002" or "Invoice No. 002"
      RegExp(r'Invoice\s*No\.?\s*:?\s*([A-Z0-9-]+)', caseSensitive: false),
      // Match "Invoice Number: 01234"
      RegExp(r'Invoice\s*Number\s*:?\s*([A-Z0-9-]+)', caseSensitive: false),
      // Match "Invoice #: 12345789"
      RegExp(r'Invoice\s*#\s*:?\s*([A-Z0-9-]+)', caseSensitive: false),
      // Match standalone "Invoice 002" or "INVOICE 002"
      RegExp(r'Invoice\s+([A-Z0-9-]+)', caseSensitive: false),
      // Match "#002" or "# 002"
      RegExp(r'#\s*([0-9]+)', caseSensitive: false),
      // Match "No: 002" or "No. 002"
      RegExp(r'No\.?\s*:?\s*([A-Z0-9-]+)', caseSensitive: false),
      // Match patterns like "01234" in the header area (first 500 chars)
      RegExp(r'\b([0-9]{3,8})\b', caseSensitive: false),
    ];

    // Check first 800 characters for invoice number (header area)
    final headerText = text.length > 800 ? text.substring(0, 800) : text;

    for (var pattern in patterns) {
      final matches = pattern.allMatches(headerText);
      for (var match in matches) {
        final invoiceNum = match.group(1)?.trim();
        if (invoiceNum != null && invoiceNum.isNotEmpty) {
          // Validate it's a reasonable invoice number
          if (invoiceNum.length >= 1 && invoiceNum.length <= 20) {
            // Skip common false positives
            if (![
              '2024',
              '2025',
              '2026',
              '100',
              '200',
              '300',
            ].contains(invoiceNum)) {
              return invoiceNum;
            }
          }
        }
      }
    }
    return null;
  }

  // Extract vendor name from PDF text
  String? _extractVendorNameFromText(String text) {
    final lines = text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    // Look for vendor name patterns
    final vendorPatterns = [
      RegExp(
        r'^([A-Za-z\s&.,]+(?:LLC|Inc|Corp|Ltd|Solutions|Services|Group|Company))',
        caseSensitive: false,
      ),
      RegExp(r'Bill\s+From:\s*([A-Za-z\s&.,]+)', caseSensitive: false),
      RegExp(r'From:\s*([A-Za-z\s&.,]+)', caseSensitive: false),
    ];

    // Check first few lines for company names
    for (int i = 0; i < math.min(10, lines.length); i++) {
      final line = lines[i];

      // Skip common invoice headers
      if (line.toLowerCase().contains(
        RegExp(r'invoice|bill to|date|amount|total'),
      )) {
        continue;
      }

      for (var pattern in vendorPatterns) {
        final match = pattern.firstMatch(line);
        if (match != null && match.group(1) != null) {
          return match.group(1)!.trim();
        }
      }

      // If line looks like a company name (has business indicators)
      if (line.length > 3 &&
          line.length < 50 &&
          RegExp(
            r'[A-Za-z\s&.,]+(LLC|Inc|Corp|Ltd|Solutions|Services|Group|Company|\b[A-Z][a-z]+\s[A-Z][a-z]+)',
            caseSensitive: false,
          ).hasMatch(line)) {
        return line;
      }
    }

    // Fallback: return first non-header line that looks like a name
    for (final line in lines.take(5)) {
      if (line.length > 5 &&
          line.length < 40 &&
          RegExp(r'^[A-Za-z][A-Za-z\s&.,]+$').hasMatch(line) &&
          !line.toLowerCase().contains(
            RegExp(r'invoice|bill|date|total|amount|qty|price'),
          )) {
        return line;
      }
    }

    return null;
  }

  // Extract total amount from PDF text
  double? _extractAmountFromText(String text) {
    final amountPatterns = [
      RegExp(
        r'(?:Grand\s*)?Total\s*:?\s*\$?([0-9,]+\.?\d*)',
        caseSensitive: false,
      ),
      RegExp(r'Amount\s*Due\s*:?\s*\$?([0-9,]+\.?\d*)', caseSensitive: false),
      RegExp(r'\$([0-9,]+\.\d{2})', caseSensitive: false),
      RegExp(r'([0-9,]+\.\d{2})', caseSensitive: false),
    ];

    // Look for the highest amount (likely to be total)
    double maxAmount = 0.0;

    for (var pattern in amountPatterns) {
      final matches = pattern.allMatches(text);
      for (var match in matches) {
        final amountStr = match.group(1)?.replaceAll(',', '') ?? '0';
        final amount = double.tryParse(amountStr) ?? 0.0;
        if (amount > maxAmount && amount < 1000000) {
          // Reasonable upper limit
          maxAmount = amount;
        }
      }
    }

    return maxAmount > 0 ? maxAmount : null;
  }

  // Extract date from PDF text
  DateTime? _extractDateFromText(String text) {
    final datePatterns = [
      RegExp(
        r'Date\s*:?\s*(\d{1,2}[-/]\w{3}[-/]\d{4})',
        caseSensitive: false,
      ), // 16-Aug-2025
      RegExp(
        r'Date\s*:?\s*(\d{1,2}[-/.]\d{1,2}[-/.]\d{4})',
        caseSensitive: false,
      ), // 16/08/2025
      RegExp(
        r'(\d{1,2}[-/.]\d{1,2}[-/.]\d{4})',
        caseSensitive: false,
      ), // General date
    ];

    for (var pattern in datePatterns) {
      final match = pattern.firstMatch(text);
      if (match != null && match.group(1) != null) {
        final dateStr = match.group(1)!;
        try {
          // Try different date formats
          if (dateStr.contains('-') && dateStr.contains(RegExp(r'[A-Za-z]'))) {
            // Format: 16-Aug-2025
            final parts = dateStr.split('-');
            if (parts.length == 3) {
              final day = int.parse(parts[0]);
              final year = int.parse(parts[2]);
              final monthStr = parts[1].toLowerCase();
              final monthMap = {
                'jan': 1,
                'feb': 2,
                'mar': 3,
                'apr': 4,
                'may': 5,
                'jun': 6,
                'jul': 7,
                'aug': 8,
                'sep': 9,
                'oct': 10,
                'nov': 11,
                'dec': 12,
              };
              final month = monthMap[monthStr] ?? 1;
              return DateTime(year, month, day);
            }
          } else {
            // Try standard date parsing
            final normalizedDate = dateStr.replaceAll('/', '-');
            final parts = normalizedDate.split('-');
            if (parts.length == 3) {
              return DateTime(
                int.parse(parts[2]),
                int.parse(parts[1]),
                int.parse(parts[0]),
              );
            }
          }
        } catch (e) {
          continue;
        }
      }
    }

    return null;
  }

  // Detect category from text content
  String _detectCategoryFromText(String text, String? vendorName) {
    final textLower = text.toLowerCase();
    final vendorLower = vendorName?.toLowerCase() ?? '';

    // Software-related keywords
    if (textLower.contains(
      RegExp(
        r'app|software|development|programming|web|mobile|system|tech|digital|cloud|saas',
      ),
    )) {
      return 'Software';
    }

    // Design/Marketing keywords
    if (textLower.contains(
      RegExp(
        r'design|creative|brand|logo|marketing|advertising|consultation|media',
      ),
    )) {
      return 'Marketing';
    }

    // Professional services
    if (textLower.contains(
      RegExp(r'consultation|advisory|professional|service|support|maintenance'),
    )) {
      return 'Professional Services';
    }

    // Hardware-related
    if (textLower.contains(
      RegExp(r'hardware|equipment|device|computer|server|network'),
    )) {
      return 'Hardware';
    }

    // Office supplies
    if (textLower.contains(RegExp(r'supply|supplies|office|paper|equipment'))) {
      return 'Office Supplies';
    }

    // Default based on vendor
    if (vendorLower.contains('solutions') || vendorLower.contains('tech')) {
      return 'Software';
    }

    return 'Other';
  }

  // Extract status from PDF text
  String _extractStatusFromText(String text) {
    final textLower = text.toLowerCase();

    print(
      '🔍 Status extraction - analyzing text: ${text.substring(0, math.min(200, text.length))}...',
    );

    // High priority patterns (exact matches from your examples)
    final highPriorityPatterns = [
      // Match "Status: PAID" pattern (Lhusajo example)
      RegExp(r'Status\s*:?\s*(PAID|Paid|paid)', caseSensitive: false),
      // Match "Payment Status: Paid in Full" (Lhusajo example)
      RegExp(
        r'Payment\s+Status\s*:?\s*(Paid\s+in\s+Full)',
        caseSensitive: false,
      ),
      // Match "Paid in Full ■" checkbox pattern
      RegExp(r'Paid\s+in\s+Full\s*[■□✓]', caseSensitive: false),
    ];

    for (var pattern in highPriorityPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        print('✅ Found high priority status pattern: ${match.group(0)}');
        return 'paid';
      }
    }

    // Medium priority patterns
    final mediumPriorityPatterns = [
      // Match standalone "PAID" or "Paid"
      RegExp(r'\bPAID\b|\bPaid\b'),
      // Match "UNPAID" or "Unpaid"
      RegExp(r'\bUNPAID\b|\bUnpaid\b'),
      // Match "OVERDUE" or "Overdue"
      RegExp(r'\bOVERDUE\b|\bOverdue\b'),
      // Match "Thank you" messages (usually indicates payment received)
      RegExp(r'Thank\s+you\s+for.*payment', caseSensitive: false),
      RegExp(r'Thank\s+you.*prompt\s+payment', caseSensitive: false),
    ];

    for (var pattern in mediumPriorityPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final matchText = match.group(0)!.toLowerCase();
        print('📋 Found medium priority status pattern: ${match.group(0)}');

        if (matchText.contains('paid') || matchText.contains('thank')) {
          return 'paid';
        } else if (matchText.contains('unpaid')) {
          return 'unpaid';
        } else if (matchText.contains('overdue')) {
          return 'overdue';
        }
      }
    }

    // Date-based status detection (if due date is in the past, likely overdue)
    final dueDatePattern = RegExp(
      r'Due\s+Date\s*:?\s*(\d{1,2}[./]\d{1,2}[./]\d{2,4})',
      caseSensitive: false,
    );
    final dueDateMatch = dueDatePattern.firstMatch(text);
    if (dueDateMatch != null) {
      try {
        final dueDateStr = dueDateMatch.group(1)!;
        print('📅 Found due date: $dueDateStr');

        // Parse different date formats
        DateTime? dueDate;
        if (dueDateStr.contains('.')) {
          final parts = dueDateStr.split('.');
          if (parts.length == 3) {
            final day = int.tryParse(parts[0]);
            final month = int.tryParse(parts[1]);
            var year = int.tryParse(parts[2]);
            if (year != null && year < 100)
              year += 2000; // Convert 2-digit year

            if (day != null && month != null && year != null) {
              dueDate = DateTime(year, month, day);
            }
          }
        } else if (dueDateStr.contains('/')) {
          final parts = dueDateStr.split('/');
          if (parts.length == 3) {
            final month = int.tryParse(parts[0]);
            final day = int.tryParse(parts[1]);
            var year = int.tryParse(parts[2]);
            if (year != null && year < 100) year += 2000;

            if (day != null && month != null && year != null) {
              dueDate = DateTime(year, month, day);
            }
          }
        }

        if (dueDate != null) {
          final now = DateTime.now();
          if (dueDate.isBefore(now)) {
            print('⏰ Due date is in the past, marking as overdue');
            return 'overdue';
          } else {
            print('📅 Due date is in the future, marking as pending');
            return 'pending';
          }
        }
      } catch (e) {
        print('❌ Error parsing due date: $e');
      }
    }

    // Low priority contextual patterns
    if (textLower.contains(
      RegExp(r'total.*\$0\.00|balance.*\$0\.00|amount\s+due.*\$0\.00'),
    )) {
      print('💰 Found zero balance, marking as paid');
      return 'paid';
    }

    if (textLower.contains(
      RegExp(r'thank\s+you(?!\s+for\s+your\s+business)'),
    )) {
      print('🙏 Found thank you message, likely paid');
      return 'paid';
    }

    // Default fallback
    print('❓ No status pattern found, defaulting to pending');
    return 'pending';
  }

  // Utility method for creating invoices with file upload
  Future<Invoice?> createInvoiceWithOptionalFile({
    required String invoiceNumber,
    required String vendorName,
    required DateTime invoiceDate,
    required DateTime dueDate,
    required double totalAmount,
    required String currency,
    String? category,
    String? status,
    File? file,
  }) async {
    final invoice = Invoice(
      invoiceNumber: invoiceNumber,
      vendorName: vendorName,
      invoiceDate: invoiceDate,
      dueDate: dueDate,
      totalAmount: totalAmount,
      currency: currency,
      category: category,
      status: status ?? 'pending',
      processingStatus: ProcessingStatus.PENDING,
    );

    // Always use the extracted data instead of backend OCR
    // This ensures we send the data that was extracted on the frontend
    return createInvoice(invoice);
  }

  // Method to add invoice with extracted data (for compatibility with add_invoice_screen)
  Future<Invoice?> addInvoice({
    required String invoiceNumber,
    required String vendorName,
    required double totalAmount,
    required String currency,
    required DateTime invoiceDate,
    DateTime? dueDate,
    String? category,
    String? status,
    File? file,
  }) async {
    return createInvoiceWithOptionalFile(
      invoiceNumber: invoiceNumber,
      vendorName: vendorName,
      invoiceDate: invoiceDate,
      dueDate: dueDate ?? invoiceDate.add(const Duration(days: 30)),
      totalAmount: totalAmount,
      currency: currency,
      category: category,
      status: status,
      file: file,
    );
  }
}
