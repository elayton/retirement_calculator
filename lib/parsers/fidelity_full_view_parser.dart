import 'package:csv/csv.dart' as csv_pkg;
import 'package:intl/intl.dart';

import '../models/portfolio.dart';

/// Parses Fidelity "Full View" portfolio export files.
///
/// Expected header:
/// "Type","Sub type","Account name","Institution","Balance","Balance as of","Hidden"
///
/// Rows with missing fields are ignored.
Portfolio parseFidelityFullView(
  String csv, {
  String type = 'Fidelity Full View',
  String? fileName,
}) {
  final rows = csv_pkg.Csv().decode(csv);

  // The header is the first row that parses into more than one field.
  // This allows for some preamble text in the file, which is common in Fidelity exports.
  final headerIndex = rows.indexWhere((r) => r.length > 1);
  if (headerIndex == -1) {
    return Portfolio(
      type: type,
      exportedDate: DateTime.now(),
      fileName: fileName,
    );
  }

  // One PortfolioAccount is created per valid account row.
  final accounts = <PortfolioAccount>[];
  DateTime? downloaded;

  for (final row in rows.skip(headerIndex + 1)) {
    final firstField = row.isNotEmpty ? row[0].toString() : '';
    if (firstField.startsWith('Date downloaded')) {
      downloaded = _parseDownloadedDate(firstField);
      break;
    }

    final fields = row.map((f) => f.toString().trim()).toList();
    if (fields.length < 7) continue;

    final typeName = fields[0].trim();
    final name = fields[2].trim();
    final institution = fields[3].trim();
    final balance = _parseBalance(fields[4]);
    final updated = _parseDate(fields[5]);

    // Ignore rows with missing fields.
    if (typeName.isEmpty || name.isEmpty || institution.isEmpty) continue;
    if (balance == null || updated == null) continue;

    accounts.add(
      PortfolioAccount(
        type: typeName,
        name: name,
        institution: institution,
        balance: balance,
        updated: updated,
      ),
    );
  }

  // Prefer the in-file date; fall back to the account dates.
  final exportedDate =
      downloaded ??
      (accounts.isEmpty
          ? DateTime.now()
          : accounts
                .map((a) => a.updated)
                .reduce((a, b) => a.isAfter(b) ? a : b));

  return Portfolio(
    type: type,
    exportedDate: exportedDate,
    accounts: accounts,
    fileName: fileName,
  );
}

DateTime? _parseDownloadedDate(String line) {
  final match = RegExp(r'(\d{1,2}/\d{1,2}/\d{4})').firstMatch(line);
  if (match == null) return null;
  try {
    return DateFormat('M/d/yyyy').parseStrict(match.group(1)!);
  } catch (_) {
    return null;
  }
}

// Strips "$", commas, and spaces before parsing.
double? _parseBalance(String raw) {
  final cleaned = raw.replaceAll(RegExp(r'[\$,\s]'), '');
  return double.tryParse(cleaned);
}

DateTime? _parseDate(String raw) {
  final value = raw.trim();
  if (value.isEmpty) return null;
  const formats = [
    'MMM d, yyyy',
    'MMM dd, yyyy',
    'MMM-d-yyyy',
    'MMM-dd-yyyy',
    'M/d/yyyy',
    'MM/dd/yyyy',
    'yyyy-MM-dd',
  ];
  for (final f in formats) {
    try {
      return DateFormat(f).parseStrict(value);
    } catch (_) {
      // Try the next format.
    }
  }
  return null;
}
