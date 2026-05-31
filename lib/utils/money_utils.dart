import 'package:intl/intl.dart';

/// Money/currency utility functions.
class MoneyUtils {
  MoneyUtils._();

  /// Formats amount with currency symbol: "$ 1,530.00"
  static String formatCurrency(double amount, [String symbol = '\$']) {
    final formatter = NumberFormat('#,##0.00');
    return '$symbol ${formatter.format(amount)}';
  }

  /// Formats amount without decimals if whole number: "$ 1,530"
  static String formatCurrencyCompact(double amount, [String symbol = '\$']) {
    if (amount == amount.roundToDouble()) {
      final formatter = NumberFormat('#,##0');
      return '$symbol ${formatter.format(amount)}';
    }
    return formatCurrency(amount, symbol);
  }

  /// Calculates line total: quantity × rate.
  static double calculateLineTotal(int quantity, double rate) {
    return quantity * rate;
  }

  /// Calculates final payable balance.
  /// finalPayable = grossProduction + totalBonus - totalAdvance - totalPartialPayment - totalFinalPayment - totalDeduction
  static double calculateFinalPayable({
    required double grossProduction,
    required double totalBonus,
    required double totalAdvance,
    required double totalPartialPayment,
    required double totalFinalPayment,
    required double totalDeduction,
  }) {
    return grossProduction +
        totalBonus -
        totalAdvance -
        totalPartialPayment -
        totalFinalPayment -
        totalDeduction;
  }
}
