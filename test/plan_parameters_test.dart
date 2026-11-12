import 'package:flutter_test/flutter_test.dart';
import 'package:retirement_calculator/models/plan_parameters.dart';
import 'package:retirement_calculator/models/plan_timeline.dart';

void main() {
  group('PlanParametersMap', () {
    group('getBudget', () {
      test('returns the budget set for the current age', () {
        final parametersMap = PlanParametersMap(minAge: 60, initial: PlanParameters());
        parametersMap.age = 60;
        parametersMap.setBudget(9000);

        expect(parametersMap.getBudget(), 9000);
      });
    });
  });

  group('PlanTimeline', () {
    test('round trips through a plan file', () {
      final timeline = PlanTimeline()
        ..retirementAge = 55
        ..primarySocialSecurityAge = 67
        ..secondarySocialSecurityAge = 66
        ..rothIraConversionAge = 63;

      final restored = PlanTimeline.fromJson(timeline.toJson());

      expect(restored.retirementAge, 55);
      expect(restored.primarySocialSecurityAge, 67);
      expect(restored.secondarySocialSecurityAge, 66);
      expect(restored.rothIraConversionAge, 63);
    });
  });

  group('PlanParametersMap toJson and fromJson', () {
    test('round trips the plan file', () {
      final parametersMap = PlanParametersMap(
        minAge: 55,
        initial: PlanParameters.withDefaults(),
        initialMap: {
          55: PlanParameters(budget: 8000, familyMembers: 5),
          65: PlanParameters(baseSalary: 90000, familyMembers: 3),
        },
      );
      parametersMap.age = 65;
      parametersMap.setBudget(9500);
      parametersMap.setBaseSalary(90000);
      parametersMap.setFamilyMembers(4);

      final restored = PlanParametersMap.fromJson(parametersMap.toJson());
      restored.age = 65;

      expect(restored.minAge, 55);
      expect(restored.getBudget(), 9500);
      expect(restored.getBaseSalary(), 90000);
      expect(restored.getFamilyMembers(), 4);
      expect(restored.parametersFor(55).budget, 8000);
      expect(restored.parametersFor(65).familyMembers, 4);
    });

    test('round trips the payment sources saved in a plan file', () {
      final parametersMap = PlanParametersMap(minAge: 60, initial: PlanParameters.withDefaults());
      parametersMap.age = 60;
      parametersMap.setPayExpensesFrom([PaymentSource.cash, PaymentSource.brokerage]);

      final restored = PlanParametersMap.fromJson(parametersMap.toJson());

      expect(restored.getPayExpensesFrom(), [PaymentSource.cash, PaymentSource.brokerage]);
    });
  });
}
