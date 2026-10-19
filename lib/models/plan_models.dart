import 'portfolio_models.dart';

enum PlanColumn {
  expenses('Expenses'),
  income('Income'),
  cash('Cash'),
  brokerage('Brokerage'),
  fourOhOneK('401(k)'),
  traditionalIra('Traditional IRA'),
  rothIra('Roth IRA'),
  hsa('HSA'),
  // Unlike the others, the tax columns hold a figure for the year rather than a
  // running balance, so they read from PlanTotals instead of from [balances].
  taxBracket('Tax Bracket'),
  tax('Tax');

  final String label;

  const PlanColumn(this.label);
}

extension PortfolioAccountTypePlanColumn on PortfolioAccountType {
  PlanColumn? get planColumn => switch (this) {
    PortfolioAccountType.cash => PlanColumn.cash,
    PortfolioAccountType.brokerage => PlanColumn.brokerage,
    PortfolioAccountType.fourOhOneK => PlanColumn.fourOhOneK,
    PortfolioAccountType.traditionalIra => PlanColumn.traditionalIra,
    PortfolioAccountType.rothIra => PlanColumn.rothIra,
    PortfolioAccountType.hsa => PlanColumn.hsa,
    _ => null,
  };
}

class PlanBalance {
  final double initial;
  final List<(String, double)> adjustments = [];

  PlanBalance({this.initial = 0});

  double get total => adjustments.fold(initial, (total, adjustment) => total + adjustment.$2);

  void add(String description, double amount) {
    adjustments.add((description, amount));
  }
}

class PlanTotals {
  final Map<PlanColumn, PlanBalance> balances = {};

  double salary = 0;

  double ordinaryIncome = 0;
  double capitalGains = 0;

  double unpaidExpenses = 0;
  double unconvertedToRoth = 0;

  double brokerageWithdrawals = 0;
  double fourOhOneKWithdrawals = 0;
  double traditionalIraWithdrawals = 0;
  double rothIraWithdrawals = 0;

  double taxBracket = 0;
  double tax = 0;

  PlanTotals.fromPortfolio(Portfolio portfolio) {
    for (final account in portfolio.accounts) {
      final column = account.type.planColumn;
      if (column == null) continue;

      balances[column] = PlanBalance(initial: portfolio.accounts.where((a) => a.type == account.type).fold<double>(0, (sum, a) => sum + a.balance));
    }
  }

  PlanTotals.fromPlanTotals(PlanTotals that) {
    balances[PlanColumn.cash] = PlanBalance(initial: that.balances[PlanColumn.cash]?.total ?? 0);
    balances[PlanColumn.brokerage] = PlanBalance(initial: that.balances[PlanColumn.brokerage]?.total ?? 0);
    balances[PlanColumn.fourOhOneK] = PlanBalance(initial: that.balances[PlanColumn.fourOhOneK]?.total ?? 0);
    balances[PlanColumn.traditionalIra] = PlanBalance(initial: that.balances[PlanColumn.traditionalIra]?.total ?? 0);
    balances[PlanColumn.rothIra] = PlanBalance(initial: that.balances[PlanColumn.rothIra]?.total ?? 0);
    balances[PlanColumn.hsa] = PlanBalance(initial: that.balances[PlanColumn.hsa]?.total ?? 0);
  }

  /// The balance tracking [column], or an empty one for a column this portfolio
  /// holds no account in.
  PlanBalance balanceOf(PlanColumn column) => balances[column] ?? PlanBalance();

  double totalOf(PlanColumn column) => balances[column]?.total ?? 0;

  void add(PlanColumn column, String description, double amount) {
    balances.putIfAbsent(column, () => PlanBalance()).add(description, amount);
  }

  void sub(PlanColumn column, String description, double amount) {
    balances.putIfAbsent(column, () => PlanBalance()).add(description, -amount);
  }
}
