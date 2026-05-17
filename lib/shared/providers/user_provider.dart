import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/user_service.dart';

class UserProvider extends InheritedWidget {
  final UserProfile profile;

  const UserProvider({
    super.key,
    required this.profile,
    required super.child,
  });

  static UserProfile of(BuildContext context) {
    final provider =
        context.dependOnInheritedWidgetOfExactType<UserProvider>();
    if (provider == null) throw Exception('UserProvider not found in widget tree');
    return provider.profile;
  }

  @override
  bool updateShouldNotify(UserProvider oldWidget) {
    return profile.id != oldWidget.profile.id;
  }
}

class UserProviderLoader extends StatefulWidget {
  final Widget child;

  const UserProviderLoader({
    super.key,
    required this.child,
  });

  @override
  State<UserProviderLoader> createState() => _UserProviderLoaderState();
}

class _UserProviderLoaderState extends State<UserProviderLoader> {
  UserProfile? _profile;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await UserService.fetchCurrentProfile();
      if (!mounted) return;
      setState(() => _profile = profile);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        body: Center(child: Text('Failed to load profile: $_error')),
      );
    }

    if (_profile == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return UserProvider(
      profile: _profile!,
      child: widget.child,
    );
  }
}