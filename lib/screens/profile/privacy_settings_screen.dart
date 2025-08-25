import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finlytic/utils/design_tokens.dart';
import 'package:finlytic/theme/app_theme.dart';
import 'package:finlytic/widgets/cards.dart';

class PrivacySettingsScreen extends ConsumerStatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  ConsumerState<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends ConsumerState<PrivacySettingsScreen> {
  bool _analyticsSharing = false;
  bool _crashReporting = true;
  bool _performanceData = true;
  bool _marketingData = false;
  bool _locationData = false;
  bool _biometricLock = false;
  bool _autoLock = true;
  
  String _autoLockDuration = '5 minutes';
  String _dataRetention = '2 years';

  final List<String> _lockDurations = ['1 minute', '5 minutes', '15 minutes', '30 minutes', '1 hour'];
  final List<String> _retentionPeriods = ['1 year', '2 years', '5 years', 'Forever'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Privacy & Security'),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(DesignTokens.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Data Sharing Section
            _buildSectionTitle('Data Sharing'),
            _buildPrivacyCard(
              'Analytics Data',
              'Share anonymous usage data to improve the app',
              Icons.analytics_outlined,
              _analyticsSharing,
              (value) => setState(() => _analyticsSharing = value),
            ),
            const SizedBox(height: DesignTokens.space2),
            _buildPrivacyCard(
              'Crash Reporting',
              'Send crash reports to help fix issues',
              Icons.bug_report_outlined,
              _crashReporting,
              (value) => setState(() => _crashReporting = value),
            ),
            const SizedBox(height: DesignTokens.space2),
            _buildPrivacyCard(
              'Performance Data',
              'Share performance metrics',
              Icons.speed_outlined,
              _performanceData,
              (value) => setState(() => _performanceData = value),
            ),
            const SizedBox(height: DesignTokens.space2),
            _buildPrivacyCard(
              'Marketing Data',
              'Allow data usage for marketing purposes',
              Icons.campaign_outlined,
              _marketingData,
              (value) => setState(() => _marketingData = value),
            ),
            
            const SizedBox(height: DesignTokens.space6),
            
            // Location & Tracking Section
            _buildSectionTitle('Location & Tracking'),
            _buildPrivacyCard(
              'Location Services',
              'Use location for expense categorization',
              Icons.location_on_outlined,
              _locationData,
              (value) => setState(() => _locationData = value),
            ),
            
            const SizedBox(height: DesignTokens.space6),
            
            // Security Section
            _buildSectionTitle('App Security'),
            _buildPrivacyCard(
              'Biometric Lock',
              'Use fingerprint or face ID to unlock',
              Icons.fingerprint_outlined,
              _biometricLock,
              (value) => setState(() => _biometricLock = value),
            ),
            const SizedBox(height: DesignTokens.space2),
            _buildPrivacyCard(
              'Auto Lock',
              'Automatically lock the app when inactive',
              Icons.lock_clock_outlined,
              _autoLock,
              (value) => setState(() => _autoLock = value),
              child: _autoLock ? _buildAutoLockSettings() : null,
            ),
            
            const SizedBox(height: DesignTokens.space6),
            
            // Data Management Section
            _buildSectionTitle('Data Management'),
            _buildDataRetentionCard(),
            
            const SizedBox(height: DesignTokens.space6),
            
            // Account Actions Section
            _buildSectionTitle('Account Actions'),
            _buildAccountActionsCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.space4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildPrivacyCard(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged, {
    Widget? child,
  }) {
    return AppCard(
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(DesignTokens.space2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                ),
                child: Icon(
                  icon,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: DesignTokens.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: value,
                onChanged: onChanged,
              ),
            ],
          ),
          if (child != null) ...[
            const SizedBox(height: DesignTokens.space4),
            const Divider(),
            const SizedBox(height: DesignTokens.space4),
            child,
          ],
        ],
      ),
    );
  }

  Widget _buildAutoLockSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Auto Lock Duration',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: DesignTokens.space2),
        Wrap(
          spacing: DesignTokens.space2,
          children: _lockDurations.map((duration) {
            final isSelected = duration == _autoLockDuration;
            return ChoiceChip(
              label: Text(duration),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _autoLockDuration = duration);
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDataRetentionCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(DesignTokens.space2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                ),
                child: Icon(
                  Icons.storage_outlined,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: DesignTokens.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Data Retention',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'How long to keep your financial data',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.space4),
          const Divider(),
          const SizedBox(height: DesignTokens.space4),
          Text(
            'Retention Period',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: DesignTokens.space2),
          Wrap(
            spacing: DesignTokens.space2,
            children: _retentionPeriods.map((period) {
              final isSelected = period == _dataRetention;
              return ChoiceChip(
                label: Text(period),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _dataRetention = period);
                  }
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountActionsCard() {
    return AppCard(
      child: Column(
        children: [
          _buildActionOption(
            'Export My Data',
            'Download all your personal data',
            Icons.download_outlined,
            _exportData,
          ),
          const Divider(),
          _buildActionOption(
            'Data Usage Report',
            'See how your data is being used',
            Icons.assessment_outlined,
            _viewDataUsage,
          ),
          const Divider(),
          _buildActionOption(
            'Clear Local Cache',
            'Clear temporarily stored data',
            Icons.clear_all_outlined,
            _clearCache,
          ),
          const Divider(),
          _buildActionOption(
            'Delete All Data',
            'Permanently delete all your data',
            Icons.delete_forever_outlined,
            _deleteAllData,
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildActionOption(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(DesignTokens.space2),
        decoration: BoxDecoration(
          color: (isDestructive ? AppTheme.error : Theme.of(context).colorScheme.primary).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        ),
        child: Icon(
          icon,
          color: isDestructive ? AppTheme.error : Theme.of(context).colorScheme.primary,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w500,
          color: isDestructive ? AppTheme.error : null,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  void _exportData() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Data'),
        content: const Text('Your data will be exported as a JSON file. This may take a few moments.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Data export started. You will be notified when complete.'),
                  backgroundColor: AppTheme.success,
                ),
              );
            },
            child: const Text('Export'),
          ),
        ],
      ),
    );
  }

  void _viewDataUsage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Data usage report will be implemented'),
        backgroundColor: DesignTokens.accent,
      ),
    );
  }

  void _clearCache() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text('This will clear temporarily stored data. Your personal data will not be affected.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cache cleared successfully'),
                  backgroundColor: AppTheme.success,
                ),
              );
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _deleteAllData() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Data'),
        content: const Text(
          'This will permanently delete all your financial data. This action cannot be undone.\n\nAre you sure you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
  }
}