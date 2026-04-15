import 'package:flutter/material.dart';

import '../../sessions/domain/session_type.dart';
import '../data/stats_demo_data.dart';
import '../domain/stats_models.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  late StatsScope _selectedScope;
  SessionType? _selectedType;

  @override
  void initState() {
    super.initState();
    _selectedScope = _defaultScopeForRole(StatsDemoData.currentUserRole);
  }

  StatsScope _defaultScopeForRole(String role) {
    switch (role) {
      case 'Executive':
        return StatsScope.company;
      case 'General Manager':
        return StatsScope.division;
      case 'Branch Manager':
        return StatsScope.division;
      case 'Marketer':
        return StatsScope.branch;
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
    return StatsDemoData.users.where((user) {
      switch (_selectedScope) {
        case StatsScope.company:
          return true;
        case StatsScope.division:
          return user.divisionName == StatsDemoData.currentDivisionName;
        case StatsScope.branch:
          return user.branchId == StatsDemoData.currentBranchId;
        case StatsScope.me:
          return user.userId == StatsDemoData.currentUserId;
      }
    }).toList();
  }

  List<BranchStats> _filteredBranches() {
    return StatsDemoData.branches.where((branch) {
      switch (_selectedScope) {
        case StatsScope.company:
          return true;
        case StatsScope.division:
          return branch.divisionName == StatsDemoData.currentDivisionName;
        case StatsScope.branch:
          return branch.branchId == StatsDemoData.currentBranchId;
        case StatsScope.me:
          return branch.branchId == StatsDemoData.currentBranchId;
      }
    }).toList();
  }

  double _totalHours(List<UserStats> users) {
    return users.fold(0, (sum, user) => sum + user.hoursForType(_selectedType));
  }

  int _totalPeople(List<UserStats> users) {
    return users.length;
  }

  double _averageHours(List<UserStats> users) {
    if (users.isEmpty) return 0;
    return _totalHours(users) / users.length;
  }

  List<UserStats> _sortedUserLeaderboard() {
    final users = List<UserStats>.from(_filteredUsers());
    users.sort(
      (a, b) => b.hoursForType(_selectedType).compareTo(a.hoursForType(_selectedType)),
    );
    return users;
  }

  List<BranchStats> _sortedBranchLeaderboard() {
    final branches = List<BranchStats>.from(_filteredBranches());
    branches.sort(
      (a, b) => b.hoursForType(_selectedType).compareTo(a.hoursForType(_selectedType)),
    );
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
              Text(
                title,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserLeaderboard(List<UserStats> users) {
    if (users.isEmpty) {
      return const Text('No users in this scope.');
    }

    return Column(
      children: users.asMap().entries.map((entry) {
        final rank = entry.key + 1;
        final user = entry.value;
        final hours = user.hoursForType(_selectedType).toStringAsFixed(1);

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: CircleAvatar(
              child: Text('$rank'),
            ),
            title: Text(user.name),
            subtitle: Text('${user.role} • ${user.branchName}'),
            trailing: Text('$hours hrs'),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBranchLeaderboard(List<BranchStats> branches) {
    if (branches.isEmpty) {
      return const Text('No branches in this scope.');
    }

    return Column(
      children: branches.asMap().entries.map((entry) {
        final rank = entry.key + 1;
        final branch = entry.value;
        final hours = branch.hoursForType(_selectedType).toStringAsFixed(1);

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: CircleAvatar(
              child: Text('$rank'),
            ),
            title: Text(branch.branchName),
            subtitle: Text(branch.divisionName),
            trailing: Text('$hours hrs'),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTypeChips() {
    final allSelected = _selectedType == null;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        FilterChip(
          selected: allSelected,
          label: const Text('All'),
          onSelected: (_) {
            setState(() {
              _selectedType = null;
            });
          },
        ),
        ...SessionType.values.map((type) {
          return FilterChip(
            selected: _selectedType == type,
            label: Text(type.label),
            onSelected: (_) {
              setState(() {
                _selectedType = type;
              });
            },
          );
        }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredUsers = _filteredUsers();
    final userLeaderboard = _sortedUserLeaderboard();
    final branchLeaderboard = _sortedBranchLeaderboard();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stats'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Scope',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: StatsScope.values.map((scope) {
                return FilterChip(
                  selected: _selectedScope == scope,
                  label: Text(_scopeLabel(scope)),
                  onSelected: (_) {
                    setState(() {
                      _selectedScope = scope;
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Text(
              'Session Type',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _buildTypeChips(),
            const SizedBox(height: 20),
            Text(
              'Overview',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildOverviewCard(
                  'Total Hours',
                  _totalHours(filteredUsers).toStringAsFixed(1),
                ),
                _buildOverviewCard(
                  'People',
                  _totalPeople(filteredUsers).toString(),
                ),
                _buildOverviewCard(
                  'Avg Hours',
                  _averageHours(filteredUsers).toStringAsFixed(1),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Personal Hours Leaderboard',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            _buildUserLeaderboard(userLeaderboard),
            const SizedBox(height: 24),
            Text(
              'Branch Hours Leaderboard',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            _buildBranchLeaderboard(branchLeaderboard),
          ],
        ),
      ),
    );
  }
}