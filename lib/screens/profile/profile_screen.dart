import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/design_tokens.dart';
import '../../providers/auth_provider.dart';
import '../categories/category_management_screen.dart';
import '../auth/auth_wrapper.dart';
import 'edit_profile_screen.dart';
import 'notification_settings_screen.dart';
import 'privacy_settings_screen.dart';
import 'appearance_settings_screen.dart';
import 'data_export_screen.dart';

/// Simple Profile Screen
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(userProvider);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text('Profile'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
      ),
      body: user.when(
        data: (user) => _buildContent(context, theme, ref, user),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error: $error', style: theme.textTheme.bodyLarge),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, ThemeData theme, WidgetRef ref, user) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(DesignTokens.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProfileHeader(theme, user),
          SizedBox(height: DesignTokens.space6),
          _buildSettingsList(context, theme, ref),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(ThemeData theme, user) {
    return Container(
      padding: EdgeInsets.all(DesignTokens.space6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: theme.colorScheme.primary,
            child: Icon(
              Icons.person_rounded,
              size: 50,
              color: theme.colorScheme.onPrimary,
            ),
          ),
          SizedBox(height: DesignTokens.space4),
          Text(
            user?.name ?? 'User',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: DesignTokens.fontWeightBold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: DesignTokens.space2),
          Text(
            user?.email ?? 'user@example.com',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsList(BuildContext context, ThemeData theme, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Settings',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: DesignTokens.fontWeightBold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: DesignTokens.space4),
        _buildSettingsItem(context, theme, 'Edit Profile', Icons.person_outline, onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const EditProfileScreen()),
          );
        }),
        _buildSettingsItem(context, theme, 'Categories', Icons.category_outlined, onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CategoryManagementScreen()),
          );
        }),
        _buildSettingsItem(context, theme, 'Notifications', Icons.notifications_outlined, onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const NotificationSettingsScreen()),
          );
        }),
        _buildSettingsItem(context, theme, 'Privacy', Icons.security_outlined, onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PrivacySettingsScreen()),
          );
        }),
        _buildSettingsItem(context, theme, 'Appearance', Icons.palette_outlined, onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AppearanceSettingsScreen()),
          );
        }),
        _buildSettingsItem(context, theme, 'Export Data', Icons.download_outlined, onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const DataExportScreen()),
          );
        }),
        _buildSettingsItem(context, theme, 'Sign Out', Icons.logout, isDestructive: true, onTap: () => _handleSignOut(context, ref)),
      ],
    );
  }

  Widget _buildSettingsItem(BuildContext context, ThemeData theme, String title, IconData icon, {bool isDestructive = false, VoidCallback? onTap}) {
    final color = isDestructive ? DesignTokens.error : theme.colorScheme.onSurfaceVariant;
    
    return Container(
      margin: EdgeInsets.only(bottom: DesignTokens.space2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: color, size: 24),
        title: Text(
          title,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: DesignTokens.fontWeightMedium,
            color: isDestructive ? DesignTokens.error : theme.colorScheme.onSurface,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: theme.colorScheme.onSurfaceVariant,
          size: 20,
        ),
      ),
    );
  }

  void _handleSignOut(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(userProvider.notifier).signOut();
                if (context.mounted) {
                  // Navigate back to AuthWrapper which will show LoginScreen
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const AuthWrapper()),
                    (route) => false,
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to sign out: $e'),
                      backgroundColor: DesignTokens.error,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: DesignTokens.error),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}
