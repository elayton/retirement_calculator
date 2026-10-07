import 'package:intl/intl.dart';

/// Currency format used across the app (e.g. "$1,234.56").
final appCurrency = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

/// Currency format rounded to the nearest dollar (e.g. "$1,235").
final appCurrencyWhole = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

final _dateFormatter = DateFormat('yyyy-MM-dd');

/// Display format for account dates (e.g. "2026-10-06").
String formatDate(DateTime date) => _dateFormatter.format(date);

/// Formats accepted when parsing dates from portfolio files.
const dateParseFormats = <String>[
  'MMM d, yyyy',
  'MMM dd, yyyy',
  'MMM-d-yyyy',
  'MMM-dd-yyyy',
  'M/d/yyyy',
  'MM/dd/yyyy',
  'yyyy-MM-dd',
];
