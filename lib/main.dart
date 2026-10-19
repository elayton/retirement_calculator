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

/// How far a tooltip's own colour is held back, so the panel sits over the page
/// rather than on top of it.
const _tooltipOpacity = 0.94;

/// Tooltips read as a panel laid over the page, so the background is a step off
/// the page's own surface and the text is its matching `on` role: the two are
/// then contrast-checked against each other by construction. The Material
/// default pairs neither, and paints its background at 90%.
TooltipThemeData _tooltipTheme(ColorScheme colorScheme) => TooltipThemeData(
  decoration: BoxDecoration(
    color: colorScheme.surfaceContainerHigh.withValues(alpha: _tooltipOpacity),
    borderRadius: BorderRadius.circular(4),
    // `outlineVariant` would read pale against this panel in light mode;
    // `outline` holds a dark neutral in both brightnesses.
    border: Border.all(color: colorScheme.outline),
  ),
  // Wide enough to sit inside the border rather than against it; the default is
  // a little short and not quite even top to bottom.
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
    // Both schemes come off the same white seed, so the neutrals they hold are grays.
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
