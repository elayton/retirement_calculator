import '../models/plan.dart';
import '../models/plan_parameters.dart';
import '../models/portfolio.dart';

/// Calculate successive rows of projected account totals by age.
class PlanCalculator {
  final PlanParameters parameters;
  late PlanTotals last;
  PlanTotals? next;

  PlanCalculator({
    this.parameters = const PlanParameters(),
    required PlanTotals totals,
  }) {
    last = PlanTotals.fromPlanTotals(totals);
  }

  double _growBy(double total, double growthRate) => total * growthRate / 100;

  void growBrokerage() {
    final growthRate = parameters.brokerageGrowthRate;
    final total = last.total(PortfolioAccountType.brokerage);
    next?.add(PortfolioAccountType.brokerage, "Growth", _growBy(total, growthRate));
  }

  void growFourOhOneK() {
    final growthRate = parameters.fourOhOneKGrowthRate;
    final total = last.total(PortfolioAccountType.fourOhOneK);
    next?.add(PortfolioAccountType.fourOhOneK, "Growth", _growBy(total, growthRate));
  }

  void growTraditionalIra() {
    final growthRate = parameters.traditionalIraGrowthRate;
    final total = last.total(PortfolioAccountType.traditionalIra);
    next?.add(PortfolioAccountType.traditionalIra, "Growth", _growBy(total, growthRate));
  }

  void growRothIra() {
    final growthRate = parameters.rothIraGrowthRate;
    final total = last.total(PortfolioAccountType.rothIra);
    next?.add(PortfolioAccountType.rothIra, "Growth", _growBy(total, growthRate));
  }

  void growHsa() {
    final growthRate = parameters.hsaGrowthRate;
    final total = last.total(PortfolioAccountType.hsa);
    next?.add(PortfolioAccountType.hsa, "Growth", _growBy(total, growthRate));
  }

  /// Advance the account totals by one year and return the new totals.
  PlanTotals calculateNext(int age) {
    next = PlanTotals.fromPlanTotals(last);

    growBrokerage();
    growFourOhOneK();
    growTraditionalIra();
    growRothIra();
    growHsa();

    last = next!;
    return last;
  }
}
