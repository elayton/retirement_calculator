import '../models/portfolio.dart';

class PlanBalance {
  final double initial;
  final List<(String, double)> adjustments = [];

  PlanBalance({
    required this.initial
  });

  double get total => adjustments.fold(initial, (total, adjustment) => total + adjustment.$2);

  void add(String label, double amount) {
    adjustments.add((label, amount));
  }
}

class PlanTotals {
  final Map<PortfolioAccountType, PlanBalance> balances = {};

  PlanTotals.fromPortfolio(
    Portfolio portfolio,
  ) {
    for (final account in portfolio.accounts) {
      balances[account.type] = PlanBalance(initial: portfolio.accounts.where((a) => a.type == account.type).fold<double>(0, (sum, a) => sum + a.balance));
    }
  }

  PlanTotals.fromPlanTotals(
    PlanTotals that,
  ) {
    for (final type in that.balances.keys) {
      final balance = that.balances[type]!;
      balances[type] = PlanBalance(initial: balance.total);
    }
  }

  double total(PortfolioAccountType type) => balances[type]?.total ?? 0;

  void add(PortfolioAccountType type, String label, double amount) {
    balances[type]?.add(label, amount);
  }

  void sub(PortfolioAccountType type, String label, double amount) {
    balances[type]?.add(label, -amount);
  }
}
