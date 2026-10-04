import 'package:flutter/material.dart';

import 'pages/breakdown_page.dart';
import 'pages/compare_page.dart';
import 'pages/load_page.dart';
import 'pages/plan_page.dart';
import 'pages/summary_page.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

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
      home: Scaffold(
        appBar: AppBar(
          title: const Text("Eric's Retirement Calculator"),
          centerTitle: true,
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [Icon(Icons.folder_open), SizedBox(width: 6), Text('Load')],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [Icon(Icons.summarize), SizedBox(width: 6), Text('Summary')],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [Icon(Icons.pie_chart), SizedBox(width: 6), Text('Breakdown')],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [Icon(Icons.event_note), SizedBox(width: 6), Text('Plan')],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [Icon(Icons.compare_arrows), SizedBox(width: 6), Text('Compare')],
                ),
              ),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: const [
            LoadPage(),
            SummaryPage(),
            BreakdownPage(),
            PlanPage(),
            ComparePage(),
          ],
        ),
      ),
    );
  }
}
