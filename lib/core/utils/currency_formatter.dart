import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
    decimalDigits: 2,
  );

  static String format(double value) {
    return _currencyFormat.format(value);
  }

  static String formatReal(double value) {
    return _currencyFormat.format(value);
  }

  static String formatWeight(double weightInKg) {
    if (weightInKg < 1.0) {
      final grams = (weightInKg * 1000).toInt();
      return '${grams}g';
    }
    return '${weightInKg.toStringAsFixed(3).replaceAll('.', ',')} kg';
  }
}
