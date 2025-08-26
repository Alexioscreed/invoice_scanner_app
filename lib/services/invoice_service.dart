import 'dart:io';
import '../models/invoice.dart';
import '../models/api_models.dart';
import 'api_service.dart';

class InvoiceService {
  static final InvoiceService _instance = InvoiceService._internal();
  factory InvoiceService() => _instance;
  InvoiceService._internal();

  final ApiService _apiService = ApiService();

  Future<PaginatedResponse<Invoice>> getInvoices({
    String? search,
    String? category,
    String? vendorName,
    DateTime? startDate,
    DateTime? endDate,
    double? minAmount,
    double? maxAmount,
    int page = 0,
    int size = 20,
    String sortBy = 'invoiceDate',
    String sortDirection = 'desc',
  }) async {
    try {
      final request = InvoiceSearchRequest(
        search: search,
        category: category,
        vendorName: vendorName,
        startDate: startDate,
        endDate: endDate,
        minAmount: minAmount,
        maxAmount: maxAmount,
        page: page,
        size: size,
        sortBy: sortBy,
        sortDirection: sortDirection,
      );

      return await _apiService.getInvoices(request);
    } catch (e) {
      throw e;
    }
  }

  Future<Invoice> getInvoice(int id) async {
    try {
      return await _apiService.getInvoice(id);
    } catch (e) {
      throw e;
    }
  }

  Future<Invoice> updateInvoice(
    int id, {
    String? invoiceNumber,
    String? vendorName,
    String? vendorAddress,
    String? vendorPhone,
    String? vendorEmail,
    DateTime? invoiceDate,
    DateTime? dueDate,
    double? totalAmount,
    double? subtotal,
    double? taxAmount,
    double? taxRate,
    double? discountAmount,
    String? currency,
    String? category,
    String? description,
    String? notes,
  }) async {
    try {
      final Map<String, dynamic> updateData = {};

      if (invoiceNumber != null) updateData['invoiceNumber'] = invoiceNumber;
      if (vendorName != null) updateData['vendorName'] = vendorName;
      if (vendorAddress != null) updateData['vendorAddress'] = vendorAddress;
      if (vendorPhone != null) updateData['vendorPhone'] = vendorPhone;
      if (vendorEmail != null) updateData['vendorEmail'] = vendorEmail;
      if (invoiceDate != null) {
        updateData['invoiceDate'] = invoiceDate.toIso8601String();
      }
      if (dueDate != null) updateData['dueDate'] = dueDate.toIso8601String();
      if (totalAmount != null) updateData['totalAmount'] = totalAmount;
      if (subtotal != null) updateData['subtotal'] = subtotal;
      if (taxAmount != null) updateData['taxAmount'] = taxAmount;
      if (taxRate != null) updateData['taxRate'] = taxRate;
      if (discountAmount != null) updateData['discountAmount'] = discountAmount;
      if (currency != null) updateData['currency'] = currency;
      if (category != null) updateData['category'] = category;
      if (description != null) updateData['description'] = description;
      if (notes != null) updateData['notes'] = notes;

      return await _apiService.updateInvoice(id, updateData);
    } catch (e) {
      throw e;
    }
  }

  Future<void> deleteInvoice(int id) async {
    try {
      await _apiService.deleteInvoice(id);
    } catch (e) {
      throw e;
    }
  }

  Future<Invoice> uploadInvoice(File file) async {
    try {
      // Validate file size
      final fileSize = await file.length();
      if (fileSize > 10 * 1024 * 1024) {
        // 10MB
        throw 'File size exceeds 10MB limit';
      }

      // Validate file type
      final fileName = file.path.toLowerCase();
      final validExtensions = ['jpg', 'jpeg', 'png', 'pdf'];
      final hasValidExtension = validExtensions.any(
        (ext) => fileName.endsWith('.$ext'),
      );

      if (!hasValidExtension) {
        throw 'Invalid file type. Please upload JPG, PNG, or PDF files only.';
      }

      return await _apiService.uploadInvoice(file);
    } catch (e) {
      throw e;
    }
  }

  Future<List<String>> getCategories() async {
    try {
      return await _apiService.getCategories();
    } catch (e) {
      // Return default categories if API fails
      return [
        'Office Supplies',
        'Travel',
        'Meals & Entertainment',
        'Equipment',
        'Software',
        'Marketing',
        'Professional Services',
        'Utilities',
        'Rent',
        'Insurance',
        'Other',
      ];
    }
  }

  Future<List<String>> getVendors() async {
    try {
      return await _apiService.getVendors();
    } catch (e) {
      throw e;
    }
  }

  Future<File> exportInvoices({
    String format = 'csv',
    DateTime? startDate,
    DateTime? endDate,
    String? category,
    required String fileName,
  }) async {
    try {
      final response = await _apiService.exportInvoicesWithDateRange(
        format: format,
        startDate: startDate,
        endDate: endDate,
        category: category,
      );

      // Save to temporary file
      final tempDir = Directory.systemTemp;
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(response.data);

      return file;
    } catch (e) {
      throw e;
    }
  }

  Future<Map<String, dynamic>> getAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      return await _apiService.getAnalytics(
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      throw e;
    }
  }

  // Get all invoices for the current user
  Future<List<Invoice>> getAllInvoices() async {
    try {
      final response = await getInvoices();
      return response.content;
    } catch (e) {
      throw e;
    }
  }

  // Search invoices
  Future<List<Invoice>> searchInvoices(String query) async {
    try {
      final response = await getInvoices(search: query);
      return response.content;
    } catch (e) {
      throw e;
    }
  }

  // Create a new invoice
  Future<Invoice> createInvoice(Invoice invoice) async {
    try {
      final response = await _apiService.createInvoice(invoice.toJson());

      try {
        // Try to parse the returned invoice JSON
        return Invoice.fromJson(response.data);
      } catch (e) {
        // If parsing failed (server couldn't serialize response),
        // try to find the created invoice by querying the invoices list
        // using the invoiceNumber as a best-effort identifier.
        try {
          final fallbackList = await getInvoices(search: invoice.invoiceNumber, size: 50);
          final found = fallbackList.content.firstWhere(
            (inv) => inv.invoiceNumber == invoice.invoiceNumber || inv.vendorName == invoice.vendorName,
            orElse: () => throw Exception('Created invoice not found after create (parse failed)') ,
          );
          return found;
        } catch (inner) {
          // Re-throw original parsing error if fallback fails
          throw Exception('Failed to parse create response and fallback lookup failed: $e; $inner');
        }
      }
    } catch (e) {
      throw e;
    }
  }

  // Get invoice by ID
  Future<Invoice> getInvoiceById(String invoiceId) async {
    try {
      return await getInvoice(int.parse(invoiceId));
    } catch (e) {
      throw e;
    }
  }

  // Update an existing invoice (overload for Invoice object)
  Future<Invoice> updateInvoiceObject(Invoice invoice) async {
    try {
      if (invoice.id == null) {
        throw Exception('Invoice ID is required for update');
      }
      return await _apiService.updateInvoice(invoice.id!, invoice.toJson());
    } catch (e) {
      throw e;
    }
  }

  // Process a document with OCR
  Future<Invoice> processOcrDocument(String filePath) async {
    try {
      // 1. Upload file to server for OCR processing
      final fileUploadResponse = await _apiService.uploadInvoiceFile(
        File(filePath),
      );

      // 2. Poll for processing status
      Invoice processedInvoice = fileUploadResponse;

      // Wait until processing is complete or failed
      while (processedInvoice.processingStatus == ProcessingStatus.PENDING ||
          processedInvoice.processingStatus == ProcessingStatus.PROCESSING) {
        // Wait before checking again
        await Future.delayed(const Duration(seconds: 2));

        // Get updated status
        processedInvoice = await getInvoice(processedInvoice.id!.toInt());
      }

      return processedInvoice;
    } catch (e) {
      throw e;
    }
  }

  // Delete an invoice by string ID
  Future<void> deleteInvoiceById(String invoiceId) async {
    try {
      await deleteInvoice(int.parse(invoiceId));
    } catch (e) {
      throw e;
    }
  }

  // Export invoices with string format
  Future<String> exportInvoicesAsFile(
    String format, {
    List<String>? invoiceIds,
    DateTime? startDate,
    DateTime? endDate,
    String? category,
  }) async {
    try {
      // Call API to get export data
      await _apiService.exportInvoicesWithDateRange(
        format: format,
        invoiceIds: invoiceIds?.map((id) => int.parse(id)).toList(),
        startDate: startDate,
        endDate: endDate,
        category: category,
      );

      // In a real implementation, you'd save the response to a file in the downloads directory
      final downloadPath =
          '/storage/downloads/invoices_${DateTime.now().millisecondsSinceEpoch}.$format';

      // Return the path to the downloaded file
      return downloadPath;
    } catch (e) {
      throw e;
    }
  }

  // Export invoices as CSV
  Future<String> exportInvoicesAsCsv({
    List<String>? invoiceIds,
    DateTime? startDate,
    DateTime? endDate,
    String? category,
  }) async {
    return exportInvoicesAsFile(
      'csv',
      invoiceIds: invoiceIds,
      startDate: startDate,
      endDate: endDate,
      category: category,
    );
  }

  // Export invoices as Excel
  Future<String> exportInvoicesAsExcel({
    List<String>? invoiceIds,
    DateTime? startDate,
    DateTime? endDate,
    String? category,
  }) async {
    return exportInvoicesAsFile(
      'xlsx',
      invoiceIds: invoiceIds,
      startDate: startDate,
      endDate: endDate,
      category: category,
    );
  }

  // Export invoices as PDF
  Future<String> exportInvoicesAsPdf({
    List<String>? invoiceIds,
    DateTime? startDate,
    DateTime? endDate,
    String? category,
  }) async {
    return exportInvoicesAsFile(
      'pdf',
      invoiceIds: invoiceIds,
      startDate: startDate,
      endDate: endDate,
      category: category,
    );
  }

  // Quick OCR document upload
  Future<Invoice> quickUploadDocument(String filePath) async {
    try {
      final file = File(filePath);
      final invoice = await _apiService.uploadInvoice(file);
      return invoice;
    } catch (e) {
      throw e;
    }
  }

  // Utility methods
  String getFileExtension(String fileName) {
    return fileName.split('.').last.toLowerCase();
  }

  bool isValidImageFile(String fileName) {
    final extension = getFileExtension(fileName);
    return ['jpg', 'jpeg', 'png'].contains(extension);
  }

  bool isValidDocumentFile(String fileName) {
    final extension = getFileExtension(fileName);
    return ['pdf'].contains(extension);
  }

  bool isValidFile(String fileName) {
    return isValidImageFile(fileName) || isValidDocumentFile(fileName);
  }

  String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String getProcessingStatusMessage(ProcessingStatus status) {
    switch (status) {
      case ProcessingStatus.PENDING:
        return 'Invoice is waiting to be processed';
      case ProcessingStatus.PROCESSING:
        return 'Invoice is being processed';
      case ProcessingStatus.COMPLETED:
        return 'Invoice processing completed successfully';
      case ProcessingStatus.FAILED:
        return 'Invoice processing failed';
      case ProcessingStatus.MANUAL_REVIEW:
        return 'Invoice requires manual review';
    }
  }
}
