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

  /// [rate] percent of [amount]: a growth rate applied to a balance, or a
  /// bonus rate applied to a salary.
  double _percentageOf(double amount, double rate) => amount * rate / 100;

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

  bool _isAfterRetirementAge() => age! > parameters.retirementAge;

  bool _isAfterMedicareAge() => age! > PlanConstants.medicareStartAge;

  bool _isAfterSocialSecurityAge() => age! > parameters.socialSecurityAge;

  bool _isAfterSpouseSocialSecurityAge() => age! > parameters.spouseSocialSecurityAge;

  /// Money coming in over the year: salary and bonus while working, then
  /// Social Security from the ages it starts at. Social Security keeps running
  /// after retirement, and the two can overlap with the working years and with
  /// each other, so each source is added on its own terms.
  void setIncome() {
    if (!_isAfterRetirementAge()) {
      final salary = parameters.baseSalary;
      next?.add(PlanColumn.income, "Salary", salary);

      final bonus = _percentageOf(salary, parameters.bonusRate);
      next?.add(PlanColumn.income, "Bonus", bonus);
    }

    if (_isAfterSocialSecurityAge()) {
      final benefit = PlanConstants.socialSecurityBenefitByAge[parameters.socialSecurityAge]?.toDouble() ?? 0;
      next?.add(PlanColumn.income, "Social Security", _monthlyToAnnual(benefit));
    }

    if (_isAfterSpouseSocialSecurityAge()) {
      final benefit = PlanConstants.socialSecurityBenefitByAge[parameters.spouseSocialSecurityAge]?.toDouble() ?? 0 / 2;
      next?.add(PlanColumn.income, "Spouse Social Security", _monthlyToAnnual(benefit));
    }
  }

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
    final growthAmount = _prorate(_percentageOf(total, growthRate));
    next?.add(PlanColumn.brokerage, "Growth", growthAmount);
  }

  void growFourOhOneK() {
    final growthRate = parameters.fourOhOneKGrowthRate;
    final total = last.total(PlanColumn.fourOhOneK);
    final growthAmount = _prorate(_percentageOf(total, growthRate));
    next?.add(PlanColumn.fourOhOneK, "Growth", growthAmount);
  }

  void growTraditionalIra() {
    final growthRate = parameters.traditionalIraGrowthRate;
    final total = last.total(PlanColumn.traditionalIra);
    final growthAmount = _prorate(_percentageOf(total, growthRate));
    next?.add(PlanColumn.traditionalIra, "Growth", growthAmount);
  }

  void growRothIra() {
    final growthRate = parameters.rothIraGrowthRate;
    final total = last.total(PlanColumn.rothIra);
    final growthAmount = _prorate(_percentageOf(total, growthRate));
    next?.add(PlanColumn.rothIra, "Growth", growthAmount);
  }

  void growHsa() {
    final growthRate = parameters.hsaGrowthRate;
    final investmentThreshold = parameters.hsaInvestmentThreshold;
    final total = last.total(PlanColumn.hsa) - investmentThreshold;
    final growthAmount = _prorate(_percentageOf(total, growthRate));
    next?.add(PlanColumn.hsa, "Growth", growthAmount);
  }

  /// Advance the account totals by one year and return the new totals.
  PlanTotals calculateNext(int age) {
    this.age = age;
    next = PlanTotals.fromPlanTotals(last);

    setIncome();
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
