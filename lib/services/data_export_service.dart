import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/expense_model.dart';
import '../models/budget_model.dart';
import '../models/category_model.dart';
import '../models/user_model.dart';
import '../utils/formatters.dart';
import '../utils/constants.dart';

/// 📤 Data Export Service
/// Handles exporting user data in various formats (JSON, CSV, PDF)
class DataExportService {
  static final DataExportService _instance = DataExportService._internal();
  factory DataExportService() => _instance;
  DataExportService._internal();

  // === JSON Export ===

  /// Export all user data to JSON
  Future<ExportResult> exportToJSON({
    required UserModel user,
    required List<ExpenseModel> expenses,
    required List<BudgetModel> budgets,
    required List<CategoryModel> categories,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // Filter expenses by date if specified
      List<ExpenseModel> filteredExpenses = expenses;
      if (startDate != null || endDate != null) {
        filteredExpenses = expenses.where((expense) {
          if (startDate != null && expense.transactionDate.isBefore(startDate)) {
            return false;
          }
          if (endDate != null && expense.transactionDate.isAfter(endDate)) {
            return false;
          }
          return true;
        }).toList();
      }

      final exportData = {
        'metadata': {
          'exportedAt': DateTime.now().toIso8601String(),
          'appVersion': AppConstants.appVersion,
          'dataVersion': '1.0',
          'userId': user.id,
          'userEmail': user.email,
          'currency': user.currency,
          'startDate': startDate?.toIso8601String(),
          'endDate': endDate?.toIso8601String(),
        },
        'user': user.toJson(),
        'expenses': filteredExpenses.map((e) => e.toJson()).toList(),
        'budgets': budgets.map((b) => b.toJson()).toList(),
        'categories': categories.map((c) => c.toJson()).toList(),
        'statistics': _generateStatistics(filteredExpenses, budgets),
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);
      final fileName = 'finlytic_export_${DateTime.now().millisecondsSinceEpoch}.json';
      
      final file = await _saveToFile(jsonString, fileName);
      
      return ExportResult(
        success: true,
        message: 'Data exported successfully to JSON',
        filePath: file.path,
        fileName: fileName,
        fileSize: jsonString.length,
        format: ExportFormat.json,
        recordCount: filteredExpenses.length,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ JSON export failed: $e');
      }
      return ExportResult(
        success: false,
        message: 'Failed to export to JSON: ${e.toString()}',
        format: ExportFormat.json,
      );
    }
  }

  // === CSV Export ===

  /// Export expenses to CSV
  Future<ExportResult> exportExpensesToCSV({
    required List<ExpenseModel> expenses,
    required List<CategoryModel> categories,
    required String currency,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // Filter expenses by date
      List<ExpenseModel> filteredExpenses = expenses;
      if (startDate != null || endDate != null) {
        filteredExpenses = expenses.where((expense) {
          if (startDate != null && expense.transactionDate.isBefore(startDate)) {
            return false;
          }
          if (endDate != null && expense.transactionDate.isAfter(endDate)) {
            return false;
          }
          return true;
        }).toList();
      }

      // Create category lookup map
      final categoryMap = {
        for (var category in categories) category.id: category.name
      };

      // Generate CSV content
      final csvLines = <String>[];
      
      // Header row
      csvLines.add('Date,Description,Category,Amount,Payment Method,Type,Notes');
      
      // Data rows
      for (final expense in filteredExpenses) {
        final categoryName = categoryMap[expense.categoryId] ?? 'Unknown';
        final formattedDate = expense.transactionDate.toDisplayDate();
        final formattedAmount = expense.amount.toStringAsFixed(2);
        final type = expense.type == ExpenseType.income ? 'Income' : 'Expense';
        
        // Escape CSV values
        final description = _escapeCsvValue(expense.description);
        final category = _escapeCsvValue(categoryName);
        final paymentMethod = _escapeCsvValue(expense.paymentMethod);
        final notes = _escapeCsvValue(expense.notes ?? '');
        
        csvLines.add('$formattedDate,$description,$category,$formattedAmount,$paymentMethod,$type,$notes');
      }

      final csvContent = csvLines.join('\n');
      final fileName = 'finlytic_expenses_${DateTime.now().millisecondsSinceEpoch}.csv';
      
      final file = await _saveToFile(csvContent, fileName);
      
      return ExportResult(
        success: true,
        message: 'Expenses exported successfully to CSV',
        filePath: file.path,
        fileName: fileName,
        fileSize: csvContent.length,
        format: ExportFormat.csv,
        recordCount: filteredExpenses.length,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ CSV export failed: $e');
      }
      return ExportResult(
        success: false,
        message: 'Failed to export to CSV: ${e.toString()}',
        format: ExportFormat.csv,
      );
    }
  }

  /// Export budgets to CSV
  Future<ExportResult> exportBudgetsToCSV({
    required List<BudgetModel> budgets,
    required List<CategoryModel> categories,
    required String currency,
  }) async {
    try {
      final categoryMap = {
        for (var category in categories) category.id: category.name
      };

      final csvLines = <String>[];
      csvLines.add('Category,Amount,Period,Start Date,End Date,Alert Threshold,Status');
      
      for (final budget in budgets) {
        final categoryName = categoryMap[budget.categoryId] ?? 'Unknown';
        final formattedAmount = budget.amount.toStringAsFixed(2);
        final period = budget.period.toString().split('.').last;
        final startDate = budget.startDate.toDisplayDate();
        final endDate = budget.endDate.toDisplayDate();
        final alertThreshold = '${(budget.alertThreshold * 100).toInt()}%';
        final status = budget.isActive ? 'Active' : 'Inactive';
        
        final category = _escapeCsvValue(categoryName);
        
        csvLines.add('$category,$formattedAmount,$period,$startDate,$endDate,$alertThreshold,$status');
      }

      final csvContent = csvLines.join('\n');
      final fileName = 'finlytic_budgets_${DateTime.now().millisecondsSinceEpoch}.csv';
      
      final file = await _saveToFile(csvContent, fileName);
      
      return ExportResult(
        success: true,
        message: 'Budgets exported successfully to CSV',
        filePath: file.path,
        fileName: fileName,
        fileSize: csvContent.length,
        format: ExportFormat.csv,
        recordCount: budgets.length,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Budget CSV export failed: $e');
      }
      return ExportResult(
        success: false,
        message: 'Failed to export budgets to CSV: ${e.toString()}',
        format: ExportFormat.csv,
      );
    }
  }

  // === PDF Export (Simplified) ===

  /// Export expense report to PDF (basic implementation)
  Future<ExportResult> exportToPDF({
    required UserModel user,
    required List<ExpenseModel> expenses,
    required List<CategoryModel> categories,
    DateTime? startDate,
    DateTime? endDate,
    String reportTitle = 'Expense Report',
  }) async {
    try {
      // For now, create a text-based report that can be converted to PDF
      // In a full implementation, you'd use packages like pdf or printing
      
      final report = _generateTextReport(
        user: user,
        expenses: expenses,
        categories: categories,
        startDate: startDate,
        endDate: endDate,
        title: reportTitle,
      );

      final fileName = 'finlytic_report_${DateTime.now().millisecondsSinceEpoch}.txt';
      final file = await _saveToFile(report, fileName);
      
      return ExportResult(
        success: true,
        message: 'Report generated successfully (PDF support coming soon)',
        filePath: file.path,
        fileName: fileName,
        fileSize: report.length,
        format: ExportFormat.pdf,
        recordCount: expenses.length,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ PDF export failed: $e');
      }
      return ExportResult(
        success: false,
        message: 'Failed to generate report: ${e.toString()}',
        format: ExportFormat.pdf,
      );
    }
  }

  // === Backup & Restore ===

  /// Create complete backup of user data
  Future<ExportResult> createBackup({
    required UserModel user,
    required List<ExpenseModel> expenses,
    required List<BudgetModel> budgets,
    required List<CategoryModel> categories,
  }) async {
    try {
      final backupData = {
        'metadata': {
          'backupCreatedAt': DateTime.now().toIso8601String(),
          'appVersion': AppConstants.appVersion,
          'backupVersion': '1.0',
          'userId': user.id,
          'userEmail': user.email,
        },
        'user': user.toJson(),
        'expenses': expenses.map((e) => e.toJson()).toList(),
        'budgets': budgets.map((b) => b.toJson()).toList(),
        'categories': categories.map((c) => c.toJson()).toList(),
      };

      final backupString = const JsonEncoder.withIndent('  ').convert(backupData);
      final fileName = 'finlytic_backup_${DateTime.now().millisecondsSinceEpoch}.backup';
      
      final file = await _saveToFile(backupString, fileName);
      
      return ExportResult(
        success: true,
        message: 'Backup created successfully',
        filePath: file.path,
        fileName: fileName,
        fileSize: backupString.length,
        format: ExportFormat.backup,
        recordCount: expenses.length + budgets.length + categories.length,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Backup creation failed: $e');
      }
      return ExportResult(
        success: false,
        message: 'Failed to create backup: ${e.toString()}',
        format: ExportFormat.backup,
      );
    }
  }

  // === Sharing ===

  /// Share exported file
  Future<void> shareFile(String filePath, {String? subject}) async {
    try {
      await Share.shareXFiles(
        [XFile(filePath)],
        subject: subject ?? 'Finlytic Export',
        text: 'Your financial data export from Finlytic',
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ File sharing failed: $e');
      }
      rethrow;
    }
  }

  // === Helper Methods ===

  /// Save content to file
  Future<File> _saveToFile(String content, String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$fileName');
    return await file.writeAsString(content);
  }

  /// Escape CSV values
  String _escapeCsvValue(String value) {
    if (value.contains(',') || value.contains('\n') || value.contains('"')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  /// Generate statistics for export
  Map<String, dynamic> _generateStatistics(List<ExpenseModel> expenses, List<BudgetModel> budgets) {
    final totalExpenses = expenses.where((e) => e.type == ExpenseType.expense).fold(0.0, (sum, e) => sum + e.amount);
    final totalIncome = expenses.where((e) => e.type == ExpenseType.income).fold(0.0, (sum, e) => sum + e.amount);
    final totalBudgets = budgets.fold(0.0, (sum, b) => sum + b.amount);
    
    return {
      'totalExpenses': totalExpenses,
      'totalIncome': totalIncome,
      'netAmount': totalIncome - totalExpenses,
      'totalBudgets': totalBudgets,
      'expenseCount': expenses.where((e) => e.type == ExpenseType.expense).length,
      'incomeCount': expenses.where((e) => e.type == ExpenseType.income).length,
      'budgetCount': budgets.length,
    };
  }

  /// Generate text-based report
  String _generateTextReport({
    required UserModel user,
    required List<ExpenseModel> expenses,
    required List<CategoryModel> categories,
    DateTime? startDate,
    DateTime? endDate,
    required String title,
  }) {
    final buffer = StringBuffer();
    
    // Header
    buffer.writeln('=' * 50);
    buffer.writeln(title.toUpperCase());
    buffer.writeln('=' * 50);
    buffer.writeln('Generated: ${DateTime.now().toDisplayDate()}');
    buffer.writeln('User: ${user.name} (${user.email})');
    buffer.writeln('Currency: ${user.currency}');
    
    if (startDate != null || endDate != null) {
      buffer.writeln('Period: ${startDate?.toDisplayDate() ?? 'All time'} - ${endDate?.toDisplayDate() ?? 'Present'}');
    }
    
    buffer.writeln();
    
    // Statistics
    final stats = _generateStatistics(expenses, []);
    buffer.writeln('SUMMARY');
    buffer.writeln('-' * 20);
    buffer.writeln('Total Expenses: ${stats['totalExpenses'].toStringAsFixed(2)} ${user.currency}');
    buffer.writeln('Total Income: ${stats['totalIncome'].toStringAsFixed(2)} ${user.currency}');
    buffer.writeln('Net Amount: ${stats['netAmount'].toStringAsFixed(2)} ${user.currency}');
    buffer.writeln('Number of Transactions: ${expenses.length}');
    buffer.writeln();
    
    // Category breakdown
    final categoryMap = {for (var cat in categories) cat.id: cat.name};
    final categoryTotals = <String, double>{};
    
    for (final expense in expenses) {
      if (expense.type == ExpenseType.expense) {
        final categoryName = categoryMap[expense.categoryId] ?? 'Unknown';
        categoryTotals[categoryName] = (categoryTotals[categoryName] ?? 0) + expense.amount;
      }
    }
    
    if (categoryTotals.isNotEmpty) {
      buffer.writeln('EXPENSES BY CATEGORY');
      buffer.writeln('-' * 30);
      
      final sortedCategories = categoryTotals.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      for (final entry in sortedCategories) {
        buffer.writeln('${entry.key}: ${entry.value.toStringAsFixed(2)} ${user.currency}');
      }
      buffer.writeln();
    }
    
    // Recent transactions
    final recentExpenses = expenses.take(20).toList();
    if (recentExpenses.isNotEmpty) {
      buffer.writeln('RECENT TRANSACTIONS');
      buffer.writeln('-' * 30);
      
      for (final expense in recentExpenses) {
        final categoryName = categoryMap[expense.categoryId] ?? 'Unknown';
        final sign = expense.type == ExpenseType.income ? '+' : '-';
        buffer.writeln('${expense.transactionDate.toDisplayDate()}: $sign${expense.amount.toStringAsFixed(2)} ${user.currency} - ${expense.description} ($categoryName)');
      }
    }
    
    buffer.writeln();
    buffer.writeln('Report generated by Finlytic v${AppConstants.appVersion}');
    
    return buffer.toString();
  }

  /// Export complete data package
  Future<File?> exportCompleteDataPackage({
    required List<ExpenseModel> expenses,
    required List<BudgetModel> budgets,
    required List<CategoryModel> categories,
  }) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final directory = await getApplicationDocumentsDirectory();
      final exportsDir = Directory('${directory.path}/exports');
      
      if (!await exportsDir.exists()) {
        await exportsDir.create(recursive: true);
      }
      
      final summaryContent = 'Finlytic Complete Data Export\nGenerated: ${Formatters.formatDisplayDate(DateTime.now())}\nExpenses: ${expenses.length}\nBudgets: ${budgets.length}\nCategories: ${categories.length}';
      final summaryFile = File('${exportsDir.path}/complete_export_$timestamp.txt');
      await summaryFile.writeAsString(summaryContent);

      return summaryFile;
    } catch (e) {
      return null;
    }
  }
}

/// Export result information
class ExportResult {
  final bool success;
  final String message;
  final String? filePath;
  final String? fileName;
  final int? fileSize;
  final ExportFormat format;
  final int recordCount;

  ExportResult({
    required this.success,
    required this.message,
    this.filePath,
    this.fileName,
    this.fileSize,
    required this.format,
    this.recordCount = 0,
  });

  /// Get human-readable file size
  String get formattedFileSize {
    if (fileSize == null) return 'Unknown';
    return Formatters.formatFileSize(fileSize!);
  }

  @override
  String toString() {
    return 'ExportResult{success: $success, message: $message, format: $format, records: $recordCount}';
  }
}

/// Export format enumeration
enum ExportFormat {
  json,
  csv,
  pdf,
  backup,
}

/// Extension for export format
extension ExportFormatExtension on ExportFormat {
  String get displayName {
    switch (this) {
      case ExportFormat.json:
        return 'JSON';
      case ExportFormat.csv:
        return 'CSV';
      case ExportFormat.pdf:
        return 'PDF';
      case ExportFormat.backup:
        return 'Backup';
    }
  }

  String get fileExtension {
    switch (this) {
      case ExportFormat.json:
        return '.json';
      case ExportFormat.csv:
        return '.csv';
      case ExportFormat.pdf:
        return '.pdf';
      case ExportFormat.backup:
        return '.backup';
    }
  }

  String get mimeType {
    switch (this) {
      case ExportFormat.json:
        return 'application/json';
      case ExportFormat.csv:
        return 'text/csv';
      case ExportFormat.pdf:
        return 'application/pdf';
      case ExportFormat.backup:
        return 'application/octet-stream';
    }
  }

}
