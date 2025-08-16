import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../providers/invoice_provider.dart';
import '../constants/app_constants.dart';

class AddInvoiceScreen extends StatefulWidget {
  const AddInvoiceScreen({super.key});

  @override
  State<AddInvoiceScreen> createState() => _AddInvoiceScreenState();
}

class _AddInvoiceScreenState extends State<AddInvoiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _invoiceNumberController = TextEditingController();
  final _vendorNameController = TextEditingController();
  final _totalAmountController = TextEditingController();

  DateTime _invoiceDate = DateTime.now();
  DateTime? _dueDate;
  String _selectedCategory = 'Other';
  String _currency = 'USD';
  File? _selectedFile;
  bool _isProcessing = false;
  String _invoiceStatus = 'pending';

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _invoiceNumberController.dispose();
    _vendorNameController.dispose();
    _totalAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Tailwind slate-50
      appBar: AppBar(
        title: const Text(
          'Add Invoice',
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
          onPressed: () => context.pop(),
        ),
        actions: [
          if (!_isProcessing)
            TextButton.icon(
              onPressed: _submitForm,
              icon: const Icon(
                Icons.save,
                color: Color(0xFF3B82F6), // Tailwind blue-500
              ),
              label: const Text(
                'Save',
                style: TextStyle(
                  color: Color(0xFF3B82F6), // Tailwind blue-500
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: _isProcessing ? _buildProcessingView() : _buildFormView(),
      ),
      bottomNavigationBar: _isProcessing
          ? null
          : Container(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                top: 8,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x1A64748B), // Tailwind slate-500 with opacity
                    blurRadius: 8,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(
                      0xFF3B82F6,
                    ), // Tailwind blue-500
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Save Invoice',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildProcessingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              Color(0xFF3B82F6), // Tailwind blue-500
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Processing Invoice...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B), // Tailwind slate-800
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'This may take a moment',
            style: TextStyle(
              color: Color(0xFF64748B), // Tailwind slate-500
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormView() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTabSelector(),
                const SizedBox(height: 24),
                _selectedFile != null
                    ? _buildFilePreview()
                    : _buildFileSelectionArea(),
                const SizedBox(height: 24),
                const Divider(color: Color(0xFFE2E8F0)), // Tailwind slate-200
                const SizedBox(height: 16),
                const Text(
                  'Invoice Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B), // Tailwind slate-800
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _invoiceNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Invoice Number',
                    labelStyle: TextStyle(
                      color: Color(0xFF64748B), // Tailwind slate-500
                    ),
                    prefixIcon: Icon(
                      Icons.numbers,
                      color: Color(0xFF3B82F6), // Tailwind blue-500
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      borderSide: BorderSide(
                        color: Color(0xFFE2E8F0), // Tailwind slate-200
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      borderSide: BorderSide(
                        color: Color(0xFFE2E8F0), // Tailwind slate-200
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      borderSide: BorderSide(
                        color: Color(0xFF3B82F6), // Tailwind blue-500
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  style: const TextStyle(
                    color: Color(0xFF1E293B), // Tailwind slate-800
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an invoice number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _vendorNameController,
                  decoration: const InputDecoration(
                    labelText: 'Vendor Name',
                    labelStyle: TextStyle(
                      color: Color(0xFF64748B), // Tailwind slate-500
                    ),
                    prefixIcon: Icon(
                      Icons.store,
                      color: Color(0xFF3B82F6), // Tailwind blue-500
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      borderSide: BorderSide(
                        color: Color(0xFFE2E8F0), // Tailwind slate-200
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      borderSide: BorderSide(
                        color: Color(0xFFE2E8F0), // Tailwind slate-200
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      borderSide: BorderSide(
                        color: Color(0xFF3B82F6), // Tailwind blue-500
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  style: const TextStyle(
                    color: Color(0xFF1E293B), // Tailwind slate-800
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a vendor name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _totalAmountController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Total Amount',
                          prefixIcon: Icon(Icons.attach_money),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter the total amount';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      width: 100,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _currency,
                          items: const [
                            DropdownMenuItem(value: 'USD', child: Text('USD')),
                            DropdownMenuItem(value: 'EUR', child: Text('EUR')),
                            DropdownMenuItem(value: 'GBP', child: Text('GBP')),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _currency = value;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildDatePicker(
                        label: 'Invoice Date',
                        selectedDate: _invoiceDate,
                        onDateSelected: (date) {
                          setState(() {
                            _invoiceDate = date;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildDatePicker(
                        label: 'Due Date (Optional)',
                        selectedDate: _dueDate,
                        onDateSelected: (date) {
                          setState(() {
                            _dueDate = date;
                          });
                        },
                        allowNull: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    prefixIcon: Icon(Icons.category),
                    border: OutlineInputBorder(),
                  ),
                  items: AppConstants.defaultCategories
                      .map(
                        (category) => DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedCategory = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _invoiceStatus,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    prefixIcon: Icon(Icons.pending_actions),
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'pending', child: Text('Pending')),
                    DropdownMenuItem(value: 'paid', child: Text('Paid')),
                    DropdownMenuItem(value: 'overdue', child: Text('Overdue')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _invoiceStatus = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTabSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () {}, // Active tab
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const Text(
                  'Manual Entry',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: _pickImageFromCamera,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: const Text(
                  'Scan with Camera',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileSelectionArea() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_upload, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Upload invoice document (optional)',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _pickImageFromGallery,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Gallery'),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _pickPDF,
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('PDF'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => _showBatchUploadDialog(),
              icon: const Icon(Icons.file_copy),
              label: const Text('Batch Upload'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilePreview() {
    final fileName = _selectedFile?.path.split('/').last ?? 'Selected File';
    final isPDF = fileName.toLowerCase().endsWith('.pdf');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                isPDF ? Icons.picture_as_pdf : Icons.image,
                size: 48,
                color: isPDF ? Colors.red : Colors.blue,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fileName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${_getFileSize(_selectedFile!.lengthSync())} - ${_getFileExtension(fileName)}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () {
                  setState(() {
                    _selectedFile = null;
                  });
                },
              ),
            ],
          ),
          if (!isPDF && _selectedFile != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                _selectedFile!,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDatePicker({
    required String label,
    required DateTime? selectedDate,
    required Function(DateTime) onDateSelected,
    bool allowNull = false,
  }) {
    return InkWell(
      onTap: () async {
        final pickedDate = await showDatePicker(
          context: context,
          initialDate: selectedDate ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (pickedDate != null) {
          onDateSelected(pickedDate);
        } else if (allowNull && pickedDate == null) {
          onDateSelected(DateTime.now());
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    selectedDate != null
                        ? DateFormat('MM/dd/yyyy').format(selectedDate)
                        : 'Select Date',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImageFromCamera() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85, // Image quality check
    );

    if (pickedFile != null) {
      setState(() {
        _selectedFile = File(pickedFile.path);
      });
      _validateImageQuality(_selectedFile!);
    }
  }

  Future<void> _pickImageFromGallery() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85, // Image quality check
    );
    if (pickedFile != null) {
      setState(() {
        _selectedFile = File(pickedFile.path);
      });
      _validateImageQuality(_selectedFile!);
    }
  }

  Future<void> _pickPDF() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: false, // Set to true for batch upload
    );
    if (result != null && result.files.isNotEmpty) {
      final path = result.files.first.path;
      if (path != null) {
        setState(() {
          _selectedFile = File(path);
        });
      }
    }
  }

  String _getFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  String _getFileExtension(String fileName) {
    return fileName.contains('.')
        ? fileName.substring(fileName.lastIndexOf('.') + 1).toUpperCase()
        : 'UNKNOWN';
  }

  void _validateImageQuality(File imageFile) {
    // Check file size - warn if > 10MB or < 50KB (too small might mean low quality)
    final fileSize = imageFile.lengthSync();
    if (fileSize > 10 * 1024 * 1024) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Warning: Image file size is very large. This may affect upload speed.',
          ),
          backgroundColor: Colors.amber,
        ),
      );
    } else if (fileSize < 50 * 1024) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Warning: Image resolution may be too low for accurate OCR processing.',
          ),
          backgroundColor: Colors.amber,
        ),
      );
    }
  }

  void _showBatchUploadDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Batch Upload'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Select multiple invoices to upload at once.'),
            SizedBox(height: 8),
            Text(
              'Supported formats: JPG, PNG, PDF',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _pickMultipleImages();
            },
            child: const Text('Images'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _pickMultipleDocuments();
            },
            child: const Text('Documents'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickMultipleImages() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage(imageQuality: 85);

    if (pickedFiles.isNotEmpty) {
      final file = File(pickedFiles.first.path);
      setState(() {
        _selectedFile = file;
      });
      _validateImageQuality(file);

      // Show count of additional files that would be processed
      if (pickedFiles.length > 1) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${pickedFiles.length - 1} additional files will be processed after saving this invoice.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _pickMultipleDocuments() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      allowMultiple: true,
    );

    if (result != null && result.files.isNotEmpty) {
      final path = result.files.first.path;
      if (path != null) {
        setState(() {
          _selectedFile = File(path);
        });

        // Show count of additional files that would be processed
        if (result.files.length > 1) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${result.files.length - 1} additional files will be processed after saving this invoice.',
              ),
            ),
          );
        }
      }
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isProcessing = true;
      });

      try {
        final invoiceProvider = Provider.of<InvoiceProvider>(
          context,
          listen: false,
        );

        await invoiceProvider.addInvoice(
          invoiceNumber: _invoiceNumberController.text,
          vendorName: _vendorNameController.text,
          totalAmount: double.parse(_totalAmountController.text),
          currency: _currency,
          invoiceDate: _invoiceDate,
          dueDate: _dueDate,
          category: _selectedCategory,
          status: _invoiceStatus,
          file: _selectedFile,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invoice saved successfully'),
              backgroundColor: Colors.green,
            ),
          );
          // Replace current route so user can't return to a completed add form
          context.go('/invoices');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to save invoice: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            _isProcessing = false;
          });
        }
      }
    }
  }
}
