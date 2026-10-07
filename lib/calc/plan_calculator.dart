import '../models/plan_parameters.dart';
import '../models/portfolio.dart';

/// Calculate successive rows of projected account totals by age.
class PlanCalculator {
  PlanCalculator({
    this.parameters = const PlanParameters(),
    Map<PortfolioAccountType, double>? totals,
  }) : totals = totals ?? <PortfolioAccountType, double>{};

  final PlanParameters parameters;
  Map<PortfolioAccountType, double> totals;

  double _growthRate(double total, double growthRate) =>
      total * growthRate / 100;

  late Map<PortfolioAccountType, double> next;

  void growBrokerage() {
    final total = next[PortfolioAccountType.brokerage] ?? 0;
    next[PortfolioAccountType.brokerage] =
        total + _growthRate(total, parameters.brokerageGrowthRate);
  }

  void growFourOhOneK() {
    final total = next[PortfolioAccountType.fourOhOneK] ?? 0;
    next[PortfolioAccountType.fourOhOneK] =
        total + _growthRate(total, parameters.fourOhOneKGrowthRate);
  }

  void growTraditionalIra() {
    final total = next[PortfolioAccountType.traditionalIra] ?? 0;
    next[PortfolioAccountType.traditionalIra] =
        total + _growthRate(total, parameters.traditionalIraGrowthRate);
  }

  void growRothIra() {
    final total = next[PortfolioAccountType.rothIra] ?? 0;
    next[PortfolioAccountType.rothIra] =
        total + _growthRate(total, parameters.rothIraGrowthRate);
  }

  void growHsa() {
    final total = next[PortfolioAccountType.hsa] ?? 0;
    next[PortfolioAccountType.hsa] =
        total + _growthRate(total, parameters.hsaGrowthRate);
  }

  /// Advance the account totals by one year and return the new totals.
  Map<PortfolioAccountType, double> calculateNext(int age) {
    next = Map.of(totals);

    growBrokerage();
    growFourOhOneK();
    growTraditionalIra();
    growRothIra();
    growHsa();

    totals = next;
    return totals;
  }
}
