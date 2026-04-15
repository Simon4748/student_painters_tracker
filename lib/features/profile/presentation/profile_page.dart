import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _notificationsEnabled = true;
  bool _cellularUploadsEnabled = false;
  bool _darkModeEnabled = false;

  final String _userName = 'Simon';
  final String _userRole = 'Branch Manager';
  final String _branchName = 'Brattleboro Branch';
  final String _divisionName = 'New England';
  final String _email = 'simon@example.com';

  void _showPlaceholder(String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label coming next')),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge,
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    Color? textColor,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon, color: iconColor),
        title: Text(
          title,
          style: textColor != null ? TextStyle(color: textColor) : null,
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account & Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 34,
                    child: Icon(Icons.person, size: 34),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _userName,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _userRole,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _buildSectionTitle('Account'),
            _buildInfoTile(
              icon: Icons.email_outlined,
              title: 'Email',
              subtitle: _email,
            ),
            _buildInfoTile(
              icon: Icons.apartment_outlined,
              title: 'Branch',
              subtitle: _branchName,
            ),
            _buildInfoTile(
              icon: Icons.public_outlined,
              title: 'Division',
              subtitle: _divisionName,
            ),

            const SizedBox(height: 20),
            _buildSectionTitle('Preferences'),
            Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: SwitchListTile(
                title: const Text('Notifications'),
                subtitle: const Text('Receive updates about feed activity and team progress'),
                value: _notificationsEnabled,
                onChanged: (value) {
                  setState(() {
                    _notificationsEnabled = value;
                  });
                },
              ),
            ),
            Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: SwitchListTile(
                title: const Text('Use Cellular Data for Uploads'),
                subtitle: const Text('Allow photo uploads when not on Wi-Fi'),
                value: _cellularUploadsEnabled,
                onChanged: (value) {
                  setState(() {
                    _cellularUploadsEnabled = value;
                  });
                },
              ),
            ),
            Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: SwitchListTile(
                title: const Text('Dark Mode'),
                subtitle: const Text('Demo toggle for future theme controls'),
                value: _darkModeEnabled,
                onChanged: (value) {
                  setState(() {
                    _darkModeEnabled = value;
                  });
                },
              ),
            ),

            const SizedBox(height: 20),
            _buildSectionTitle('Management'),
            _buildActionTile(
              icon: Icons.edit_outlined,
              title: 'Edit Profile',
              onTap: () => _showPlaceholder('Edit Profile'),
            ),
            _buildActionTile(
              icon: Icons.group_outlined,
              title: 'Manage Branch Members',
              onTap: () => _showPlaceholder('Manage Branch Members'),
            ),
            _buildActionTile(
              icon: Icons.security_outlined,
              title: 'Permissions & Account Type',
              onTap: () => _showPlaceholder('Permissions & Account Type'),
            ),

            const SizedBox(height: 20),
            _buildSectionTitle('Account Actions'),
            _buildActionTile(
              icon: Icons.logout,
              iconColor: Colors.red,
              textColor: Colors.red,
              title: 'Sign Out',
              onTap: () => _showPlaceholder('Sign Out'),
            ),
          ],
        ),
      ),
    );
  }
}