enum PortfolioAccountType {
  cash('Cash'),
  brokerage('Brokerage'),
  fourOhOneK('401(k)'),
  traditionalIra('Traditional IRA'),
  rothIra('Roth IRA'),
  hsa('HSA'),
  annuity('Annuity'),
  fiveTwoNinePlan('529 Plan'),
  creditCard('Credit Card'),
  other('Other'),

  /// Fallback for values that the parser does not recognize.
  unknown('Unknown');

  const PortfolioAccountType(this.label);

  /// Human-readable name displayed on the Summary page.
  final String label;
}

class PortfolioAccount {
  const PortfolioAccount({
    required this.type,
    required this.name,
    required this.institution,
    required this.balance,
    required this.updated,
  });

  final PortfolioAccountType type;
  final String name;
  final String institution;
  final double balance;
  final DateTime updated;
}

class Portfolio {
  const Portfolio({
    required this.type,
    required this.exportedDate,
    this.accounts = const [],
    this.fileName,
  });

  final String type;
  final DateTime exportedDate;
  final List<PortfolioAccount> accounts;
  final String? fileName;
}
