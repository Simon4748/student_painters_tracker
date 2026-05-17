import 'package:flutter/material.dart';

import '../../sessions/domain/session_type.dart';
import '../domain/stats_models.dart';
import '../../../shared/providers/user_provider.dart';
import '../../../shared/services/stats_service.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  late StatsScope _selectedScope;
  SessionType? _selectedType;

  List<UserStats> _userStats = [];
  List<BranchStats> _branchStats = [];
  bool _isLoading = true;
  bool _scopeInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_scopeInitialized) {
      final user = UserProvider.of(context);
      _selectedScope = _defaultScopeForRole(user.role);
      _scopeInitialized = true;
      _loadStats();
    }
  }

  Future<void> _loadStats() async {
    final user = UserProvider.of(context);
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        StatsService.fetchUserStats(user.branchId),
        StatsService.fetchBranchStats(),
      ]);

      if (!mounted) return;
      setState(() {
        _userStats = results[0] as List<UserStats>;
        _branchStats = results[1] as List<BranchStats>;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load stats: $e')),
      );
    }
  }

  StatsScope _defaultScopeForRole(String role) {
    switch (role) {
      case 'executive':
        return StatsScope.company;
      case 'general_manager':
        return StatsScope.division;
      case 'branch_manager':
        return StatsScope.division;
      default:
        return StatsScope.branch;
    }
  }

  String _scopeLabel(StatsScope scope) {
    switch (scope) {
      case StatsScope.company:
        return 'Company';
      case StatsScope.division:
        return 'Division';
      case StatsScope.branch:
        return 'Branch';
      case StatsScope.me:
        return 'Me';
    }
  }

  List<UserStats> _filteredUsers() {
    final user = UserProvider.of(context);
    return _userStats.where((u) {
      switch (_selectedScope) {
        case StatsScope.company:
          return true;
        case StatsScope.division:
          return u.divisionName == user.divisionName;
        case StatsScope.branch:
          return u.branchId == user.branchId;
        case StatsScope.me:
          return u.userId == user.id;
      }
    }).toList();
  }

  List<BranchStats> _filteredBranches() {
    final user = UserProvider.of(context);
    return _branchStats.where((b) {
      switch (_selectedScope) {
        case StatsScope.company:
          return true;
        case StatsScope.division:
          return b.divisionName == user.divisionName;
        case StatsScope.branch:
        case StatsScope.me:
          return b.branchId == user.branchId;
      }
    }).toList();
  }

  double _totalHours(List<UserStats> users) =>
      users.fold(0, (sum, u) => sum + u.hoursForType(_selectedType));

  double _averageHours(List<UserStats> users) {
    if (users.isEmpty) return 0;
    return _totalHours(users) / users.length;
  }

  List<UserStats> _sortedUserLeaderboard() {
    final users = List<UserStats>.from(_filteredUsers());
    users.sort((a, b) =>
        b.hoursForType(_selectedType).compareTo(a.hoursForType(_selectedType)));
    return users;
  }

  List<BranchStats> _sortedBranchLeaderboard() {
    final branches = List<BranchStats>.from(_filteredBranches());
    branches.sort((a, b) =>
        b.hoursForType(_selectedType).compareTo(a.hoursForType(_selectedType)));
    return branches;
  }

  Widget _buildOverviewCard(String title, String value) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(title, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserLeaderboard(List<UserStats> users) {
    if (users.isEmpty) return const Text('No users in this scope.');

    return Column(
      children: users.asMap().entries.map((entry) {
        final rank = entry.key + 1;
        final user = entry.value;
        final hours = user.hoursForType(_selectedType).toStringAsFixed(1);

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: CircleAvatar(child: Text('$rank')),
            title: Text(user.name),
            subtitle: Text('${user.role} • ${user.branchName}'),
            trailing: Text('$hours hrs'),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBranchLeaderboard(List<BranchStats> branches) {
    if (branches.isEmpty) return const Text('No branches in this scope.');

    return Column(
      children: branches.asMap().entries.map((entry) {
        final rank = entry.key + 1;
        final branch = entry.value;
        final hours = branch.hoursForType(_selectedType).toStringAsFixed(1);

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: CircleAvatar(child: Text('$rank')),
            title: Text(branch.branchName),
            subtitle: Text(branch.divisionName),
            trailing: Text('$hours hrs'),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTypeChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        FilterChip(
          selected: _selectedType == null,
          label: const Text('All'),
          onSelected: (_) => setState(() => _selectedType = null),
        ),
        ...SessionType.values.map((type) => FilterChip(
              selected: _selectedType == type,
              label: Text(type.label),
              onSelected: (_) => setState(() => _selectedType = type),
            )),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final filteredUsers = _filteredUsers();
    final userLeaderboard = _sortedUserLeaderboard();
    final branchLeaderboard = _sortedBranchLeaderboard();

    return Scaffold(
      appBar: AppBar(title: null),
      body: RefreshIndicator(
        onRefresh: _loadStats,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Scope', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: StatsScope.values.map((scope) {
                  return FilterChip(
                    selected: _selectedScope == scope,
                    label: Text(_scopeLabel(scope)),
                    onSelected: (_) =>
                        setState(() => _selectedScope = scope),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Text('Session Type',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              _buildTypeChips(),
              const SizedBox(height: 20),
              Text('Overview',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildOverviewCard(
                    'Total Hours',
                    _totalHours(filteredUsers).toStringAsFixed(1),
                  ),
                  _buildOverviewCard(
                    'People',
                    filteredUsers.length.toString(),
                  ),
                  _buildOverviewCard(
                    'Avg Hours',
                    _averageHours(filteredUsers).toStringAsFixed(1),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text('Personal Leaderboard',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              _buildUserLeaderboard(userLeaderboard),
              const SizedBox(height: 24),
              Text('Branch Leaderboard',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              _buildBranchLeaderboard(branchLeaderboard),
            ],
          ),
        ),
      ),
    );
  }
}