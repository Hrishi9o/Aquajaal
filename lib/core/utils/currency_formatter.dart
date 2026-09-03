import 'package:intl/intl.dart';

/// Formatter for Indian Rupee (INR) currency display matching exact ₹#,##,##0.00 pattern
class CurrencyFormatter {
  CurrencyFormatter._();

  // Pattern: ₹#,##,##0.00 (Indian locale, always 2 decimal places)
  static final NumberFormat _inrWithDecimals = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  /// Formats amount strictly with 2 decimal places e.g. ₹60.00, ₹1,00,000.50, ₹2,50,000.00
  static String format(num amount) {
    return _inrWithDecimals.format(amount);
  }

  /// Formats with 2 decimal digits e.g. ₹1,250.00
  static String formatDetailed(num amount) {
    return _inrWithDecimals.format(amount);
  }

  /// Compact format e.g. ₹25.0K, ₹1.2L, ₹1.0Cr
  static String formatCompact(num amount) {
    if (amount >= 10000000) {
      return '₹${(amount / 10000000).toStringAsFixed(1)} Cr';
    } else if (amount >= 100000) {
      return '₹${(amount / 100000).toStringAsFixed(1)} L';
    } else if (amount >= 1000) {
      return '₹${(amount / 1000).toStringAsFixed(1)} K';
    }
    return _inrWithDecimals.format(amount);
  }
}
