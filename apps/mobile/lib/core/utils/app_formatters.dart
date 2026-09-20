import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../features/auth/presentation/auth_controller.dart';
// ignore: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:html' as html;

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

  /// Downloads/saves a file directly to the user's browser/device Downloads folder
  static void saveFile({
    required String filename,
    required List<int> bytes,
    required String mimeType,
  }) {
    try {
      final base64Content = base64Encode(bytes);
      final anchor = html.AnchorElement(
        href: 'data:$mimeType;base64,$base64Content',
      )
        ..setAttribute('download', filename)
        ..style.display = 'none';

      html.document.body?.children.add(anchor);
      anchor.click();
      html.document.body?.children.remove(anchor);
    } catch (e) {
      // Fallback using Blob URL
      try {
        final blob = html.Blob([bytes], mimeType);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', filename)
          ..style.display = 'none';
        html.document.body?.children.add(anchor);
        anchor.click();
        html.document.body?.children.remove(anchor);
        html.Url.revokeObjectUrl(url);
      } catch (_) {}
    }
  }

  /// Opens an HTML printable statement in a new window and triggers window.print() (Save as PDF)
  static void openPrintableHtml({
    required String title,
    required String htmlContent,
  }) {
    try {
      final fullHtml = '''
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8">
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
    <title>$title</title>
    <style>
      body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif; padding: 40px; color: #1e293b; line-height: 1.5; }
      .header { display: flex; justify-content: space-between; align-items: center; border-bottom: 2px solid #0f766e; padding-bottom: 16px; margin-bottom: 24px; }
      .brand { font-size: 24px; font-weight: 800; color: #0f766e; letter-spacing: -0.5px; }
      .date { font-size: 13px; color: #64748b; }
      .card { background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 12px; padding: 20px; margin-bottom: 20px; }
      .title { font-size: 13px; font-weight: 700; color: #475569; text-transform: uppercase; letter-spacing: 0.5px; margin-bottom: 12px; }
      .amount-hero { font-size: 32px; font-weight: 900; color: #0f766e; margin-bottom: 8px; }
      .stat-grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 16px; margin-top: 12px; }
      .stat-label { font-size: 12px; color: #64748b; margin-bottom: 2px; }
      .stat-val { font-size: 16px; font-weight: 700; color: #0f172a; }
      table { width: 100%; border-collapse: collapse; margin-top: 12px; }
      th { text-align: left; padding: 10px 12px; background: #e2e8f0; font-size: 12px; font-weight: 700; color: #334155; }
      td { padding: 10px 12px; border-bottom: 1px solid #e2e8f0; font-size: 13px; color: #1e293b; }
      .badge { display: inline-block; padding: 3px 8px; border-radius: 6px; font-size: 11px; font-weight: 700; background: #d1fae5; color: #065f46; }
      @media print {
        body { padding: 0; }
        button { display: none; }
      }
    </style>
  </head>
  <body>
    $htmlContent
    <script>
      window.onload = function() {
        window.print();
      };
    </script>
  </body>
</html>
''';

      final blob = html.Blob([utf8.encode(fullHtml)], 'text/html;charset=utf-8');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.window.open(url, '_blank');
    } catch (_) {}
  }
}
