import 'package:intl/intl.dart';

final _appCurrency = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

/// Currency format used across the app, rounded to the nearest dollar (e.g. "$1,235").
String formatCurrency(num value) => _appCurrency.format(value);

/// Percent format used for tax bracket rates, which are always whole numbers
/// (e.g. "22%").
String formatPercent(num value) => '${value.toStringAsFixed(0)}%';

final _dateFormatter = DateFormat('yyyy-MM-dd');

/// Display format for account dates (e.g. "2026-10-06").
String formatDate(DateTime date) => _dateFormatter.format(date);

/// Formats accepted when parsing dates from portfolio files.
const dateParseFormats = <String>['MMM d, yyyy', 'MMM dd, yyyy', 'MMM-d-yyyy', 'MMM-dd-yyyy', 'M/d/yyyy', 'MM/dd/yyyy', 'yyyy-MM-dd'];
