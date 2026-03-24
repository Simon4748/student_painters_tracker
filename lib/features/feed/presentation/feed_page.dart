import 'package:flutter/material.dart';

import '../../../shared/models/feed_item.dart';
import '../../../shared/models/feed_scope.dart';
import '../../../shared/models/feed_store.dart';
import 'create_post_page.dart';
import 'feed_item_card.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  // Demo current user state
  final String _currentUserId = 'manager_1';
  final String _currentBranchId = 'brattleboro_branch';
  final String _currentDivisionName = 'New England';
  final String _currentUserRole = 'Branch Manager';

  late FeedScope _selectedScope;

  @override
  void initState() {
    super.initState();
    _selectedScope = _defaultScopeForRole(_currentUserRole);
  }

  FeedScope _defaultScopeForRole(String role) {
    switch (role) {
      case 'Executive':
        return FeedScope.company;
      case 'General Manager':
        return FeedScope.division;
      case 'Branch Manager':
        return FeedScope.division;
      case 'Marketer':
        return FeedScope.branch;
      default:
        return FeedScope.branch;
    }
  }

  List<FeedItem> _filteredItems() {
    return FeedStore.items.where((item) {
      switch (_selectedScope) {
        case FeedScope.company:
          return true;
        case FeedScope.division:
          return item.divisionName == _currentDivisionName;
        case FeedScope.branch:
          return item.branchId == _currentBranchId;
        case FeedScope.me:
          return item.authorId == _currentUserId;
      }
    }).toList();
  }

  String _scopeLabel(FeedScope scope) {
    switch (scope) {
      case FeedScope.company:
        return 'Company';
      case FeedScope.division:
        return 'Division';
      case FeedScope.branch:
        return 'Branch';
      case FeedScope.me:
        return 'Me';
    }
  }

  Future<void> _openCreatePostPage() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const CreatePostPage(),
      ),
    );

    if (created == true && mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _filteredItems();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Feed'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreatePostPage,
        icon: const Icon(Icons.add),
        label: const Text('Post'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Viewing',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: FeedScope.values.map((scope) {
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
                const SizedBox(height: 12),
                Text(
                  'Showing ${items.length} item(s)',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? const Center(
                    child: Text('No feed items yet'),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      return FeedItemCard(item: items[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}