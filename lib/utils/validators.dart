
/// 🔐 Comprehensive validation utilities for Finlytic
/// Handles form validation, data validation, and security checks
class Validators {
  // 📧 EMAIL VALIDATION
  
  static const String _emailPattern = 
      r'^[a-zA-Z0-9.!#$%&*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$';
  
  /// Validate email address
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    
    if (!RegExp(_emailPattern).hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    
    if (value.length > 254) {
      return 'Email address is too long';
    }
    
    return null;
  }
  
  /// Check if email is valid (returns boolean)
  static bool isValidEmail(String email) {
    return validateEmail(email) == null;
  }
  
  // 🔒 PASSWORD VALIDATION
  
  /// Validate password with comprehensive rules
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    
    if (value.length > 128) {
      return 'Password is too long (max 128 characters)';
    }
    
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }
    
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter';
    }
    
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }
    
    if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Password must contain at least one special character';
    }
    
    // Check for common weak patterns
    if (_isCommonWeakPassword(value)) {
      return 'This password is too common. Please choose a stronger password';
    }
    
    return null;
  }
  
  /// Validate password confirmation
  static String? validatePasswordConfirmation(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    
    if (value != password) {
      return 'Passwords do not match';
    }
    
    return null;
  }
  
  /// Calculate password strength (0-100)
  static int calculatePasswordStrength(String password) {
    if (password.isEmpty) return 0;
    
    int strength = 0;
    
    // Length bonus
    if (password.length >= 8) strength += 20;
    if (password.length >= 12) strength += 10;
    if (password.length >= 16) strength += 10;
    
    // Character variety
    if (password.contains(RegExp(r'[a-z]'))) strength += 10;
    if (password.contains(RegExp(r'[A-Z]'))) strength += 10;
    if (password.contains(RegExp(r'[0-9]'))) strength += 10;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength += 15;
    
    // Unique characters
    final uniqueChars = password.split('').toSet().length;
    if (uniqueChars >= 6) strength += 10;
    if (uniqueChars >= 10) strength += 5;
    
    // Deduct points for common patterns
    if (_containsSequentialChars(password)) strength -= 10;
    if (_containsRepeatedChars(password)) strength -= 10;
    if (_isCommonWeakPassword(password)) strength -= 20;
    
    return strength.clamp(0, 100);
  }
  
  /// Check for common weak passwords
  static bool _isCommonWeakPassword(String password) {
    final lowerPassword = password.toLowerCase();
    const commonPasswords = [
      'password', '123456', '123456789', 'qwerty', 'abc123',
      'password123', 'admin', 'letmein', 'welcome', 'monkey',
      'dragon', 'pass', 'master', 'hello', 'freedom'
    ];
    return commonPasswords.contains(lowerPassword);
  }
  
  /// Check for sequential characters
  static bool _containsSequentialChars(String password) {
    for (int i = 0; i < password.length - 2; i++) {
      final char1 = password.codeUnitAt(i);
      final char2 = password.codeUnitAt(i + 1);
      final char3 = password.codeUnitAt(i + 2);
      
      if (char2 == char1 + 1 && char3 == char2 + 1) {
        return true;
      }
    }
    return false;
  }
  
  /// Check for repeated characters
  static bool _containsRepeatedChars(String password) {
    for (int i = 0; i < password.length - 2; i++) {
      if (password[i] == password[i + 1] && password[i + 1] == password[i + 2]) {
        return true;
      }
    }
    return false;
  }
  
  // 📱 PHONE NUMBER VALIDATION
  
  /// Validate phone number (supports multiple formats)
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    
    // Remove all non-digit characters for validation
    final digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');
    
    if (digitsOnly.length < 10) {
      return 'Phone number must be at least 10 digits';
    }
    
    if (digitsOnly.length > 15) {
      return 'Phone number is too long';
    }
    
    // Specific validation for Nepali numbers
    if (digitsOnly.startsWith('977') || digitsOnly.startsWith('98')) {
      if (digitsOnly.length != 10 && digitsOnly.length != 13) {
        return 'Please enter a valid Nepali phone number';
      }
    }
    
    return null;
  }
  
  /// Format phone number for display
  static String formatPhoneNumber(String phoneNumber) {
    final digitsOnly = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    
    if (digitsOnly.length == 10) {
      // Nepali format: 98XX-XXX-XXX
      if (digitsOnly.startsWith('98')) {
        return '${digitsOnly.substring(0, 4)}-${digitsOnly.substring(4, 7)}-${digitsOnly.substring(7)}';
      }
      // US format: (XXX) XXX-XXXX
      return '(${digitsOnly.substring(0, 3)}) ${digitsOnly.substring(3, 6)}-${digitsOnly.substring(6)}';
    }
    
    return phoneNumber; // Return original if can't format
  }
  
  // 💰 FINANCIAL VALIDATION
  
  /// Validate expense amount
  static String? validateAmount(String? value, {double? minAmount, double? maxAmount}) {
    if (value == null || value.isEmpty) {
      return 'Amount is required';
    }
    
    final double? amount = double.tryParse(value);
    if (amount == null) {
      return 'Please enter a valid amount';
    }
    
    if (amount <= 0) {
      return 'Amount must be greater than zero';
    }
    
    if (minAmount != null && amount < minAmount) {
      return 'Amount must be at least ${minAmount.toStringAsFixed(2)}';
    }
    
    if (maxAmount != null && amount > maxAmount) {
      return 'Amount cannot exceed ${maxAmount.toStringAsFixed(2)}';
    }
    
    return null;
  }
  
  /// Validate budget amount
  static String? validateBudgetAmount(String? value) {
    return validateAmount(value, minAmount: 1.0, maxAmount: 10000000.0);
  }
  
  /// Validate expense description
  static String? validateDescription(String? value, {bool required = false}) {
    if (required && (value == null || value.isEmpty)) {
      return 'Description is required';
    }
    
    if (value != null && value.length > 200) {
      return 'Description is too long (max 200 characters)';
    }
    
    return null;
  }
  
  // 👤 PERSONAL INFORMATION VALIDATION
  
  /// Validate name
  static String? validateName(String? value, {bool required = true}) {
    if (required && (value == null || value.isEmpty)) {
      return 'Name is required';
    }
    
    if (value != null) {
      if (value.length < 2) {
        return 'Name must be at least 2 characters';
      }
      
      if (value.length > 50) {
        return 'Name is too long (max 50 characters)';
      }
      
      if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
        return 'Name can only contain letters and spaces';
      }
    }
    
    return null;
  }
  
  /// Validate age
  static String? validateAge(String? value) {
    if (value == null || value.isEmpty) {
      return 'Age is required';
    }
    
    final int? age = int.tryParse(value);
    if (age == null) {
      return 'Please enter a valid age';
    }
    
    if (age < 13) {
      return 'You must be at least 13 years old';
    }
    
    if (age > 120) {
      return 'Please enter a valid age';
    }
    
    return null;
  }
  
  // 🏷️ CATEGORY & TAGS VALIDATION
  
  /// Validate category name
  static String? validateCategoryName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Category name is required';
    }
    
    if (value.length < 2) {
      return 'Category name must be at least 2 characters';
    }
    
    if (value.length > 30) {
      return 'Category name is too long (max 30 characters)';
    }
    
    return null;
  }
  
  /// Validate budget period selection
  static String? validateBudgetPeriod(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please select a budget period';
    }
    
    const validPeriods = ['weekly', 'monthly', 'quarterly', 'yearly'];
    if (!validPeriods.contains(value.toLowerCase())) {
      return 'Please select a valid budget period';
    }
    
    return null;
  }
  
  // 📅 DATE VALIDATION
  
  /// Validate date
  static String? validateDate(DateTime? value, {DateTime? minDate, DateTime? maxDate}) {
    if (value == null) {
      return 'Date is required';
    }
    
    if (minDate != null && value.isBefore(minDate)) {
      return 'Date cannot be before ${minDate.day}/${minDate.month}/${minDate.year}';
    }
    
    if (maxDate != null && value.isAfter(maxDate)) {
      return 'Date cannot be after ${maxDate.day}/${maxDate.month}/${maxDate.year}';
    }
    
    return null;
  }
  
  /// Validate future date
  static String? validateFutureDate(DateTime? value) {
    final now = DateTime.now();
    return validateDate(value, minDate: now);
  }
  
  /// Validate past date
  static String? validatePastDate(DateTime? value) {
    final now = DateTime.now();
    return validateDate(value, maxDate: now);
  }
  
  // 🔒 SECURITY VALIDATION
  
  /// Validate PIN (4-6 digits)
  static String? validatePIN(String? value, {int length = 4}) {
    if (value == null || value.isEmpty) {
      return 'PIN is required';
    }
    
    if (value.length != length) {
      return 'PIN must be exactly $length digits';
    }
    
    if (!RegExp(r'^\d+$').hasMatch(value)) {
      return 'PIN can only contain numbers';
    }
    
    // Check for simple patterns
    if (_isSimplePIN(value)) {
      return 'Please choose a more secure PIN';
    }
    
    return null;
  }
  
  /// Check for simple PIN patterns
  static bool _isSimplePIN(String pin) {
    // All same digits
    if (RegExp(r'^(\d)\1+$').hasMatch(pin)) return true;
    
    // Sequential ascending
    bool isAscending = true;
    for (int i = 1; i < pin.length; i++) {
      if (int.parse(pin[i]) != int.parse(pin[i-1]) + 1) {
        isAscending = false;
        break;
      }
    }
    if (isAscending) return true;
    
    // Sequential descending
    bool isDescending = true;
    for (int i = 1; i < pin.length; i++) {
      if (int.parse(pin[i]) != int.parse(pin[i-1]) - 1) {
        isDescending = false;
        break;
      }
    }
    if (isDescending) return true;
    
    // Common patterns
    const commonPins = ['1234', '4321', '1111', '0000', '1212'];
    return commonPins.contains(pin);
  }
  
  // 🌐 GENERAL VALIDATION
  
  /// Validate required field
  static String? validateRequired(String? value, {String fieldName = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }
  
  /// Validate minimum length
  static String? validateMinLength(String? value, int minLength, {String fieldName = 'This field'}) {
    if (value == null || value.length < minLength) {
      return '$fieldName must be at least $minLength characters';
    }
    return null;
  }
  
  /// Validate maximum length
  static String? validateMaxLength(String? value, int maxLength, {String fieldName = 'This field'}) {
    if (value != null && value.length > maxLength) {
      return '$fieldName cannot exceed $maxLength characters';
    }
    return null;
  }
  
  /// Validate URL
  static String? validateURL(String? value, {bool required = false}) {
    if (!required && (value == null || value.isEmpty)) {
      return null;
    }
    
    if (value == null || value.isEmpty) {
      return 'URL is required';
    }
    
    final urlPattern = RegExp(
      r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$'
    );
    
    if (!urlPattern.hasMatch(value)) {
      return 'Please enter a valid URL';
    }
    
    return null;
  }
}

/// Extension methods for convenient validation
extension ValidationExtension on String? {
  String? validateEmail() => Validators.validateEmail(this);
  String? validatePassword() => Validators.validatePassword(this);
  String? validatePhoneNumber() => Validators.validatePhoneNumber(this);
  String? validateName() => Validators.validateName(this);
  String? validateAmount() => Validators.validateAmount(this);
  String? validateRequired([String fieldName = 'This field']) => Validators.validateRequired(this, fieldName: fieldName);
  String? validateMinLength(int minLength, [String fieldName = 'This field']) => Validators.validateMinLength(this, minLength, fieldName: fieldName);
  String? validateMaxLength(int maxLength, [String fieldName = 'This field']) => Validators.validateMaxLength(this, maxLength, fieldName: fieldName);
  String? validateURL({bool required = false}) => Validators.validateURL(this, required: required);
}