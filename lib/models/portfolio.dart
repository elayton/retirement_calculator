enum PortfolioType {
  fidelityFullView('Fidelity Full View');

  final String label;

  const PortfolioType(this.label);
}

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
  unknown('Unknown');

  /// Human-readable name displayed on the Summary page.
  final String label;

  const PortfolioAccountType(this.label);
}

class PortfolioAccount {
  final PortfolioAccountType type;
  final String name;
  final String institution;
  final double balance;
  final DateTime updated;

  const PortfolioAccount({
    required this.type,
    required this.name,
    required this.institution,
    required this.balance,
    required this.updated,
  });
}

class Portfolio {
  final String type;
  final DateTime exportedDate;
  final List<PortfolioAccount> accounts;
  final String? fileName;

  const Portfolio({
    required this.type,
    required this.exportedDate,
    this.accounts = const [],
    this.fileName,
  });
}
