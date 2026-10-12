import 'package:intl/intl.dart';

class PriceFormatter {
  PriceFormatter._();

  static final _fmt = NumberFormat.currency(
    locale: 'fr_FR',
    symbol: 'FCFA',
    decimalDigits: 0,
  );

  /// Retourne un prix formaté, ex : "150 000 FCFA"
  static String format(num price) => _fmt.format(price);
}
