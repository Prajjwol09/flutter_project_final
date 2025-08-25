import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finlytic/utils/design_tokens.dart';
import 'package:finlytic/theme/app_theme.dart';
import 'package:finlytic/widgets/cards.dart';

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends ConsumerState<NotificationSettingsScreen> {
  bool _budgetAlerts = true;
  bool _expenseReminders = true;
  bool _weeklyReports = false;
  bool _monthlyReports = true;
  bool _promotionalEmails = false;
  bool _pushNotifications = true;
  bool _emailNotifications = true;
  bool _smsNotifications = false;

  String _budgetAlertThreshold = '80%';
  String _reminderTime = '9:00 AM';

  final List<String> _thresholds = ['50%', '70%', '80%', '90%', '95%'];
  final List<String> _times = [
    '8:00 AM', '9:00 AM', '10:00 AM', '6:00 PM', '7:00 PM', '8:00 PM'
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Notification Settings'),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(DesignTokens.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Budget Alerts Section
            _buildSectionTitle('Budget Alerts'),
            _buildNotificationCard(
              'Budget Limit Alerts',
              'Get notified when approaching budget limits',
              Icons.account_balance_wallet_outlined,
              _budgetAlerts,
              (value) => setState(() => _budgetAlerts = value),
              child: _budgetAlerts ? _buildBudgetAlertSettings() : null,
            ),
            
            const SizedBox(height: DesignTokens.space6),
            
            // Expense Reminders Section
            _buildSectionTitle('Expense Reminders'),
            _buildNotificationCard(
              'Daily Expense Reminders',
              'Remind me to log my daily expenses',
              Icons.receipt_outlined,
              _expenseReminders,
              (value) => setState(() => _expenseReminders = value),
              child: _expenseReminders ? _buildReminderSettings() : null,
            ),
            
            const SizedBox(height: DesignTokens.space6),
            
            // Reports Section
            _buildSectionTitle('Reports'),
            _buildNotificationCard(
              'Weekly Reports',
              'Get weekly spending summaries',
              Icons.bar_chart_outlined,
              _weeklyReports,
              (value) => setState(() => _weeklyReports = value),
            ),
            const SizedBox(height: DesignTokens.space2),
            _buildNotificationCard(
              'Monthly Reports',
              'Get monthly financial insights',
              Icons.analytics_outlined,
              _monthlyReports,
              (value) => setState(() => _monthlyReports = value),
            ),
            
            const SizedBox(height: DesignTokens.space6),
            
            // Marketing Section
            _buildSectionTitle('Marketing'),
            _buildNotificationCard(
              'Promotional Emails',
              'Receive tips and feature updates',
              Icons.campaign_outlined,
              _promotionalEmails,
              (value) => setState(() => _promotionalEmails = value),
            ),
            
            const SizedBox(height: DesignTokens.space6),
            
            // Delivery Methods Section
            _buildSectionTitle('Delivery Methods'),
            _buildNotificationCard(
              'Push Notifications',
              'Receive notifications on your device',
              Icons.notifications_outlined,
              _pushNotifications,
              (value) => setState(() => _pushNotifications = value),
            ),
            const SizedBox(height: DesignTokens.space2),
            _buildNotificationCard(
              'Email Notifications',
              'Receive notifications via email',
              Icons.email_outlined,
              _emailNotifications,
              (value) => setState(() => _emailNotifications = value),
            ),
            const SizedBox(height: DesignTokens.space2),
            _buildNotificationCard(
              'SMS Notifications',
              'Receive notifications via text message',
              Icons.sms_outlined,
              _smsNotifications,
              (value) => setState(() => _smsNotifications = value),
            ),
            
            const SizedBox(height: DesignTokens.space8),
            
            // Quiet Hours Section
            _buildSectionTitle('Quiet Hours'),
            _buildQuietHoursCard(),
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

  Widget _buildNotificationCard(
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

  Widget _buildBudgetAlertSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Alert Threshold',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: DesignTokens.space2),
        Wrap(
          spacing: DesignTokens.space2,
          children: _thresholds.map((threshold) {
            final isSelected = threshold == _budgetAlertThreshold;
            return ChoiceChip(
              label: Text(threshold),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _budgetAlertThreshold = threshold);
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildReminderSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reminder Time',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: DesignTokens.space2),
        Wrap(
          spacing: DesignTokens.space2,
          children: _times.map((time) {
            final isSelected = time == _reminderTime;
            return ChoiceChip(
              label: Text(time),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _reminderTime = time);
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildQuietHoursCard() {
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
                  Icons.bedtime_outlined,
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
                      'Quiet Hours',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'No notifications during these hours',
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
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _selectTime('start'),
                  child: const Text('10:00 PM'),
                ),
              ),
              const SizedBox(width: DesignTokens.space2),
              const Text('to'),
              const SizedBox(width: DesignTokens.space2),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _selectTime('end'),
                  child: const Text('7:00 AM'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _selectTime(String type) {
    showTimePicker(
      context: context,
      initialTime: type == 'start' 
          ? const TimeOfDay(hour: 22, minute: 0)
          : const TimeOfDay(hour: 7, minute: 0),
    ).then((time) {
      if (time != null && mounted) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${type == 'start' ? 'Start' : 'End'} time updated to ${time.format(context)}'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    });
  }
}