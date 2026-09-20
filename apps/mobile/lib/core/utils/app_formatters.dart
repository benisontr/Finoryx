import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../features/auth/presentation/auth_controller.dart';
final userCurrencySymbolProvider = Provider<String>((ref) {
  final user = ref.watch(authNotifierProvider).user;
  return AppFormatters.symbolForCurrency(user?.baseCurrency);
});

class AppFormatters {
  AppFormatters._();

  static final Map<String, NumberFormat> _currencyFormatters = {};
  static final DateFormat _defaultDateFormat = DateFormat.yMMMMd();
  static final DateFormat _shortDateFormat = DateFormat.MMMd();
  static final DateFormat _monthYearFormat = DateFormat.yMMMM();

  /// Resolves currency symbol from ISO currency code (e.g. INR -> ₹, USD -> $, EUR -> €)
  static String symbolForCurrency(String? currencyCode) {
    switch (currencyCode?.toUpperCase()) {
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'JPY':
        return '¥';
      case 'CAD':
        return 'CA\$';
      case 'AUD':
        return 'AU\$';
      case 'INR':
      default:
        return '₹';
    }
  }

  static NumberFormat _getCurrencyFormatter(String symbol, int decimals) {
    final key = '$symbol-$decimals';
    return _currencyFormatters.putIfAbsent(
      key,
      () => NumberFormat.currency(symbol: symbol, decimalDigits: decimals),
    );
  }

  /// Formats currency with customizable symbol (default: '₹') and decimals (default: 2)
  static String currency(
    num amount, {
    String symbol = '₹',
    int decimalDigits = 2,
  }) {
    return _getCurrencyFormatter(symbol, decimalDigits).format(amount);
  }

  /// Formats percentage (e.g. 75.456 -> 75.5%)
  static String percentage(num value, {int decimalDigits = 1}) {
    return '${value.toStringAsFixed(decimalDigits)}%';
  }

  /// Compact number formatter (e.g. 1.2K, 3.4M)
  static String compactCurrency(
    num amount, {
    String symbol = '₹',
  }) {
    final compact = NumberFormat.compact().format(amount);
    return '$symbol$compact';
  }

  /// Format date as: MMM d (e.g., Sep 19)
  static String shortDate(DateTime date) {
    return _shortDateFormat.format(date);
  }

  /// Format date as: MMMM d, y (e.g., September 19, 2026)
  static String fullDate(DateTime date) {
    return _defaultDateFormat.format(date);
  }

  /// Format date as: MMMM y (e.g., September 2026)
  static String monthYear(DateTime date) {
    return _monthYearFormat.format(date);
  }

  /// Downloads/saves a statement or report file safely
  static void saveFile({
    required String filename,
    required List<int> bytes,
    required String mimeType,
  }) {
    // Platform-agnostic file handling placeholder (supports future cross-platform file saving plugins)
  }

  /// Opens an HTML printable statement in a new window or system viewer
  static void openPrintableHtml({
    required String title,
    required String htmlContent,
  }) {
    // Platform-agnostic printing placeholder
  }
}
