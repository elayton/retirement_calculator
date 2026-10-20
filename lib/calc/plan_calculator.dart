import 'dart:math';

import '../models/plan_models.dart';
import '../models/plan_constants.dart';
import '../models/plan_parameters.dart';
import 'tax_calculator.dart';

/// Calculate successive rows of projected account totals by age.
class PlanCalculator {
  final DateTime portfolioDate;
  final PlanParameters parameters;
  late PlanTotals last;

  int? age;
  PlanTotals? next;

  /// Number of iteration steps completed so far.
  int _iteration = 0;

  /// Begin a projection from [totals], copied into the shape the per-year steps
  /// read and add to.
  PlanCalculator({required this.portfolioDate, required this.parameters, required PlanTotals totals}) {
    last = PlanTotals.fromPlanTotals(totals);
  }

  /// [rate] percent of [amount].
  double _percentageOf(double amount, double rate) => amount * rate / 100;

  /// Scale [amount] to the share of the export year still to come, so a
  /// portfolio exported in June does not project a whole year at once.
  double _prorate(double amount) {
    if (_iteration > 0) return amount;

    final date = portfolioDate;

    final startOfYear = DateTime.utc(date.year);
    final dayOfYear = DateTime.utc(date.year, date.month, date.day).difference(startOfYear).inDays;
    final endOfYear = DateTime.utc(date.year, 12, 31);
    final daysLeftInYear = endOfYear.difference(startOfYear).inDays - dayOfYear;

    return amount * daysLeftInYear / 365;
  }

  /// [monthly] as an annual figure.
  double _monthlyToAnnual(double monthly) => monthly * 12;

  /// Strictly after the retirement age, so the year that reaches it still
  /// counts as working.
  bool _isAfterRetirementAge() => age! > parameters.retirementAge;

  /// One year after retirement age.
  bool _isOneYearAfterRetirementAge() => age! > parameters.retirementAge + 1;

  /// Whether Medicare has taken over from private health insurance.
  bool _isAfterMedicareAge() => age! > PlanConstants.medicareStartAge;

  bool _isAfterRothConversionAge() => age! > parameters.rothIraConversionAge;

  /// Whether primary Social Security has started.
  bool _isAfterPrimarySocialSecurityAge() => age! > parameters.primarySocialSecurityAge;

  /// Whether secondary Social Security has started.
  bool _isAfterSecondarySocialSecurityAge() => age! > parameters.secondarySocialSecurityAge;

  /// Money going out over the year, and only once retired: the budget plus
  /// whichever health insurance applies, less any premium tax credits.
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

      // Last year's taxes are part of this year's expenses.
      if (_isOneYearAfterRetirementAge()) {
        final lastYearTax = last.tax;
        if (lastYearTax > 0) {
          next!.add(PlanColumn.expenses, "Last Year's Taxes", lastYearTax);
        }
      }
    }

    next!.unpaidExpenses = next!.totalOf(PlanColumn.expenses);
  }

  /// Salary and bonus while working.
  void _earnSalary() {
    if (!_isAfterRetirementAge()) {
      final salary = parameters.baseSalary;
      next!.add(PlanColumn.income, "Salary", salary);
      next!.salary += salary;
      next!.ordinaryIncome += salary;

      final bonus = _percentageOf(salary, parameters.bonusRate);
      next!.add(PlanColumn.income, "Bonus", bonus);
      next!.salary += bonus;
      next!.ordinaryIncome += bonus;
    }
  }

  void _receiveSocialSecurity() {
    if (_isAfterPrimarySocialSecurityAge()) {
      final benefit = _monthlyToAnnual(PlanConstants.socialSecurityBenefitByAge[parameters.primarySocialSecurityAge] ?? 0);
      next!.add(PlanColumn.income, "Primary Social Security", benefit);
      next!.ordinaryIncome += _percentageOf(benefit, PlanConstants.socialSecurityTaxablePercentage);
    }

    if (_isAfterSecondarySocialSecurityAge()) {
      final benefit = _monthlyToAnnual((PlanConstants.socialSecurityBenefitByAge[parameters.secondarySocialSecurityAge] ?? 0) / 2);
      next!.add(PlanColumn.income, "Secondary Social Security", benefit);
      next!.ordinaryIncome += _percentageOf(benefit, PlanConstants.socialSecurityTaxablePercentage);
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
          next!.sub(PlanColumn.brokerage, "Pay Expenses", withdrawalAmount);
          next!.unpaidExpenses -= withdrawalAmount;

          // Brokerage withdrawals are taxable as capital gains.  TODO: Adjust brokerage capital gains with cost basis.
          next!.add(PlanColumn.income, "Withdrawal from Brokerage", withdrawalAmount);
          next!.capitalGains += withdrawalAmount;
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
          next!.sub(PlanColumn.fourOhOneK, "Pay Expenses", withdrawalAmount);
          next!.unpaidExpenses -= withdrawalAmount;

          // 401(k) withdrawals are taxable as ordinary income.
          next!.add(PlanColumn.income, "Withdrawal from 401(k)", withdrawalAmount);
          next!.ordinaryIncome += withdrawalAmount;
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
          next!.add(PlanColumn.income, "Withdrawal from Traditional IRA", withdrawalAmount);
          next!.ordinaryIncome += withdrawalAmount;
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
        }
      }
    }
  }

  void _transferFourOhOneKToTraditionalIra() {
    if (_isAfterRetirementAge()) {
      final transferAmount = next!.totalOf(PlanColumn.fourOhOneK);

      if (transferAmount > 0) {
        next!.sub(PlanColumn.fourOhOneK, "Transfer to Traditional IRA", transferAmount);
        next!.add(PlanColumn.traditionalIra, "Transfer from 401(k)", transferAmount);
      }
    }
  }

  void _convertTraditionalIraToRothIra() {
    if (_isAfterRetirementAge()) {
      if (_isAfterRothConversionAge()) {
        final conversionAmount = min(parameters.rothIraConversion, next!.totalOf(PlanColumn.traditionalIra));

        if (conversionAmount > 0) {
          next!.sub(PlanColumn.traditionalIra, "Convert to Roth IRA", conversionAmount);
          next!.traditionalIraWithdrawals += conversionAmount;

          // Convert to Roth IRA.
          next!.add(PlanColumn.rothIra, "Convert from Traditional IRA", conversionAmount);

          // Traditional IRA withdrawals for Roth conversions are taxable as ordinary income.
          next!.add(PlanColumn.income, "Convert to Roth IRA from Traditional IRA", conversionAmount);
          next!.ordinaryIncome += conversionAmount;
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

  /// Record the tax owed on this year's income. See [TaxCalculator].
  void _calculateTax() => TaxCalculator.record(next!, next!.ordinaryIncome, next!.capitalGains);

  /// Advance the account totals by one year and return the new totals.
  PlanTotals calculateNext(int age) {
    this.age = age;
    next = PlanTotals.fromPlanTotals(last);

    _setExpenses();
    _earnSalary();
    _receiveSocialSecurity();

    _contributeTo401k();
    _contributeToHsa();

    // Pay expenses from brokerage until it runs out.
    _payExpensesFromBrokerage();
    
    // If we are retired and not on medicare yet, pay expenses from Roth IRA
    // to lower MAGI.
    //if (_isAfterRetirementAge() && !_isAfterMedicareAge()) _payExpensesFromRothIra();

    _payExpensesFromFourOhOneK();
    _payExpensesFromTraditionalIra();
    _payExpensesFromRothIra();

    _transferFourOhOneKToTraditionalIra();
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
