import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../providers/expense_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/category_provider.dart';
import '../../models/expense_model.dart';
import '../../models/category_model.dart';
import '../../services/ocr_service.dart';
import '../../services/voice_input_service.dart';
import '../../services/ai_service.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';
import '../../theme/app_theme.dart';
import '../../utils/design_tokens.dart';
import 'package:uuid/uuid.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  final ExpenseModel? expense;
  
  const AddExpenseScreen({super.key, this.expense});

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();
  final _ocrService = OCRService();
  final _uuid = const Uuid();

  String? _selectedCategoryId;
  String _selectedPaymentMethod = 'Cash';
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  bool _isVoiceListening = false;
  bool _isProcessingOCR = false;
  String? _ocrExtractedText;
  String? _voiceExtractedText;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    
    if (widget.expense != null) {
      final expense = widget.expense!;
      _amountController.text = expense.amount.toString();
      _descriptionController.text = expense.description;
      _notesController.text = expense.notes ?? '';
      _selectedCategoryId = expense.categoryId;
      _selectedPaymentMethod = expense.paymentMethod;
      _selectedDate = expense.transactionDate;
    }
  }

  Future<void> _initializeServices() async {
    try {
      await _ocrService.initialize();
      await VoiceInputService.initialize();
    } catch (e) {
      debugPrint('Failed to initialize services: $e');
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    _ocrService.dispose();
    VoiceInputService.dispose();
    super.dispose();
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedCategoryId == null) {
      _showSnackBar('Please select a category', AppTheme.error);
      return;
    }

    final user = ref.read(userProvider).value;
    if (user == null) {
      _showSnackBar('User not authenticated', AppTheme.error);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final expenseData = {
        'id': widget.expense?.id ?? _uuid.v4(),
        'userId': user.id,
        'categoryId': _selectedCategoryId!,
        'amount': double.parse(_amountController.text),
        'description': _descriptionController.text.trim(),
        'paymentMethod': _selectedPaymentMethod,
        'transactionDate': _selectedDate,
        'notes': _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        'createdAt': widget.expense?.createdAt ?? DateTime.now(),
        'type': ExpenseType.expense,
      };

      // Add OCR metadata if available
      if (_ocrExtractedText != null) {
        expenseData['metadata'] = {
          'source': 'ocr',
          'extractedText': _ocrExtractedText,
        };
      }

      // Add voice metadata if available
      if (_voiceExtractedText != null) {
        expenseData['metadata'] = {
          'source': 'voice',
          'extractedText': _voiceExtractedText,
        };
      }

      final expense = ExpenseModel(
        id: expenseData['id'] as String,
        userId: expenseData['userId'] as String,
        categoryId: expenseData['categoryId'] as String,
        amount: expenseData['amount'] as double,
        description: expenseData['description'] as String,
        paymentMethod: expenseData['paymentMethod'] as String,
        transactionDate: expenseData['transactionDate'] as DateTime,
        createdAt: expenseData['createdAt'] as DateTime,
        type: expenseData['type'] as ExpenseType,
        notes: expenseData['notes'] as String?,
      );

      if (widget.expense != null) {
        await ref.read(expensesProvider.notifier).updateExpense(expense);
        _showSnackBar('Expense updated successfully', AppTheme.success);
      } else {
        await ref.read(expensesProvider.notifier).addExpense(expense);
        _showSnackBar('Expense added successfully', AppTheme.success);
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}', AppTheme.error);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackBar(String message, Color backgroundColor) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: backgroundColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  // OCR Functions
  Future<void> _captureReceipt() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );
      
      if (image != null) {
        await _processReceiptImage(image.path);
      }
    } catch (e) {
      _showSnackBar('Failed to capture image: $e', AppTheme.error);
    }
  }

  Future<void> _pickReceiptFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      
      if (image != null) {
        await _processReceiptImage(image.path);
      }
    } catch (e) {
      _showSnackBar('Failed to pick image: $e', AppTheme.error);
    }
  }

  Future<void> _processReceiptImage(String imagePath) async {
    setState(() => _isProcessingOCR = true);
    
    try {
      final result = await _ocrService.processImage(imagePath);
      
      if (result.success && result.extractedAmount != null) {
        setState(() {
          _amountController.text = result.extractedAmount!.toStringAsFixed(2);
          _descriptionController.text = result.extractedMerchant ?? result.rawText.split('\n').first;
          _ocrExtractedText = result.rawText;
          
          // Set category if suggested
          if (result.suggestedCategory != null) {
            _autoSelectCategoryByName(result.suggestedCategory!);
          }
        });
        
        _showSnackBar('Receipt processed successfully!', AppTheme.success);
      } else {
        _showSnackBar(result.message, AppTheme.warning);
      }
    } catch (e) {
      _showSnackBar('Failed to process receipt: $e', AppTheme.error);
    } finally {
      setState(() => _isProcessingOCR = false);
    }
  }

  // Voice Input Functions
  Future<void> _startVoiceInput() async {
    if (_isVoiceListening) {
      await _stopVoiceInput();
      return;
    }

    setState(() => _isVoiceListening = true);
    
    try {
      await VoiceInputService.startListening(
        onResult: _processVoiceResult,
        onError: (error) {
          _showSnackBar('Voice input error: $error', AppTheme.error);
          setState(() => _isVoiceListening = false);
        },
      );
    } catch (e) {
      _showSnackBar('Failed to start voice input: $e', AppTheme.error);
      setState(() => _isVoiceListening = false);
    }
  }

  Future<void> _stopVoiceInput() async {
    await VoiceInputService.stopListening();
    setState(() => _isVoiceListening = false);
  }

  void _processVoiceResult(String text) async {
    if (text.isEmpty) return;
    
    setState(() {
      _isVoiceListening = false;
      _voiceExtractedText = text;
    });

    try {
      // Try AI parsing first if available
      if (AiService.isEnabled) {
        final aiResult = await AiService.parseExpenseFromText(text);
        
        setState(() {
          if (aiResult.amount != null) {
            _amountController.text = aiResult.amount!.toStringAsFixed(2);
          }
          if (aiResult.description?.isNotEmpty == true) {
            _descriptionController.text = aiResult.description!;
          }
          if (aiResult.categoryName != null) {
            _autoSelectCategoryByName(aiResult.categoryName!);
          }
          if (aiResult.paymentMethod != null) {
            _selectedPaymentMethod = aiResult.paymentMethod!;
          }
        });
      } else {
        // Fallback to basic voice parsing
        final voiceData = VoiceInputService.parseExpenseFromVoice(text);
        
        setState(() {
          if (voiceData['amount']?.isNotEmpty == true) {
            _amountController.text = voiceData['amount'];
          }
          if (voiceData['description']?.isNotEmpty == true) {
            _descriptionController.text = voiceData['description'];
          }
          if (voiceData['category'] != null) {
            _autoSelectCategoryByName(voiceData['category']);
          }
          if (voiceData['paymentMethod'] != null) {
            _selectedPaymentMethod = voiceData['paymentMethod'];
          }
        });
      }
      
      _showSnackBar('Voice input processed successfully!', AppTheme.success);
    } catch (e) {
      _showSnackBar('Failed to process voice input: $e', AppTheme.error);
    }
  }

  void _autoSelectCategoryByName(String categoryName) {
    final categoriesAsync = ref.read(categoriesProvider);
    if (categoriesAsync.value != null) {
      final category = categoriesAsync.value!.firstWhere(
        (cat) => cat.name.toLowerCase().contains(categoryName.toLowerCase()),
        orElse: () => categoriesAsync.value!.first,
      );
      _selectedCategoryId = category.id;
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    
    return Scaffold(
      backgroundColor: AppTheme.neutral50,
      appBar: AppBar(
        title: Text(
          widget.expense != null ? 'Edit Expense' : 'Add Expense',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppTheme.neutral900,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveExpense,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    'Save',
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
      body: categoriesAsync.when(
        data: (categories) => _buildForm(categories),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: AppTheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load categories',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.error,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.neutral600),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(categoriesProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForm(List<CategoryModel> categories) {
    final expenseCategories = categories
        .where((cat) => cat.name.toLowerCase() != 'income')
        .toList();
    
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Quick Input Actions
          _buildQuickActions(),
          
          const SizedBox(height: 32),
          
          // Amount Field
          _buildAmountField(),
          
          const SizedBox(height: 24),
          
          // Description Field
          _buildDescriptionField(),
          
          const SizedBox(height: 24),
          
          // Notes Field
          _buildNotesField(),
          
          const SizedBox(height: 32),
          
          // Category Selection
          _buildCategorySection(expenseCategories),
          
          const SizedBox(height: 32),
          
          // Payment Method
          _buildPaymentMethodSection(),
          
          const SizedBox(height: 32),
          
          // Date Selection
          _buildDateSection(),
          
          const SizedBox(height: 48),
          
          // Save Button
          _buildSaveButton(),
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
        boxShadow: DesignTokens.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Input',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.neutral800,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: _isProcessingOCR
                      ? Icons.hourglass_empty
                      : Icons.camera_alt,
                  label: _isProcessingOCR ? 'Processing...' : 'Scan Receipt',
                  onPressed: _isProcessingOCR ? null : _captureReceipt,
                  backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                  textColor: AppTheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.photo_library,
                  label: 'Gallery',
                  onPressed: _isProcessingOCR ? null : _pickReceiptFromGallery,
                  backgroundColor: AppTheme.warning.withValues(alpha: 0.1),
                  textColor: AppTheme.warning,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  icon: _isVoiceListening ? Icons.stop : Icons.mic,
                  label: _isVoiceListening ? 'Stop' : 'Voice',
                  onPressed: _startVoiceInput,
                  backgroundColor: _isVoiceListening
                      ? AppTheme.error.withValues(alpha: 0.1)
                      : AppTheme.success.withValues(alpha: 0.1),
                  textColor: _isVoiceListening ? AppTheme.error : AppTheme.success,
                ),
              ),
            ],
          ),
          if (_ocrExtractedText != null || _voiceExtractedText != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                border: Border.all(color: AppTheme.accent.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    _ocrExtractedText != null ? Icons.camera_alt : Icons.mic,
                    size: 16,
                    color: AppTheme.accent,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _ocrExtractedText != null
                          ? 'Data extracted from receipt'
                          : 'Data extracted from voice input',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.accent,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _ocrExtractedText = null;
                        _voiceExtractedText = null;
                      });
                    },
                    child: Icon(
                      Icons.close,
                      size: 16,
                      color: AppTheme.accent,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    required Color backgroundColor,
    required Color textColor,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      ),
    );
  }

  Widget _buildAmountField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
        boxShadow: DesignTokens.shadowSm,
      ),
      child: TextFormField(
        controller: _amountController,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textInputAction: TextInputAction.next,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: AppTheme.neutral900,
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter an amount';
          }
          final amount = double.tryParse(value);
          if (amount == null) {
            return 'Please enter a valid number';
          }
          if (amount <= 0) {
            return 'Amount must be greater than 0';
          }
          if (amount > AppConstants.maxExpenseAmount) {
            return 'Amount too large';
          }
          return null;
        },
        decoration: InputDecoration(
          labelText: 'Amount',
          hintText: 'Enter amount',
          prefixText: 'Rs. ',
          prefixStyle: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: AppTheme.neutral700,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.all(20),
        ),
      ),
    );
  }

  Widget _buildDescriptionField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
        boxShadow: DesignTokens.shadowSm,
      ),
      child: TextFormField(
        controller: _descriptionController,
        textInputAction: TextInputAction.next,
        maxLength: AppConstants.maxDescriptionLength,
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Please enter a description';
          }
          if (value.trim().length < 2) {
            return 'Description too short';
          }
          return null;
        },
        decoration: InputDecoration(
          labelText: 'Description',
          hintText: 'What did you spend on?',
          counterText: '',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.all(20),
        ),
      ),
    );
  }

  Widget _buildNotesField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
        boxShadow: DesignTokens.shadowSm,
      ),
      child: TextFormField(
        controller: _notesController,
        textInputAction: TextInputAction.done,
        maxLines: 3,
        decoration: InputDecoration(
          labelText: 'Notes (Optional)',
          hintText: 'Add additional notes...',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.all(20),
        ),
      ),
    );
  }

  Widget _buildCategorySection(List<CategoryModel> categories) {
    if (categories.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
          boxShadow: DesignTokens.shadowSm,
        ),
        child: Column(
          children: [
            Icon(
              Icons.category_outlined,
              size: 48,
              color: AppTheme.neutral400,
            ),
            const SizedBox(height: 16),
            Text(
              'No categories available',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.neutral700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please create categories first',
              style: TextStyle(
                color: AppTheme.neutral600,
              ),
            ),
          ],
        ),
      );
    }

    // Set default category if none selected
    if (_selectedCategoryId == null && categories.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _selectedCategoryId = categories.first.id;
        });
      });
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
        boxShadow: DesignTokens.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Category',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.neutral800,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: categories.map((category) {
              final isSelected = category.id == _selectedCategoryId;
              final categoryColor = Color(category.color);
              
              return GestureDetector(
                onTap: () => setState(() => _selectedCategoryId = category.id),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? categoryColor.withValues(alpha: 0.1)
                        : AppTheme.neutral100,
                    borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
                    border: Border.all(
                      color: isSelected ? categoryColor : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        category.icon,
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        category.name,
                        style: TextStyle(
                          color: isSelected
                              ? categoryColor
                              : AppTheme.neutral700,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
        boxShadow: DesignTokens.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Method',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.neutral800,
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedPaymentMethod,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
                borderSide: BorderSide(color: AppTheme.neutral300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
                borderSide: BorderSide(color: AppTheme.neutral300),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            items: AppConstants.paymentMethods.map((method) {
              return DropdownMenuItem(
                value: method,
                child: Row(
                  children: [
                    Icon(
                      _getPaymentMethodIcon(method),
                      size: 20,
                      color: AppTheme.neutral600,
                    ),
                    const SizedBox(width: 12),
                    Text(method),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedPaymentMethod = value);
              }
            },
          ),
        ],
      ),
    );
  }

  IconData _getPaymentMethodIcon(String method) {
    switch (method.toLowerCase()) {
      case 'cash':
        return Icons.money;
      case 'credit card':
        return Icons.credit_card;
      case 'debit card':
        return Icons.payment;
      case 'digital wallet':
        return Icons.account_balance_wallet;
      case 'bank transfer':
        return Icons.account_balance;
      default:
        return Icons.payment;
    }
  }

  Widget _buildDateSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
        boxShadow: DesignTokens.shadowSm,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
            ),
            child: Icon(
              Icons.calendar_today,
              color: AppTheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Date',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.neutral600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  Formatters.formatDate(_selectedDate),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.neutral900,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _selectDate,
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text(
              'Change',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveExpense,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
          ),
          disabledBackgroundColor: AppTheme.neutral300,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                widget.expense != null ? 'Update Expense' : 'Add Expense',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}