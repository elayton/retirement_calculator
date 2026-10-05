class PortfolioAccount {
  const PortfolioAccount({
    required this.type,
    required this.name,
    required this.institution,
    required this.balance,
    required this.updated,
  });

  final String type;
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
