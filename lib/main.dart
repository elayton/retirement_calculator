import 'package:flutter/material.dart';

import 'pages/breakdown_page.dart';
import 'pages/compare_page.dart';
import 'pages/load_page.dart';
import 'pages/plan_page.dart';
import 'pages/summary_page.dart';
import 'models/portfolio_models.dart';

void main() {
  runApp(const MainApp());
}

Tab _iconTab(IconData icon, String label) => Tab(
  child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon), const SizedBox(width: 6), Text(label)]),
);

/// How far a tooltip's own colour is held back, letting a little of the page
/// through so the panel sits over it rather than on top of it. Short of clear
/// enough that the table behind a number starts to compete with it.
const _tooltipOpacity = 0.94;

/// Tooltips float above a page, so they read as a panel laid over it rather than
/// as more of it. [ColorScheme.surfaceContainerHigh] is a step off the page's
/// own surface, holding just enough of the theme's hue to tell the panel apart
/// from what it floats over. The tint is faint by design: this is among the
/// quietest of the accent-carrying roles, and anything stronger competes with
/// the numbers for the eye instead of framing them.
///
/// Text comes from [ColorScheme.onSurface], the role that pairs with it. That
/// pairing is what keeps the numbers readable: take the background from the
/// scheme and the foreground from its matching `on` role and the two are
/// contrast-checked against each other by construction, in either brightness.
/// The Material default pairs neither, and paints its background at 90%.
TooltipThemeData _tooltipTheme(ColorScheme colorScheme) => TooltipThemeData(
  decoration: BoxDecoration(
    color: colorScheme.surfaceContainerHigh.withValues(alpha: _tooltipOpacity),
    borderRadius: BorderRadius.circular(4),
    // An edge, so the panel reads as a panel rather than a wash of colour over
    // the page. [ColorScheme.outline] is the scheme's full-weight outline and
    // the only role that stays a dark neutral in both brightnesses;
    // `outlineVariant` would read pale against this panel in light mode and
    // lose the edge entirely.
    border: Border.all(color: colorScheme.outline),
  ),
  // Padding wide enough to sit inside the border rather than against it. The
  // default is a little short of that and not quite even top to bottom, which
  // reads as the tooltip being tighter at one end than the other.
  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
  // Carried by the text style rather than set per amount, so it reaches the
  // Initial and Total lines too, which take no colour of their own.
  textStyle: TextStyle(color: colorScheme.onSurface),
);

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  Portfolio? _portfolio;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Both schemes come off the same white seed, so the neutrals they hold are
    // grays. Each is held in a local because the tooltip theme is built from it.
    final colorScheme = ColorScheme.fromSeed(seedColor: Colors.white);
    final darkColorScheme = ColorScheme.fromSeed(seedColor: Colors.white, brightness: Brightness.dark);

    return MaterialApp(
      theme: ThemeData(colorScheme: colorScheme, useMaterial3: true, tooltipTheme: _tooltipTheme(colorScheme)),
      darkTheme: ThemeData(
        colorScheme: darkColorScheme,
        useMaterial3: true,
        tooltipTheme: _tooltipTheme(darkColorScheme),
      ),
      home: Scaffold(
        appBar: AppBar(
          // The title and the tab strip.
          title: const Text("Eric's Retirement Calculator"),
          centerTitle: true,
          bottom: TabBar(
            controller: _tabController,
            tabs: [
              _iconTab(Icons.folder_open, 'Load'),
              _iconTab(Icons.summarize, 'Summary'),
              _iconTab(Icons.table_chart, 'Breakdown'),
              _iconTab(Icons.event_note, 'Plan'),
              _iconTab(Icons.compare_arrows, 'Compare'),
            ],
          ),
        ),
        body: TabBarView(
          // One page is shown per tab.
          controller: _tabController,
          children: [
            LoadPage(
              onLoaded: (portfolio) {
                setState(() => _portfolio = portfolio);
                _tabController.animateTo(1);
              },
            ),
            SummaryPage(portfolio: _portfolio),
            BreakdownPage(portfolio: _portfolio),
            PlanPage(portfolio: _portfolio),
            const ComparePage(),
          ],
        ),
      ),
    );
  }
}
