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

  /// Whether primary Social Security has started.
  bool _isAfterPrimarySocialSecurityAge() => age! > parameters.primarySocialSecurityAge;

  /// Whether secondary Social Security has started, which may fall earlier
  /// or later.
  bool _isAfterSecondarySocialSecurityAge() => age! > parameters.secondarySocialSecurityAge;

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

  /// Money coming in over the year: salary and bonus while working, then
  /// primary and secondary Social Security from the ages it starts.
  void _setIncome() {
    if (!_isAfterRetirementAge()) {
      final salary = parameters.baseSalary;
      next!.add(PlanColumn.income, "Salary", salary);

      final bonus = _percentageOf(salary, parameters.bonusRate);
      next!.add(PlanColumn.income, "Bonus", bonus);
    }

    if (_isAfterPrimarySocialSecurityAge()) {
      final benefit = PlanConstants.socialSecurityBenefitByAge[parameters.primarySocialSecurityAge] ?? 0;
      next!.add(PlanColumn.income, "Primary Social Security", _monthlyToAnnual(benefit));
    }

    if (_isAfterSecondarySocialSecurityAge()) {
      final benefit = (PlanConstants.socialSecurityBenefitByAge[parameters.secondarySocialSecurityAge] ?? 0) / 2;
      next!.add(PlanColumn.income, "Secondary Social Security", _monthlyToAnnual(benefit));
    }

    next!.unpaidExpenses -= next!.totalOf(PlanColumn.income);
  }

  void _contributeTo401k() {
    if (!_isAfterRetirementAge()) {
      final salary = parameters.baseSalary + _percentageOf(parameters.baseSalary, parameters.bonusRate);

      final employeeContribution = _percentageOf(salary, parameters.employee401kContributionRate);
      next!.add(PlanColumn.fourOhOneK, "Employee 401(k) Contribution", employeeContribution);

      final employerContribution = _percentageOf(salary, parameters.employer401kContributionRate);
      next!.add(PlanColumn.fourOhOneK, "Employer 401(k) Contribution", employerContribution);
    }
  }

  void _contributeToHsa() {
    if (!_isAfterRetirementAge()) {
      // Not deducted from salary because we budget for it.

      final hsaContribution = PlanConstants.hsaContributionLimit;
      next!.add(PlanColumn.hsa, "HSA Contribution", hsaContribution);
    }
  }

  /// Withdraw from the brokerage account to pay unpaid expenses.
  void _withdrawFromBrokerage() {
    if (_isAfterRetirementAge()) {
      if (next!.unpaidExpenses > 0) {
        next!.brokerageWithdrawals = min(next!.unpaidExpenses, next!.totalOf(PlanColumn.brokerage));
        next!.sub(PlanColumn.brokerage, "Pay Expenses", next!.brokerageWithdrawals);
        next!.unpaidExpenses -= next!.brokerageWithdrawals;
      }
    }
  }

  /// Withdraw from the 401(k) account to pay unpaid expenses.
  void _withdrawFromFourOhOneK() {
    if (_isAfterRetirementAge()) {
      if (next!.unpaidExpenses > 0) {
        next!.fourOhOneKWithdrawals = min(next!.unpaidExpenses, next!.totalOf(PlanColumn.fourOhOneK));
        next!.sub(PlanColumn.fourOhOneK, "Pay Expenses", next!.fourOhOneKWithdrawals);
        next!.unpaidExpenses -= next!.fourOhOneKWithdrawals;
      }
    }
  }

  /// Withdraw from the traditional IRA account to pay unpaid expenses.
  void _withdrawFromTraditionalIra() {
    if (_isAfterRetirementAge()) {
      if (next!.unpaidExpenses > 0) {
        next!.traditionalIraWithdrawals = min(next!.unpaidExpenses, next!.totalOf(PlanColumn.traditionalIra));
        next!.sub(PlanColumn.traditionalIra, "Pay Expenses", next!.traditionalIraWithdrawals);
        next!.unpaidExpenses -= next!.traditionalIraWithdrawals;
      }
    }
  }

  /// Withdraw from the traditional IRA account to pay unpaid expenses.
  void _withdrawFromRothIra() {
    if (_isAfterRetirementAge()) {
      if (next!.unpaidExpenses > 0) {
        next!.rothIraWithdrawals = min(next!.unpaidExpenses, next!.totalOf(PlanColumn.rothIra));
        next!.sub(PlanColumn.rothIra, "Pay Expenses", next!.rothIraWithdrawals);
        next!.unpaidExpenses -= next!.rothIraWithdrawals;
      }
    }
  }

  /// Add a year of growth to the brokerage balance.
  void _growBrokerage() {
    final growthRate = parameters.brokerageGrowthRate;
    final total = next!.totalOf(PlanColumn.brokerage);
    final growthAmount = _prorate(_percentageOf(total, growthRate));
    next!.add(PlanColumn.brokerage, "Growth", growthAmount);
  }

  /// Add a year of growth to the 401(k) balance.
  void _growFourOhOneK() {
    final growthRate = parameters.fourOhOneKGrowthRate;
    final total = next!.totalOf(PlanColumn.fourOhOneK);
    final growthAmount = _prorate(_percentageOf(total, growthRate));
    next!.add(PlanColumn.fourOhOneK, "Growth", growthAmount);
  }

  /// Add a year of growth to the pre-tax traditional IRA balance.
  void _growTraditionalIra() {
    final growthRate = parameters.traditionalIraGrowthRate;
    final total = next!.totalOf(PlanColumn.traditionalIra);
    final growthAmount = _prorate(_percentageOf(total, growthRate));
    next!.add(PlanColumn.traditionalIra, "Growth", growthAmount);
  }

  /// Add a year of growth to the after-tax Roth IRA balance.
  void _growRothIra() {
    final growthRate = parameters.rothIraGrowthRate;
    final total = next!.totalOf(PlanColumn.rothIra);
    final growthAmount = _prorate(_percentageOf(total, growthRate));
    next!.add(PlanColumn.rothIra, "Growth", growthAmount);
  }

  /// Add a year of growth to the invested HSA balance.
  void _growHsa() {
    final growthRate = parameters.hsaGrowthRate;
    final investmentThreshold = parameters.hsaInvestmentThreshold;
    final total = next!.totalOf(PlanColumn.hsa) - investmentThreshold;
    final growthAmount = _prorate(_percentageOf(total, growthRate));
    next!.add(PlanColumn.hsa, "Growth", growthAmount);
  }

  /// Advance the account totals by one year and return the new totals.
  PlanTotals calculateNext(int age) {
    this.age = age;
    next = PlanTotals.fromPlanTotals(last);

    _setExpenses();
    _setIncome();

    _contributeTo401k();
    _contributeToHsa();
    
    _withdrawFromBrokerage();
    _withdrawFromFourOhOneK();
    _withdrawFromTraditionalIra();
    _withdrawFromRothIra();

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
