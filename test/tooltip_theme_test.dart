import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:retirement_calculator/main.dart';

/// The theme in effect at [brightness], read back off the tree rather than off a
/// copy of the scheme, so the test covers what a running app actually gets.
Future<ThemeData> themeFor(WidgetTester tester, Brightness brightness) async {
  tester.platformDispatcher.platformBrightnessTestValue = brightness;
  addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
  await tester.pumpAndSettle();

  return Theme.of(tester.element(find.byType(Scaffold).first));
}

/// The colour the tooltip panel is decorated with, which is translucent, so it
/// is never read on its own.
Color panelOf(ThemeData theme) => (theme.tooltipTheme.decoration! as BoxDecoration).color!;

/// The panel as it actually appears: its translucent colour laid over the page
/// behind it, which is what text on the tooltip really sits against.
Color panelOnPage(ThemeData theme) => Color.alphaBlend(panelOf(theme), theme.colorScheme.surface);

/// WCAG contrast between two colours, which is what says whether a tooltip's
/// text stays readable on the panel it was handed.
double contrast(Color a, Color b) {
  final (lighter, darker) = a.computeLuminance() > b.computeLuminance()
      ? (a.computeLuminance(), b.computeLuminance())
      : (b.computeLuminance(), a.computeLuminance());

  return (lighter + 0.05) / (darker + 0.05);
}

/// The floor every colour on the panel has to clear against what is behind it.
const _contrastFloor = 4.5;

void main() {
  group('tooltip theme', () {
    for (final (brightness, name) in [(Brightness.light, 'light'), (Brightness.dark, 'dark')]) {
      testWidgets('the $name tooltip panel is tinted and slightly transparent', (tester) async {
        tester.view.physicalSize = const Size(1500, 700);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(const MainApp());

        final theme = await themeFor(tester, brightness);
        final panel = panelOf(theme);

        // A tint off the theme's own hue, distinct from the plain surface it
        // floats over, but held back far enough to frame the numbers rather
        // than compete with them. The quiet role runs fainter still in dark.
        expect(panel, isNot(theme.colorScheme.surface));
        expect(HSLColor.fromColor(panel).saturation, greaterThan(0.05),
            reason: 'the panel carries no tint at all: $panel');
        expect(HSLColor.fromColor(panel).saturation, lessThan(0.6),
            reason: 'the panel tint is loud enough to compete with the numbers: $panel');
        // Let a little of the page through, but nowhere near clear enough that
        // the table behind a number competes with it.
        expect(panel.a, lessThan(1.0), reason: 'the panel is opaque');
        expect(panel.a, greaterThan(0.85), reason: 'the panel has faded too far to read on');
      });

      testWidgets('the $name tooltip text clears the contrast floor on its panel', (tester) async {
        tester.view.physicalSize = const Size(1500, 700);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(const MainApp());

        final theme = await themeFor(tester, brightness);

        // Checked against the panel as it lands on the page, since the panel is
        // translucent and the page shows through it.
        expect(contrast(theme.tooltipTheme.textStyle!.color!, panelOnPage(theme)), greaterThan(_contrastFloor),
            reason: 'tooltip text is hard to read against its own panel');
      });
    }

    testWidgets('the tooltip panel takes the theme accent, not a color of its own', (tester) async {
      tester.view.physicalSize = const Size(1500, 700);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const MainApp());

      // Same panel in each brightness, drawn from the accent that brightness holds.
      for (final brightness in [Brightness.light, Brightness.dark]) {
        final theme = await themeFor(tester, brightness);
        expect(panelOf(theme).withValues(alpha: 1), theme.colorScheme.surfaceContainerHigh);
        // Text comes from the role that pairs with the container, so the two
        // are contrast-checked against each other by the scheme itself.
        expect(theme.tooltipTheme.textStyle!.color, theme.colorScheme.onSurface);
      }
    });

    testWidgets('the tooltip has a dark gray edge in both brightnesses', (tester) async {
      tester.view.physicalSize = const Size(1500, 700);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const MainApp());

      for (final brightness in [Brightness.light, Brightness.dark]) {
        final theme = await themeFor(tester, brightness);
        final border = (theme.tooltipTheme.decoration! as BoxDecoration).border! as Border;
        final name = brightness == Brightness.light ? 'light' : 'dark';

        expect(border.top.color, theme.colorScheme.outline);
        // Far enough from the panel it outlines to actually read as an edge.
        // Which side of it the border falls flips with the brightness: the dark
        // panel wants a lighter rule, the light one a darker, so this is a
        // floor on the difference rather than a direction.
        expect(contrast(border.top.color, panelOnPage(theme)), greaterThan(1.5),
            reason: 'the border is too close to the $name panel to read as an edge');
        // A neutral rather than a tint of the accent.
        expect(HSLColor.fromColor(border.top.color).saturation, lessThan(0.2),
            reason: 'the $name border is tinted, not gray: ${border.top.color}');
      }
    });
  });
}
