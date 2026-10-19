import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:retirement_calculator/models/plan_parameters.dart';
import 'package:retirement_calculator/widgets/plan_sidebar.dart';

/// Opens every accordion so all of the sidebar's fields are laid out.
Future<void> _expandAll(WidgetTester tester) async {
  for (final title in planSidebarSections) {
    final finder = find.text(title);
    if (finder.evaluate().isEmpty) continue;
    await tester.ensureVisible(finder.first);
    await tester.tap(finder.first, warnIfMissed: false);
    await tester.pumpAndSettle();
  }
}

Widget _app() => MaterialApp(
  home: Scaffold(
    body: SingleChildScrollView(
      child: PlanSidebar(parameters: PlanParameters(), onChanged: () {}),
    ),
  ),
);

/// Global y of the alphabetic baseline below [element], or null when it has no
/// baseline. Reading one needs the intrinsics flag, available in debug only.
double? baselineY(Element element) {
  final box = element.findRenderObject() as RenderBox;
  try {
    final distance = box.getDistanceToBaseline(TextBaseline.alphabetic) as double;
    return box.localToGlobal(Offset.zero).dy + distance;
  } catch (_) {
    return null;
  }
}

/// The first Row above a value box is the row every field shares, so its rect is
/// the whole label-plus-box line.
Rect _rowFor(Element element) {
  var current = (element.findRenderObject() as RenderObject).parent;
  while (current != null && current is! RenderBox) {
    current = current.parent;
  }
  final row = current! as RenderBox;
  return row.localToGlobal(Offset.zero) & row.size;
}

/// Every field's row: the editable boxes plus the fixed ages, the only plain
/// integers the sidebar renders.
List<Rect> _fieldRows(WidgetTester tester) {
  final rows = <Rect>[];
  for (final element in find.byType(TextField).evaluate()) {
    rows.add(_rowFor(element));
  }
  for (final element in find.byType(Text).evaluate()) {
    final text = (element.widget as Text).data;
    if (text != null && int.tryParse(text) != null) rows.add(_rowFor(element));
  }
  return rows;
}

void main() {
  group('PlanSidebar layout', () {
    testWidgets('every field row shares one right edge and one width', (tester) async {
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();
      await _expandAll(tester);

      final rows = _fieldRows(tester);
      expect(rows, hasLength(20));

      expect(rows.map((r) => r.right).toSet(), hasLength(1), reason: 'field rows have differing right edges');
      expect(rows.map((r) => r.width).toSet(), hasLength(1), reason: 'field rows have differing widths');
    });

    testWidgets('field rows are never packed tighter than the gap between them', (tester) async {
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();
      await _expandAll(tester);

      final centres = _fieldRows(tester).map((r) => r.center.dy).toList()..sort();
      for (var i = 1; i < centres.length; i++) {
        expect(centres[i] - centres[i - 1], greaterThanOrEqualTo(44.0), reason: 'rows $i and ${i - 1} are closer than a field height plus its gap');
      }
    });

    testWidgets('stepper arrows keep one width, enabled or disabled', (tester) async {
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();
      await _expandAll(tester);

      final arrows = find.byType(IconButton);
      expect(arrows, findsWidgets);

      final widths = <double>{};
      for (var i = 0; i < arrows.evaluate().length; i++) {
        widths.add(tester.getSize(arrows.at(i)).width);
      }
      expect(widths, hasLength(1), reason: 'stepper arrows have differing widths: $widths');
    });

    testWidgets('each value box sits on its label baseline', (tester) async {
      RenderObject.debugCheckingIntrinsics = true;
      addTearDown(() => RenderObject.debugCheckingIntrinsics = false);

      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();
      await _expandAll(tester);

      var checked = 0;
      for (final row in find.byType(Row).evaluate()) {
        // The shared field row is label, gap, then the box-and-stepper piece.
        final children = <Element>[];
        row.visitChildren(children.add);
        if (children.length != 3 || children[2].widget is! Row) continue;

        final labelBaseline = baselineY(children[0]);
        final boxBaseline = baselineY(children[2]);
        if (labelBaseline == null || boxBaseline == null) continue;

        checked++;
        final label = find.descendant(of: find.byWidget(children[0].widget), matching: find.byType(Text)).first;
        expect(labelBaseline, closeTo(boxBaseline, 0.01), reason: '"${(label.evaluate().first.widget as Text).data}" is not on its box baseline');
      }

      expect(checked, 20, reason: 'not every field row reported a baseline');
    });
  });
}