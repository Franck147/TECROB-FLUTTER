import 'package:intl/intl.dart';

class CurrencyFormatter {
  static String format(num? amount) {
    if (amount == null) return 'S/ 0.00';
    final formatter = NumberFormat.currency(
      locale: 'es_PE',
      symbol: 'S/ ',
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }
}
