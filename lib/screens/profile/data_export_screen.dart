import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/expense_provider.dart';
import '../../providers/budget_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/data_export_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/design_tokens.dart';
import '../../utils/formatters.dart';
import '../../widgets/cards.dart';

class DataExportScreen extends ConsumerStatefulWidget {
  const DataExportScreen({super.key});

  @override
  ConsumerState<DataExportScreen> createState() => _DataExportScreenState();
}

class _DataExportScreenState extends ConsumerState<DataExportScreen> {
  final _exportService = DataExportService();
  bool _isExporting = false;
  ExportFormat _selectedFormat = ExportFormat.json;
  DateTime? _startDate;
  DateTime? _endDate;
  
  final List<ExportFormat> _formats = [
    ExportFormat.json,
    ExportFormat.csv,
    ExportFormat.pdf,
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: AppTheme.neutral50,
      appBar: AppBar(
        title: const Text(
          'Export Data',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppTheme.neutral900,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Export Format Selection
            _buildSectionTitle('Export Format'),
            _buildFormatSelection(),
            
            const SizedBox(height: 32),
            
            // Date Range Selection
            _buildSectionTitle('Date Range (Optional)'),
            _buildDateRangeSelection(),
            
            const SizedBox(height: 32),
            
            // Export Options
            _buildSectionTitle('Export Options'),
            _buildExportOptions(),
            
            const SizedBox(height: 48),
            
            // Export Button
            _buildExportButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppTheme.neutral900,
        ),
      ),
    );
  }

  Widget _buildFormatSelection() {
    return AppCard(
      child: Column(
        children: _formats.map((format) {
          final isSelected = format == _selectedFormat;
          return RadioListTile<ExportFormat>(
            value: format,
            groupValue: _selectedFormat,
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedFormat = value);
              }
            },
            title: Text(
              format.displayName,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: AppTheme.neutral900,
              ),
            ),
            subtitle: Text(
              _getFormatDescription(format),
              style: TextStyle(
                color: AppTheme.neutral600,
              ),
            ),
            secondary: Icon(
              _getFormatIcon(format),
              color: isSelected ? AppTheme.primary : AppTheme.neutral500,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDateRangeSelection() {
    return AppCard(
      child: Column(
        children: [
          ListTile(
            leading: Icon(
              Icons.date_range,
              color: AppTheme.primary,
            ),
            title: const Text(
              'Start Date',
              style: TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              _startDate != null
                  ? Formatters.formatDate(_startDate!)
                  : 'All time',
              style: TextStyle(color: AppTheme.neutral600),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _selectStartDate(),
          ),
          const Divider(),
          ListTile(
            leading: Icon(
              Icons.date_range,
              color: AppTheme.primary,
            ),
            title: const Text(
              'End Date',
              style: TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              _endDate != null
                  ? Formatters.formatDate(_endDate!)
                  : 'Present',
              style: TextStyle(color: AppTheme.neutral600),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _selectEndDate(),
          ),
          if (_startDate != null || _endDate != null) ...[
            const Divider(),
            ListTile(
              leading: Icon(
                Icons.clear,
                color: AppTheme.error,
              ),
              title: Text(
                'Clear Date Range',
                style: TextStyle(
                  color: AppTheme.error,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () {
                setState(() {
                  _startDate = null;
                  _endDate = null;
                });
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExportOptions() {
    return AppCard(
      child: Column(
        children: [
          ListTile(
            leading: Icon(
              Icons.info_outline,
              color: AppTheme.accent,
            ),
            title: const Text(
              'Export includes',
              style: TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: const Text(
              'All expenses, budgets, categories, and financial data',
            ),
          ),
          const Divider(),
          ListTile(
            leading: Icon(
              Icons.security,
              color: AppTheme.success,
            ),
            title: const Text(
              'Data Privacy',
              style: TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: const Text(
              'Your data is exported locally and securely',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _isExporting ? null : _exportData,
        icon: _isExporting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.download),
        label: Text(
          _isExporting ? 'Exporting...' : 'Export Data',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
          ),
        ),
      ),
    );
  }

  String _getFormatDescription(ExportFormat format) {
    switch (format) {
      case ExportFormat.json:
        return 'Complete data structure, best for backup';
      case ExportFormat.csv:
        return 'Spreadsheet format, easy to analyze';
      case ExportFormat.pdf:
        return 'Formatted report, ready to share';
      case ExportFormat.backup:
        return 'Complete app backup for restore';
    }
  }

  IconData _getFormatIcon(ExportFormat format) {
    switch (format) {
      case ExportFormat.json:
        return Icons.code;
      case ExportFormat.csv:
        return Icons.table_chart;
      case ExportFormat.pdf:
        return Icons.picture_as_pdf;
      case ExportFormat.backup:
        return Icons.backup;
    }
  }

  Future<void> _selectStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now().subtract(const Duration(days: 30)),
      firstDate: DateTime(2020),
      lastDate: _endDate ?? DateTime.now(),
    );
    if (date != null) {
      setState(() => _startDate = date);
    }
  }

  Future<void> _selectEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() => _endDate = date);
    }
  }

  Future<void> _exportData() async {
    setState(() => _isExporting = true);

    try {
      final user = ref.read(userProvider).value;
      final expensesAsync = ref.read(expensesProvider);
      final budgetsAsync = ref.read(budgetsProvider);
      final categoriesAsync = ref.read(categoriesProvider);

      if (user == null) {
        throw Exception('User not authenticated');
      }

      if (!expensesAsync.hasValue || !budgetsAsync.hasValue || !categoriesAsync.hasValue) {
        throw Exception('Data not loaded');
      }

      final expenses = expensesAsync.value!;
      final budgets = budgetsAsync.value!;
      final categories = categoriesAsync.value!;

      ExportResult result;

      switch (_selectedFormat) {
        case ExportFormat.json:
          result = await _exportService.exportToJSON(
            user: user,
            expenses: expenses,
            budgets: budgets,
            categories: categories,
            startDate: _startDate,
            endDate: _endDate,
          );
          break;
        case ExportFormat.csv:
          result = await _exportService.exportExpensesToCSV(
            expenses: expenses,
            categories: categories,
            currency: user.currency,
            startDate: _startDate,
            endDate: _endDate,
          );
          break;
        case ExportFormat.pdf:
          result = await _exportService.exportToPDF(
            user: user,
            expenses: expenses,
            categories: categories,
            reportTitle: 'Financial Report',
            startDate: _startDate,
            endDate: _endDate,
          );
          break;
        case ExportFormat.backup:
          result = await _exportService.createBackup(
            user: user,
            expenses: expenses,
            budgets: budgets,
            categories: categories,
          );
          break;
      }

      if (result.success && result.filePath != null) {
        // Share the exported file
        await _exportService.shareFile(
          result.filePath!,
          subject: 'Finlytic Data Export',
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Export Successful!',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${result.recordCount} records exported',
                    style: const TextStyle(fontSize: 12),
                  ),
                  Text(
                    'File size: ${result.formattedFileSize}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
              backgroundColor: AppTheme.success,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } else {
        throw Exception(result.message);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }
}
