import 'dart:math';

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

  /// Begin a projection from [totals], copying them into the shape the
  /// per-year steps below expect to read and add to.
  PlanCalculator({required this.portfolioDate, required this.parameters, required PlanTotals totals}) {
    last = PlanTotals.fromPlanTotals(totals);
  }

  /// [rate] percent of [amount]: a growth rate applied to a balance, or a
  /// bonus rate applied to a salary.
  double _percentageOf(double amount, double rate) => amount * rate / 100;

  /// Scale [amount] to the share of the export year still to come, so a
  /// portfolio exported in June does not project a whole year of income or
  /// growth at once. Every year after the first runs at full size.
  double _prorate(double amount) {
    if (_iteration > 0) return amount;

    final date = portfolioDate;

    final startOfYear = DateTime.utc(date.year);
    final dayOfYear = DateTime.utc(date.year, date.month, date.day).difference(startOfYear).inDays;
    final endOfYear = DateTime.utc(date.year, 12, 31);
    final daysLeftInYear = endOfYear.difference(startOfYear).inDays - dayOfYear;

    return amount * daysLeftInYear / 365;
  }

  /// [monthly] as an annual figure. The parameters are entered per month, while
  /// the projection steps a year at a time.
  double _monthlyToAnnual(double monthly) => monthly * 12;

  /// Whether the projection has passed retirement. Strictly after, so the year
  /// that reaches the retirement age still counts as working.
  bool _isAfterRetirementAge() => age! > parameters.retirementAge;

  /// Whether Medicare has taken over from private health insurance.
  bool _isAfterMedicareAge() => age! > PlanConstants.medicareStartAge;

  /// Whether Social Security has started.
  bool _isAfterSocialSecurityAge() => age! > parameters.socialSecurityAge;

  /// Whether spouse's Social Security has started, which may fall earlier
  /// or later.
  bool _isAfterSpouseSocialSecurityAge() => age! > parameters.spouseSocialSecurityAge;

  /// Money coming in over the year: salary and bonus while working, then
  /// Social Security from the ages it starts at. Social Security keeps running
  /// after retirement, and the two can overlap with the working years and with
  /// each other, so each source is added on its own terms.
  void _setIncome() {
    if (!_isAfterRetirementAge()) {
      final salary = parameters.baseSalary;
      next!.add(PlanColumn.income, "Salary", salary);

      final bonus = _percentageOf(salary, parameters.bonusRate);
      next!.add(PlanColumn.income, "Bonus", bonus);
    }

    if (_isAfterSocialSecurityAge()) {
      final benefit = PlanConstants.socialSecurityBenefitByAge[parameters.socialSecurityAge]?.toDouble() ?? 0;
      next!.add(PlanColumn.income, "Social Security", _monthlyToAnnual(benefit));
    }

    if (_isAfterSpouseSocialSecurityAge()) {
      final benefit = (PlanConstants.socialSecurityBenefitByAge[parameters.spouseSocialSecurityAge]?.toDouble() ?? 0) / 2;
      next!.add(PlanColumn.income, "Spouse Social Security", _monthlyToAnnual(benefit));
    }
  }

  /// Money going out over the year, and only once the projection has retired:
  /// the budget, plus whichever health insurance applies, less any premium tax
  /// credits offsetting the years before Medicare takes over.
  void _setExpenses() {
    if (_isAfterRetirementAge()) {
      final budget = _monthlyToAnnual(parameters.budget);
      next!.add(PlanColumn.expenses, "Budget", budget);

      if (_isAfterMedicareAge()) {
        final medicare = _monthlyToAnnual(parameters.medicare);
        next!.add(PlanColumn.expenses, "Medicare", medicare);
      } else {
        final medicalInsurance = _monthlyToAnnual(parameters.medicalInsurance);
        next!.add(PlanColumn.expenses, "Medical Insurance", medicalInsurance);
        
        final premiumTaxCredits = _monthlyToAnnual(parameters.premiumTaxCredits);
        next!.sub(PlanColumn.expenses, "Premium Tax Credits", premiumTaxCredits);
      }
    }

    next!.unpaidExpenses = next!.totalOf(PlanColumn.expenses);
  }

  /// Withdraw from the brokerage account to pay unpaid expenses.
  void _withdrawFromBrokerage() {
    if (_isAfterRetirementAge()) {
      if (next!.unpaidExpenses > 0) {
        next!.brokerageWithdrawal = min(next!.unpaidExpenses, next!.totalOf(PlanColumn.brokerage));
        next!.sub(PlanColumn.brokerage, "Pay Expenses", next!.brokerageWithdrawal);
        next!.unpaidExpenses -= next!.brokerageWithdrawal;
      }
    }
  }

  /// Add a year of growth to the brokerage balance.
  void _growBrokerage() {
    final growthRate = parameters.brokerageGrowthRate;
    final total = last.totalOf(PlanColumn.brokerage);
    final growthAmount = _prorate(_percentageOf(total, growthRate));
    next!.add(PlanColumn.brokerage, "Growth", growthAmount);
  }

  /// Add a year of growth to the 401(k) balance.
  void _growFourOhOneK() {
    final growthRate = parameters.fourOhOneKGrowthRate;
    final total = last.totalOf(PlanColumn.fourOhOneK);
    final growthAmount = _prorate(_percentageOf(total, growthRate));
    next!.add(PlanColumn.fourOhOneK, "Growth", growthAmount);
  }

  /// Add a year of growth to the pre-tax traditional IRA balance.
  void _growTraditionalIra() {
    final growthRate = parameters.traditionalIraGrowthRate;
    final total = last.totalOf(PlanColumn.traditionalIra);
    final growthAmount = _prorate(_percentageOf(total, growthRate));
    next!.add(PlanColumn.traditionalIra, "Growth", growthAmount);
  }

  /// Add a year of growth to the after-tax Roth IRA balance.
  void _growRothIra() {
    final growthRate = parameters.rothIraGrowthRate;
    final total = last.totalOf(PlanColumn.rothIra);
    final growthAmount = _prorate(_percentageOf(total, growthRate));
    next!.add(PlanColumn.rothIra, "Growth", growthAmount);
  }

  /// Add a year of growth to the invested HSA balance.
  void _growHsa() {
    final growthRate = parameters.hsaGrowthRate;
    final investmentThreshold = parameters.hsaInvestmentThreshold;
    final total = last.totalOf(PlanColumn.hsa) - investmentThreshold;
    final growthAmount = _prorate(_percentageOf(total, growthRate));
    next!.add(PlanColumn.hsa, "Growth", growthAmount);
  }

  /// Advance the account totals by one year and return the new totals.
  PlanTotals calculateNext(int age) {
    this.age = age;
    next = PlanTotals.fromPlanTotals(last);

    _setIncome();
    _setExpenses();

    _withdrawFromBrokerage();

    _growBrokerage();
    _growFourOhOneK();
    _growTraditionalIra();
    _growRothIra();
    _growHsa();

    ++_iteration;

    last = next!;
    return last;
  }
}
