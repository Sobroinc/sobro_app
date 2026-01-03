import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/auth_service.dart';

/// User profile screen.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    final user = authState is AuthAuthenticated ? authState.user : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: user == null
          ? const Center(child: Text('Not logged in'))
          : _buildContent(context, ref, user),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, User user) {
    final dateFormat = DateFormat('MMMM d, yyyy');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar
          CircleAvatar(
            radius: 60,
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: Text(
              user.username.substring(0, 1).toUpperCase(),
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Name
          Text(
            user.fullName ?? user.username,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '@${user.username}',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),

          // Role badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getRoleColor(user.role).withAlpha(30),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              user.role.toUpperCase(),
              style: TextStyle(
                color: _getRoleColor(user.role),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Info cards
          _buildInfoCard(
            context,
            'Account Information',
            [
              _buildInfoRow(context, Icons.email_outlined, 'Email', user.email ?? 'Not set'),
              _buildInfoRow(context, Icons.badge_outlined, 'Role', user.role),
              _buildInfoRow(
                context,
                Icons.check_circle_outline,
                'Status',
                user.isActive ? 'Active' : 'Inactive',
              ),
              _buildInfoRow(
                context,
                Icons.calendar_today_outlined,
                'Member since',
                dateFormat.format(user.createdAt),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Actions
          _buildInfoCard(
            context,
            'Actions',
            [
              ListTile(
                leading: const Icon(Icons.password_outlined),
                title: const Text('Change Password'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Password change coming soon')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Edit Profile'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Profile editing coming soon')),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Logout button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                _showLogoutDialog(context, ref);
              },
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
                side: BorderSide(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Colors.red;
      case 'manager':
        return Colors.orange;
      case 'user':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Widget _buildInfoCard(BuildContext context, String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(authProvider.notifier).logout();
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
