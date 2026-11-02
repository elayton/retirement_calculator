import 'package:flutter_test/flutter_test.dart';
import 'package:retirement_calculator/models/plan_parameters.dart';

void main() {
  group('PlanParametersMap', () {
    group('getBudget', () {
      test('returns the budget set for the current age', () {
        final parametersMap = PlanParametersMap(minAge: 60, initial: PlanParameters());
        parametersMap.age = 60;
        parametersMap.setBudget(9000);

        expect(parametersMap.getBudget(), 9000);
      });

      test('returns the budget of the current age over the first age', () {
        final parametersMap = PlanParametersMap(minAge: 60, initial: PlanParameters());
        parametersMap.age = 60;
        parametersMap.setBudget(7500);

        parametersMap.age = 70;
        parametersMap.setBudget(6000);

        expect(parametersMap.getBudget(), 6000);

        parametersMap.age = 60;
        parametersMap.setBudget(8000);

        expect(parametersMap.getBudget(), 8000);
      });

      test('falls back to the first age when no parameters exist for the current age', () {
        final parametersMap = PlanParametersMap(minAge: 60, initial: PlanParameters.withDefaults());
        parametersMap.age = 65;

        expect(parametersMap.getBudget(), 7500);
      });
    });

    group('setBudget', () {
      test('sets the budget in the parameters for the current age', () {
        final parametersMap = PlanParametersMap(minAge: 60, initial: PlanParameters());
        parametersMap.age = 60;
        parametersMap.setBudget(9000);

        expect(parametersMap.getBudget(), 9000);
      });

      test('creates new parameters for the current age when none are set', () {
        final parametersMap = PlanParametersMap(minAge: 60, initial: PlanParameters());
        parametersMap.age = 60;
        parametersMap.setBudget(7500);

        parametersMap.age = 70;
        parametersMap.setBudget(6000);

        expect(parametersMap.getBudget(), 6000);
      });

      test('overwrites the budget of the parameters for the current age', () {
        final parametersMap = PlanParametersMap(minAge: 60, initial: PlanParameters());
        parametersMap.age = 60;
        parametersMap.setBudget(9000);

        parametersMap.setBudget(9500);

        expect(parametersMap.getBudget(), 9500);
      });
    });
  });
}
