/// Validation utility functions.
class Validators {
  Validators._();

  static String? validateRequired(String? value, [String fieldName = 'Field']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? validatePositiveNumber(String? value,
      [String fieldName = 'Value']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    final number = double.tryParse(value);
    if (number == null) {
      return 'Enter a valid number';
    }
    if (number < 0) {
      return '$fieldName must be zero or positive';
    }
    return null;
  }

  static String? validatePositiveInteger(String? value,
      [String fieldName = 'Value']) {
    if (value == null || value.trim().isEmpty) {
      return null; // Quantity can be empty (treated as 0)
    }
    final number = int.tryParse(value);
    if (number == null) {
      return 'Enter a valid whole number';
    }
    if (number < 0) {
      return '$fieldName must be zero or positive';
    }
    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Phone is optional
    }
    final cleaned = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (cleaned.length < 7 || cleaned.length > 15) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  static String? validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Username is required';
    }
    if (value.trim().length < 3) {
      return 'Username must be at least 3 characters';
    }
    if (!RegExp(r'^[a-zA-Z0-9._]+$').hasMatch(value.trim())) {
      return 'Username can only contain letters, numbers, dots, and underscores';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  static String? validateAmount(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Amount is required';
    }
    final number = double.tryParse(value);
    if (number == null) {
      return 'Enter a valid amount';
    }
    if (number <= 0) {
      return 'Amount must be greater than zero';
    }
    return null;
  }

  static String? validateRate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Rate is required';
    }
    final number = double.tryParse(value);
    if (number == null) {
      return 'Enter a valid rate';
    }
    if (number < 0) {
      return 'Rate must be zero or positive';
    }
    return null;
  }
}
