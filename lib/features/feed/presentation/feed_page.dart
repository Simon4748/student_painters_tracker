import 'package:flutter/material.dart';

import '../../../shared/models/feed_scope.dart';
import '../../../shared/providers/user_provider.dart';
import '../../../shared/services/feed_service.dart';
import 'create_post_page.dart';
import 'feed_item_card.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late FeedScope _selectedScope;

  List<Map<String, dynamic>> _allItems = [];
  bool _isLoading = true;
  bool _scopeInitialized = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedScope = FeedScope.branch;
    _tabController = TabController(
      length: FeedScope.values.length,
      vsync: this,
      initialIndex: FeedScope.values.indexOf(_selectedScope),
    );
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _selectedScope = FeedScope.values[_tabController.index];
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_scopeInitialized) {
      final user = UserProvider.of(context);
      _selectedScope = _defaultScopeForRole(user.role);
      _tabController.animateTo(FeedScope.values.indexOf(_selectedScope));
      _scopeInitialized = true;
    }
    _loadFeed();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  FeedScope _defaultScopeForRole(String role) {
    switch (role) {
      case 'executive':
        return FeedScope.company;
      case 'general_manager':
        return FeedScope.division;
      case 'branch_manager':
        return FeedScope.division;
      case 'marketer':
        return FeedScope.branch;
      default:
        return FeedScope.branch;
    }
  }

  Future<void> _loadFeed() async {
    final user = UserProvider.of(context);
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final items = await FeedService.fetchFeedForBranch(user.branchId);
      if (!mounted) return;
      setState(() {
        _allItems = items;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _filteredItems() {
    final user = UserProvider.of(context);
    return _allItems.where((item) {
      switch (_selectedScope) {
        case FeedScope.company:
          return true;
        case FeedScope.division:
          final divisionName =
              item['branches']?['divisions']?['name'] as String?;
          return divisionName == user.divisionName;
        case FeedScope.branch:
          print('Filtering branch: item=${item['branch_id']} user=${user.branchId}');
          return item['branch_id'] == user.branchId;
        case FeedScope.me:
          return item['profiles']?['id'] == user.id;
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
      _loadFeed();
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _filteredItems();

    return Scaffold(
      appBar: AppBar(
        title: null,
        bottom: TabBar(
          controller: _tabController,
          tabs: FeedScope.values
              .map((scope) => Tab(text: _scopeLabel(scope)))
              .toList(),
          indicator: const UnderlineTabIndicator(
            borderSide: BorderSide(
              color: Color(0xFFE93324),
              width: 2.5,
            ),
          ),
          indicatorSize: TabBarIndicatorSize.label,
          labelColor: Colors.black87,
          unselectedLabelColor: Colors.grey,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
          dividerColor: Colors.transparent,
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreatePostPage,
        icon: const Icon(Icons.add),
        label: const Text('Post'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Failed to load feed: $_error'),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _loadFeed,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : items.isEmpty
                  ? const Center(child: Text('No feed items yet'))
                  : RefreshIndicator(
                      onRefresh: _loadFeed,
                      child: ListView.builder(
                        padding:
                            const EdgeInsets.fromLTRB(16, 12, 16, 80),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          return FeedItemCard(
                            item: items[index],
                            onChanged: _loadFeed,
                          );
                        },
                      ),
                    ),
    );
  }
}