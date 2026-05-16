import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'features/sessions/presentation/tracker_page.dart';
import 'features/feed/presentation/feed_page.dart';
import 'features/coverage/presentation/coverage_page.dart';
import 'features/stats/presentation/stats_page.dart';
import 'features/profile/presentation/profile_page.dart';
import 'features/auth/presentation/login_page.dart';
import 'core/theme/app_theme.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Student Painters',
      theme: AppTheme.light,
      home: const _AuthGate(),
    );
  }
}

class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  Session? _session;

  @override
  void initState() {
    super.initState();
    _session = Supabase.instance.client.auth.currentSession;
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (!mounted) return;
      setState(() => _session = data.session);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_session == null) {
      return const LoginPage();
    }

    return const _MainApp();
  }
}

class _MainApp extends StatefulWidget {
  const _MainApp();

  @override
  State<_MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<_MainApp> {
  int _index = 2;

  final List<Widget> pages = const [
    FeedPage(),
    CoveragePage(),
    TrackerPage(),
    StatsPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        child: Scaffold(
          body: pages[_index],
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _index,
            onTap: (value) => setState(() => _index = value),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.feed),
                label: 'Feed',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.layers),
                label: 'Coverage',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.map),
                label: 'Track',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.bar_chart),
                label: 'Stats',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.more_horiz),
                label: 'More',
              ),
            ],
          ),
        ),
      ),
    );
  }
}