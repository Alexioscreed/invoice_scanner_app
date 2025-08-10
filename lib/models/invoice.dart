class Invoice {
  final int? id;
  final int? userId;
  final String invoiceNumber;
  final String vendorName;
  final String? vendorAddress;
  final String? vendorPhone;
  final String? vendorEmail;
  final DateTime invoiceDate;
  final DateTime? dueDate;
  final double totalAmount;
  final double? subtotal;
  final double? taxAmount;
  final double? taxRate;
  final double? discountAmount;
  final String currency;
  final String? category;
  final String? description;
  final String? notes;
  final String status; // Added status field
  final String? originalFilename;
  final String? filePath;
  final int? fileSize;
  final String? mimeType;
  final ProcessingStatus processingStatus;
  final double? confidenceScore;
  final String? ocrRawText;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<InvoiceLineItem>? lineItems;

  Invoice({
    this.id,
    this.userId,
    required this.invoiceNumber,
    required this.vendorName,
    this.vendorAddress,
    this.vendorPhone,
    this.vendorEmail,
    required this.invoiceDate,
    this.dueDate,
    required this.totalAmount,
    this.subtotal,
    this.taxAmount,
    this.taxRate,
    this.discountAmount,
    this.currency = 'USD',
    this.category,
    this.description,
    this.notes,
    this.status = 'pending', // Default status
    this.originalFilename,
    this.filePath,
    this.fileSize,
    this.mimeType,
    this.processingStatus = ProcessingStatus.PENDING,
    this.confidenceScore,
    this.ocrRawText,
    this.createdAt,
    this.updatedAt,
    this.lineItems,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: json['id'],
      userId: json['userId'],
      invoiceNumber: json['invoiceNumber'] ?? '',
      vendorName: json['vendorName'] ?? '',
      vendorAddress: json['vendorAddress'],
      vendorPhone: json['vendorPhone'],
      vendorEmail: json['vendorEmail'],
      invoiceDate: json['invoiceDate'] != null
          ? DateTime.parse(json['invoiceDate'])
          : DateTime.now(),
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
      totalAmount: (json['totalAmount'] ?? 0.0).toDouble(),
      subtotal: json['subtotal']?.toDouble(),
      taxAmount: json['taxAmount']?.toDouble(),
      taxRate: json['taxRate']?.toDouble(),
      discountAmount: json['discountAmount']?.toDouble(),
      currency: json['currency'] ?? 'USD',
      category: json['category'],
      description: json['description'],
      notes: json['notes'],
      status: json['status'] ?? 'pending', // Add status field
      originalFilename: json['originalFilename'],
      filePath: json['filePath'],
      fileSize: json['fileSize'],
      mimeType: json['mimeType'],
      processingStatus: ProcessingStatus.values.firstWhere(
        (e) => e.name == json['processingStatus'],
        orElse: () => ProcessingStatus.PENDING,
      ),
      confidenceScore: json['confidenceScore']?.toDouble(),
      ocrRawText: json['ocrRawText'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
      lineItems: json['lineItems'] != null
          ? (json['lineItems'] as List)
                .map((item) => InvoiceLineItem.fromJson(item))
                .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'invoiceNumber': invoiceNumber,
      'vendorName': vendorName,
      'vendorAddress': vendorAddress,
      'vendorPhone': vendorPhone,
      'vendorEmail': vendorEmail,
      'invoiceDate': invoiceDate.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
      'totalAmount': totalAmount,
      'subtotal': subtotal,
      'taxAmount': taxAmount,
      'taxRate': taxRate,
      'discountAmount': discountAmount,
      'currency': currency,
      'category': category,
      'description': description,
      'notes': notes,
      'status': status, // Add status field
      'originalFilename': originalFilename,
      'filePath': filePath,
      'fileSize': fileSize,
      'mimeType': mimeType,
      'processingStatus': processingStatus.name,
      'confidenceScore': confidenceScore,
      'ocrRawText': ocrRawText,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'lineItems': lineItems?.map((item) => item.toJson()).toList(),
    };
  }

  Invoice copyWith({
    int? id,
    int? userId,
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
    String? status, // Add status field
    String? originalFilename,
    String? filePath,
    int? fileSize,
    String? mimeType,
    ProcessingStatus? processingStatus,
    double? confidenceScore,
    String? ocrRawText,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<InvoiceLineItem>? lineItems,
  }) {
    return Invoice(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      vendorName: vendorName ?? this.vendorName,
      vendorAddress: vendorAddress ?? this.vendorAddress,
      vendorPhone: vendorPhone ?? this.vendorPhone,
      vendorEmail: vendorEmail ?? this.vendorEmail,
      invoiceDate: invoiceDate ?? this.invoiceDate,
      dueDate: dueDate ?? this.dueDate,
      totalAmount: totalAmount ?? this.totalAmount,
      subtotal: subtotal ?? this.subtotal,
      taxAmount: taxAmount ?? this.taxAmount,
      taxRate: taxRate ?? this.taxRate,
      discountAmount: discountAmount ?? this.discountAmount,
      currency: currency ?? this.currency,
      category: category ?? this.category,
      description: description ?? this.description,
      notes: notes ?? this.notes,
      status: status ?? this.status, // Add status field
      originalFilename: originalFilename ?? this.originalFilename,
      filePath: filePath ?? this.filePath,
      fileSize: fileSize ?? this.fileSize,
      mimeType: mimeType ?? this.mimeType,
      processingStatus: processingStatus ?? this.processingStatus,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      ocrRawText: ocrRawText ?? this.ocrRawText,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lineItems: lineItems ?? this.lineItems,
    );
  }

  String get formattedAmount => '\$${totalAmount.toStringAsFixed(2)}';
  String get formattedDate =>
      '${invoiceDate.day}/${invoiceDate.month}/${invoiceDate.year}';

  bool get isOverdue {
    if (dueDate == null) return false;
    return DateTime.now().isAfter(dueDate!);
  }

  @override
  String toString() {
    return 'Invoice{id: $id, invoiceNumber: $invoiceNumber, vendorName: $vendorName, totalAmount: $totalAmount}';
  }
}

class InvoiceLineItem {
  final int? id;
  final int? invoiceId;
  final String description;
  final double quantity;
  final double unitPrice;
  final double totalPrice;
  final String? unitOfMeasure;
  final double? taxRate;
  final double? taxAmount;
  final double? discountRate;
  final double? discountAmount;
  final String? itemCode;
  final String? category;
  final int? lineNumber;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  InvoiceLineItem({
    this.id,
    this.invoiceId,
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.unitOfMeasure,
    this.taxRate,
    this.taxAmount,
    this.discountRate,
    this.discountAmount,
    this.itemCode,
    this.category,
    this.lineNumber,
    this.createdAt,
    this.updatedAt,
  });

  factory InvoiceLineItem.fromJson(Map<String, dynamic> json) {
    return InvoiceLineItem(
      id: json['id'],
      invoiceId: json['invoiceId'],
      description: json['description'] ?? '',
      quantity: (json['quantity'] ?? 0.0).toDouble(),
      unitPrice: (json['unitPrice'] ?? 0.0).toDouble(),
      totalPrice: (json['totalPrice'] ?? 0.0).toDouble(),
      unitOfMeasure: json['unitOfMeasure'],
      taxRate: json['taxRate']?.toDouble(),
      taxAmount: json['taxAmount']?.toDouble(),
      discountRate: json['discountRate']?.toDouble(),
      discountAmount: json['discountAmount']?.toDouble(),
      itemCode: json['itemCode'],
      category: json['category'],
      lineNumber: json['lineNumber'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'invoiceId': invoiceId,
      'description': description,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'totalPrice': totalPrice,
      'unitOfMeasure': unitOfMeasure,
      'taxRate': taxRate,
      'taxAmount': taxAmount,
      'discountRate': discountRate,
      'discountAmount': discountAmount,
      'itemCode': itemCode,
      'category': category,
      'lineNumber': lineNumber,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  String get formattedTotalPrice => '\$${totalPrice.toStringAsFixed(2)}';
  String get formattedUnitPrice => '\$${unitPrice.toStringAsFixed(2)}';
}

enum ProcessingStatus { PENDING, PROCESSING, COMPLETED, FAILED, MANUAL_REVIEW }

extension ProcessingStatusExtension on ProcessingStatus {
  String get displayName {
    switch (this) {
      case ProcessingStatus.PENDING:
        return 'Pending';
      case ProcessingStatus.PROCESSING:
        return 'Processing';
      case ProcessingStatus.COMPLETED:
        return 'Completed';
      case ProcessingStatus.FAILED:
        return 'Failed';
      case ProcessingStatus.MANUAL_REVIEW:
        return 'Manual Review';
    }
  }

  String get description {
    switch (this) {
      case ProcessingStatus.PENDING:
        return 'Waiting to be processed';
      case ProcessingStatus.PROCESSING:
        return 'Currently being processed';
      case ProcessingStatus.COMPLETED:
        return 'Processing completed successfully';
      case ProcessingStatus.FAILED:
        return 'Processing failed';
      case ProcessingStatus.MANUAL_REVIEW:
        return 'Requires manual review';
    }
  }
}
