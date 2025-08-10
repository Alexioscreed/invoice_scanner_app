import 'invoice.dart';

class ApiResponse<T> {
  final bool success;
  final String? message;
  final T? data;
  final List<String>? errors;

  ApiResponse({required this.success, this.message, this.data, this.errors});

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json)? fromJsonT,
  ) {
    return ApiResponse<T>(
      success: json['success'] ?? false,
      message: json['message'],
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : json['data'],
      errors: json['errors'] != null ? List<String>.from(json['errors']) : null,
    );
  }
}

class PaginatedResponse<T> {
  final List<T> content;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;
  final bool first;
  final bool last;

  PaginatedResponse({
    required this.content,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
    required this.first,
    required this.last,
  });

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    return PaginatedResponse<T>(
      content: json['content'] != null
          ? (json['content'] as List)
                .map((item) => fromJsonT(item as Map<String, dynamic>))
                .toList()
          : [],
      page: json['page'] ?? 0,
      size: json['size'] ?? 0,
      totalElements: json['totalElements'] ?? 0,
      totalPages: json['totalPages'] ?? 0,
      first: json['first'] ?? true,
      last: json['last'] ?? true,
    );
  }
}

class InvoiceSearchRequest {
  final String? search;
  final String? category;
  final String? vendorName;
  final DateTime? startDate;
  final DateTime? endDate;
  final double? minAmount;
  final double? maxAmount;
  final int page;
  final int size;
  final String sortBy;
  final String sortDirection;

  InvoiceSearchRequest({
    this.search,
    this.category,
    this.vendorName,
    this.startDate,
    this.endDate,
    this.minAmount,
    this.maxAmount,
    this.page = 0,
    this.size = 20,
    this.sortBy = 'invoiceDate',
    this.sortDirection = 'desc',
  });

  Map<String, dynamic> toQueryParams() {
    final Map<String, dynamic> params = {
      'page': page.toString(),
      'size': size.toString(),
      'sortBy': sortBy,
      'sortDirection': sortDirection,
    };

    if (search != null && search!.isNotEmpty) {
      params['search'] = search!;
    }
    if (category != null && category!.isNotEmpty) {
      params['category'] = category!;
    }
    if (vendorName != null && vendorName!.isNotEmpty) {
      params['vendorName'] = vendorName!;
    }
    if (startDate != null) {
      params['startDate'] = startDate!.toIso8601String().split('T')[0];
    }
    if (endDate != null) {
      params['endDate'] = endDate!.toIso8601String().split('T')[0];
    }
    if (minAmount != null) {
      params['minAmount'] = minAmount!.toString();
    }
    if (maxAmount != null) {
      params['maxAmount'] = maxAmount!.toString();
    }

    return params;
  }
}

class UploadResponse {
  final bool success;
  final String? message;
  final String? filePath;
  final String? fileName;
  final int? fileSize;
  final String? uploadId;

  UploadResponse({
    required this.success,
    this.message,
    this.filePath,
    this.fileName,
    this.fileSize,
    this.uploadId,
  });

  factory UploadResponse.fromJson(Map<String, dynamic> json) {
    return UploadResponse(
      success: json['success'] ?? false,
      message: json['message'],
      filePath: json['filePath'],
      fileName: json['fileName'],
      fileSize: json['fileSize'],
      uploadId: json['uploadId'],
    );
  }
}

class ProcessingStatusResponse {
  final String status;
  final String? message;
  final double? progress;
  final Invoice? invoice;
  final int? invoiceId;
  final String? error;

  ProcessingStatusResponse({
    required this.status,
    this.message,
    this.progress,
    this.invoice,
    this.invoiceId,
    this.error,
  });

  factory ProcessingStatusResponse.fromJson(Map<String, dynamic> json) {
    return ProcessingStatusResponse(
      status: json['status'] ?? 'UNKNOWN',
      message: json['message'],
      progress: json['progress']?.toDouble(),
      invoice: json['invoice'] != null
          ? Invoice.fromJson(json['invoice'])
          : null,
      invoiceId: json['invoiceId'],
      error: json['error'],
    );
  }
}
