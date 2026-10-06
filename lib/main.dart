import 'package:flutter/material.dart';

import 'pages/breakdown_page.dart';
import 'pages/compare_page.dart';
import 'pages/load_page.dart';
import 'pages/plan_page.dart';
import 'pages/summary_page.dart';
import 'models/portfolio.dart';

void main() {
  runApp(const MainApp());
}

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
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.white),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.white,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: AppBar(
          // The title and the tab strip.
          title: const Text("Eric's Retirement Calculator"),
          centerTitle: true,
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.folder_open),
                    SizedBox(width: 6),
                    Text('Load'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.summarize),
                    SizedBox(width: 6),
                    Text('Summary'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.table_chart),
                    SizedBox(width: 6),
                    Text('Breakdown'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.event_note),
                    SizedBox(width: 6),
                    Text('Plan'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.compare_arrows),
                    SizedBox(width: 6),
                    Text('Compare'),
                  ],
                ),
              ),
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
            const PlanPage(),
            const ComparePage(),
          ],
        ),
      ),
    );
  }
}
