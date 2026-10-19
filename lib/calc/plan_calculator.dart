import 'dart:math';

import 'package:flutter/foundation.dart';

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

  bool _isAfterRothConversionAge() => age! > parameters.rothIraConversionAge;

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
  void _earnSalary() {
    if (!_isAfterRetirementAge()) {
      final salary = parameters.baseSalary;
      next!.salary += salary;
      next!.ordinaryIncome += salary;
      next!.add(PlanColumn.income, "Salary", salary);

      final bonus = _percentageOf(salary, parameters.bonusRate);
      next!.salary += bonus;
      next!.ordinaryIncome += bonus;
      next!.add(PlanColumn.income, "Bonus", bonus);
    }
  }

  void _receiveSocialSecurity() {
    if (_isAfterPrimarySocialSecurityAge()) {
      final benefit = _monthlyToAnnual(PlanConstants.socialSecurityBenefitByAge[parameters.primarySocialSecurityAge] ?? 0);
      next!.ordinaryIncome += _percentageOf(benefit, PlanConstants.socialSecurityTaxablePercentage);
      next!.add(PlanColumn.income, "Primary Social Security", benefit);
    }

    if (_isAfterSecondarySocialSecurityAge()) {
      final benefit = _monthlyToAnnual((PlanConstants.socialSecurityBenefitByAge[parameters.secondarySocialSecurityAge] ?? 0) / 2);
      next!.ordinaryIncome += _percentageOf(benefit, PlanConstants.socialSecurityTaxablePercentage);
      next!.add(PlanColumn.income, "Secondary Social Security", benefit);
    }

    next!.unpaidExpenses -= next!.totalOf(PlanColumn.income);
  }

  void _contributeTo401k() {
    if (!_isAfterRetirementAge()) {
      final employeeContribution = _percentageOf(next!.salary, parameters.employee401kContributionRate);
      next!.add(PlanColumn.fourOhOneK, "Employee 401(k) Contribution", employeeContribution);

      final employerContribution = _percentageOf(next!.salary, parameters.employer401kContributionRate);
      next!.add(PlanColumn.fourOhOneK, "Employer 401(k) Contribution", employerContribution);
    }
  }

  void _contributeToHsa() {
    if (!_isAfterRetirementAge()) {
      final hsaContribution = PlanConstants.hsaContributionLimit;
      next!.add(PlanColumn.hsa, "HSA Contribution", hsaContribution);

      // TODO: Add employer HSA contributions.
    }
  }

  /// Withdraw from the brokerage account to pay unpaid expenses.
  void _payExpensesFromBrokerage() {
    if (_isAfterRetirementAge()) {
      if (next!.unpaidExpenses > 0) {
        final withdrawalAmount = min(next!.unpaidExpenses, next!.totalOf(PlanColumn.brokerage));
        if (withdrawalAmount > 0) {
          next!.brokerageWithdrawals += withdrawalAmount;

          // Pay expenses.
          next!.unpaidExpenses -= withdrawalAmount;
          next!.sub(PlanColumn.brokerage, "Pay Expenses", withdrawalAmount);

          // Brokerage withdrawals are taxable as capital gains.  TODO: Adjust brokerage capital gains with cost basis.
          next!.capitalGains += withdrawalAmount;
          next!.add(PlanColumn.income, "Withdrawal from Brokerage", withdrawalAmount);
        }
      }
    }
  }

  /// Withdraw from the 401(k) account to pay unpaid expenses.
  void _payExpensesFromFourOhOneK() {
    if (_isAfterRetirementAge()) {
      if (next!.unpaidExpenses > 0) {
        final withdrawalAmount = min(next!.unpaidExpenses, next!.totalOf(PlanColumn.fourOhOneK));
        if (withdrawalAmount > 0) {
          next!.fourOhOneKWithdrawals += withdrawalAmount;

          // Pay expenses.
          next!.unpaidExpenses -= withdrawalAmount;
          next!.sub(PlanColumn.fourOhOneK, "Pay Expenses", withdrawalAmount);

          // 401(k) withdrawals are taxable as ordinary income.
          next!.ordinaryIncome += withdrawalAmount;
          next!.add(PlanColumn.income, "Withdrawal from 401(k)", withdrawalAmount);
        }
      }
    }
  }

  /// Withdraw from the traditional IRA account to pay unpaid expenses.
  void _payExpensesFromTraditionalIra() {
    if (_isAfterRetirementAge()) {
      if (next!.unpaidExpenses > 0) {
        final withdrawalAmount = min(next!.unpaidExpenses, next!.totalOf(PlanColumn.traditionalIra));
        if (withdrawalAmount > 0) {
          next!.traditionalIraWithdrawals += withdrawalAmount;

          // Pay expenses.
          next!.sub(PlanColumn.traditionalIra, "Pay Expenses", withdrawalAmount);
          next!.unpaidExpenses -= withdrawalAmount;

          // Traditional IRA withdrawals are taxable as ordinary income.
          next!.ordinaryIncome += withdrawalAmount;
          next!.add(PlanColumn.income, "Withdrawal from Traditional IRA", withdrawalAmount);
        }
      }
    }
  }

  /// Withdraw from the traditional IRA account to pay unpaid expenses.
  void _payExpensesFromRothIra() {
    if (_isAfterRetirementAge()) {
      if (next!.unpaidExpenses > 0) {
        final withdrawalAmount = min(next!.unpaidExpenses, next!.totalOf(PlanColumn.rothIra));
        if (withdrawalAmount > 0) {
          next!.rothIraWithdrawals += withdrawalAmount;

          // Pay expenses.
          next!.sub(PlanColumn.rothIra, "Pay Expenses", withdrawalAmount);
          next!.unpaidExpenses -= withdrawalAmount;

          // Roth IRA withdrawals are not taxable.
          next!.ordinaryIncome += 0;
        }
      }
    }
  }

  void _setRothIraConversion() {
    if (_isAfterRetirementAge()) {
      if (_isAfterRothConversionAge()) {
        next!.unconvertedToRoth = parameters.rothIraConversion;
      }
    }
  }

  void _convertFourOhOneKToRothIra() {
    if (_isAfterRetirementAge()) {
      if (_isAfterRothConversionAge()) {
        final conversionAmount = min(next!.unconvertedToRoth, next!.totalOf(PlanColumn.fourOhOneK));
        if (conversionAmount > 0) {
          next!.fourOhOneKWithdrawals += conversionAmount;
          next!.sub(PlanColumn.fourOhOneK, "Convert to Roth IRA", conversionAmount);

          // Convert to Roth IRA.
          next!.add(PlanColumn.rothIra, "Convert from 401(k)", conversionAmount);
          next!.unconvertedToRoth -= conversionAmount;

          // 401(k) withdrawals for Roth conversions are taxable as ordinary income.
          next!.ordinaryIncome += conversionAmount;
          next!.add(PlanColumn.income, "Convert to Roth IRA from 401(k)", conversionAmount);
        }
      }
    }
  }

  void _convertTraditionalIraToRothIra() {
    if (_isAfterRetirementAge()) {
      if (_isAfterRothConversionAge()) {
        final conversionAmount = min(next!.unconvertedToRoth, next!.totalOf(PlanColumn.traditionalIra));
        if (conversionAmount > 0) {
          next!.traditionalIraWithdrawals += conversionAmount;
          next!.sub(PlanColumn.traditionalIra, "Convert to Roth IRA", conversionAmount);

          // Convert to Roth IRA.
          next!.add(PlanColumn.rothIra, "Convert from Traditional IRA", conversionAmount);
          next!.unconvertedToRoth -= conversionAmount;

          // Traditional IRA withdrawals for Roth conversions are taxable as ordinary income.
          next!.ordinaryIncome += conversionAmount;
          next!.add(PlanColumn.income, "Convert to Roth IRA from Traditional IRA", conversionAmount);
        }
      }
    }
  }

  /// Add a year of growth to the brokerage balance.
  void _growBrokerage() {
    final growthRate = parameters.brokerageGrowthRate;
    final total = next!.totalOf(PlanColumn.brokerage) - next!.brokerageWithdrawals;
    final growthAmount = _prorate(_percentageOf(total, growthRate));
    if (growthAmount > 0) {
      next!.add(PlanColumn.brokerage, "Growth", growthAmount);
    }
  }

  /// Add a year of growth to the 401(k) balance.
  void _growFourOhOneK() {
    final growthRate = parameters.fourOhOneKGrowthRate;
    final total = next!.totalOf(PlanColumn.fourOhOneK) - next!.fourOhOneKWithdrawals;
    final growthAmount = _prorate(_percentageOf(total, growthRate));
    if (growthAmount > 0) {
      next!.add(PlanColumn.fourOhOneK, "Growth", growthAmount);
    }
  }

  /// Add a year of growth to the pre-tax traditional IRA balance.
  void _growTraditionalIra() {
    final growthRate = parameters.traditionalIraGrowthRate;
    final total = next!.totalOf(PlanColumn.traditionalIra) - next!.traditionalIraWithdrawals;
    final growthAmount = _prorate(_percentageOf(total, growthRate));
    if (growthAmount > 0) {
      next!.add(PlanColumn.traditionalIra, "Growth", growthAmount);
    }
  }

  /// Add a year of growth to the after-tax Roth IRA balance.
  void _growRothIra() {
    final growthRate = parameters.rothIraGrowthRate;
    final total = next!.totalOf(PlanColumn.rothIra) - next!.rothIraWithdrawals;
    final growthAmount = _prorate(_percentageOf(total, growthRate));
    if (growthAmount > 0) {
      next!.add(PlanColumn.rothIra, "Growth", growthAmount);
    }
  }

  /// Add a year of growth to the invested HSA balance.
  void _growHsa() {
    final growthRate = parameters.hsaGrowthRate;
    final investmentThreshold = parameters.hsaInvestmentThreshold;
    final total = next!.totalOf(PlanColumn.hsa) - investmentThreshold;
    final growthAmount = _prorate(_percentageOf(total, growthRate));
    if (growthAmount > 0) {
      next!.add(PlanColumn.hsa, "Growth", growthAmount);
    }
  }

  /// Federal income tax owed on this year's income.
  ///
  /// The U.S. model is progressive, so each marginal rate applies only to the
  /// slice of taxable income inside its own bracket rather than to the income
  /// as a whole.  [PlanConstants.ordinaryIncomeTaxBrackets] gives each bracket as
  /// an upper bound on taxable income (a null bound is the uncapped top
  /// bracket), so the slice for a bracket is the income above the previous bound
  /// and up to this one.  [PlanConstants.capitalGainsTaxBrackets] has the same
  /// shape.
  ///
  /// Income stacks in three layers.  The standard deduction shelters the
  /// bottom, so it comes off ordinary income first and then goes on sheltering
  /// gains once ordinary income runs out.  Ordinary income then fills upward
  /// through the ordinary brackets, and the gains occupy whatever room is left
  /// over, taxed by position in the gains brackets.  A gain landing at a stack
  /// position under $98,900 is therefore taxed at 0%, even though the same gain
  /// earned by someone with high wages would be taxed at 15%.
  ///
  /// Records both the tax owed and, in [PlanTotals.taxBracket], the highest
  /// marginal rate any income reached.  That rate is the topmost of the two
  /// walks rather than the ordinary one alone, so a year whose gains land in a
  /// higher band than the wages do reports the gains band.
  void _calculateTax() {
    // The deduction comes off the bottom of the stack, so it shelters ordinary
    // income first and then continues into the gains.
    final ordinaryTaxable = max(0.0, next!.ordinaryIncome - PlanConstants.standardDeduction);
    final gainsTaxable = max(0.0, next!.ordinaryIncome + next!.capitalGains - PlanConstants.standardDeduction) - ordinaryTaxable;

    var tax = 0.0;
    var lowerBound = 0.0;
    var topRate = 0.0;

    /* Ordinary income. */

    for (final (upperBound, rate) in PlanConstants.ordinaryIncomeTaxBrackets) {
      // Income has run out before this bracket starts.
      if (ordinaryTaxable <= lowerBound) break;

      final upper = upperBound ?? ordinaryTaxable;
      tax += _percentageOf(min(ordinaryTaxable, upper) - lowerBound, rate);
      topRate = max(topRate, rate);

      // The uncapped top bracket closes the walk.
      if (upperBound == null) break;

      lowerBound = upperBound;
    }

    /* Capital gains, starting where ordinary income left off. */

    final stackTop = ordinaryTaxable + gainsTaxable;
    lowerBound = ordinaryTaxable;

    for (final (upperBound, rate) in PlanConstants.capitalGainsTaxBrackets) {
      // Gains have run out before this bracket starts.
      if (stackTop <= lowerBound) break;

      final upper = upperBound ?? stackTop;

      // Ordinary income may already have reached past this bracket, in which
      // case none of the gains are taxed here.  The bound still has to hold
      // steady, or the next bracket would tax room the gains never reached.
      if (upper > lowerBound) {
        tax += _percentageOf(min(stackTop, upper) - lowerBound, rate);
        topRate = max(topRate, rate);
        lowerBound = upper;
      }

      // The uncapped top bracket closes the walk.
      if (upperBound == null) break;
    }

    next!.tax = tax;
    next!.taxBracket = topRate;
  }

  /// Advance the account totals by one year and return the new totals.
  PlanTotals calculateNext(int age) {
    this.age = age;
    next = PlanTotals.fromPlanTotals(last);

    _setExpenses();
    _earnSalary();
    _receiveSocialSecurity();

    _contributeTo401k();
    _contributeToHsa();

    _payExpensesFromBrokerage();
    _payExpensesFromFourOhOneK();
    _payExpensesFromTraditionalIra();
    _payExpensesFromRothIra();

    _setRothIraConversion();
    _convertFourOhOneKToRothIra();
    _convertTraditionalIraToRothIra();

    _growBrokerage();
    _growFourOhOneK();
    _growTraditionalIra();
    _growRothIra();
    _growHsa();

    _calculateTax();

    ++_iteration;

    last = next!;
    return last;
  }
}
