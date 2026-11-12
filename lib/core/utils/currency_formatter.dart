import 'package:intl/intl.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  static final NumberFormat _usdFormat = NumberFormat.currency(
    symbol: '\$',
    decimalDigits: 2,
  );

  static String _symbolFor(String currency) {
    return switch (currency.toUpperCase()) {
      'EUR' => '€',
      'GBP' => '£',
      'CAD' => 'CA\$',
      'AUD' => 'A\$',
      'JPY' => '¥',
      _ => '\$',
    };
  }

  static String formatUsd(num amount) {
    return _usdFormat.format(amount);
  }

  static String formatAmount(num amount, {String currency = 'USD'}) {
    final formatter = NumberFormat.currency(
      symbol: _symbolFor(currency),
      decimalDigits: currency.toUpperCase() == 'JPY' ? 0 : 2,
    );
    return formatter.format(amount);
  }

  static String formatVariance(num amount, {String currency = 'USD'}) {
    final prefix = amount > 0 ? '+' : '';
    return '$prefix${formatAmount(amount, currency: currency)}';
  }
}
