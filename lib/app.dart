import 'package:flutter/material.dart';
import 'features/sessions/presentation/tracker_page.dart';
import 'features/feed/presentation/feed_page.dart';
import 'features/coverage/presentation/coverage_page.dart';
import 'features/stats/presentation/stats_page.dart';
import 'features/profile/presentation/profile_page.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int _index = 0;

  final pages = const [
    TrackerPage(),
    FeedPage(),
    CoveragePage(),
    StatsPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: pages[_index],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _index,
          onTap: (value) => setState(() => _index = value),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Track'),
            BottomNavigationBarItem(icon: Icon(Icons.feed), label: 'Feed'),
            BottomNavigationBarItem(icon: Icon(Icons.layers), label: 'Coverage'),
            BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Stats'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}