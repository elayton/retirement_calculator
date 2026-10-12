import '../models/plan_models.dart';
import '../models/plan_constants.dart';
import '../models/plan_parameters.dart';

/// Calculate successive rows of projected account totals by age.
class PlanCalculator {
  final DateTime portfolioDate;
  final PlanParameters parameters;
  late PlanTotals last;

  int? age;
  PlanTotals? next;

  /// Number of iteration steps completed so far.
  int _iteration = 0;

  PlanCalculator({required this.portfolioDate, required this.parameters, required PlanTotals totals}) {
    last = PlanTotals.fromPlanTotals(totals);
  }

  double _growBy(double total, double growthRate) => total * growthRate / 100;

  double _prorate(double amount) {
    if (_iteration > 0) return amount;

    final date = portfolioDate;

    final startOfYear = DateTime.utc(date.year);
    final dayOfYear = DateTime.utc(date.year, date.month, date.day).difference(startOfYear).inDays;
    final endOfYear = DateTime.utc(date.year, 12, 31);
    final daysLeftInYear = endOfYear.difference(startOfYear).inDays - dayOfYear;

    return amount * daysLeftInYear / 365;
  }

  double _monthlyToAnnual(double monthly) => monthly * 12;

  bool _isAfterRetirementAge() => age! >= parameters.retirementAge;

  bool _isAfterMedicareAge() => age! >= PlanConstants.medicareStartAge;

  bool _isAfterSocialSecurityAge() => age! >= parameters.socialSecurityAge;

  bool _isAfterSpouseSocialSecurityAge() => age! >= parameters.spouseSocialSecurityAge;

  void setExpenses() {
    if (_isAfterRetirementAge()) {
      final budget = _monthlyToAnnual(parameters.budget);
      next?.add(PlanColumn.expenses, "Budget", budget);

      if (_isAfterMedicareAge()) {
        final medicare = _monthlyToAnnual(parameters.medicare);
        next?.add(PlanColumn.expenses, "Medicare", medicare);
      } else {
        final medicalInsurance = _monthlyToAnnual(parameters.medicalInsurance);
        next?.add(PlanColumn.expenses, "Medical Insurance", medicalInsurance);
        
        final premiumTaxCredits = _monthlyToAnnual(parameters.premiumTaxCredits);
        next?.sub(PlanColumn.expenses, "Premium Tax Credits", premiumTaxCredits);
      }
    }
  }

  void growBrokerage() {
    final growthRate = parameters.brokerageGrowthRate;
    final total = last.total(PlanColumn.brokerage);
    final growthAmount = _prorate(_growBy(total, growthRate));
    next?.add(PlanColumn.brokerage, "Growth", growthAmount);
  }

  void growFourOhOneK() {
    final growthRate = parameters.fourOhOneKGrowthRate;
    final total = last.total(PlanColumn.fourOhOneK);
    final growthAmount = _prorate(_growBy(total, growthRate));
    next?.add(PlanColumn.fourOhOneK, "Growth", growthAmount);
  }

  void growTraditionalIra() {
    final growthRate = parameters.traditionalIraGrowthRate;
    final total = last.total(PlanColumn.traditionalIra);
    final growthAmount = _prorate(_growBy(total, growthRate));
    next?.add(PlanColumn.traditionalIra, "Growth", growthAmount);
  }

  void growRothIra() {
    final growthRate = parameters.rothIraGrowthRate;
    final total = last.total(PlanColumn.rothIra);
    final growthAmount = _prorate(_growBy(total, growthRate));
    next?.add(PlanColumn.rothIra, "Growth", growthAmount);
  }

  void growHsa() {
    final growthRate = parameters.hsaGrowthRate;
    final investmentThreshold = parameters.hsaInvestmentThreshold;
    final total = last.total(PlanColumn.hsa) - investmentThreshold;
    final growthAmount = _prorate(_growBy(total, growthRate));
    next?.add(PlanColumn.hsa, "Growth", growthAmount);
  }

  /// Advance the account totals by one year and return the new totals.
  PlanTotals calculateNext(int age) {
    this.age = age;
    next = PlanTotals.fromPlanTotals(last);

    setExpenses();

    growBrokerage();
    growFourOhOneK();
    growTraditionalIra();
    growRothIra();
    growHsa();

    ++_iteration;

    last = next!;
    return last;
  }
}
