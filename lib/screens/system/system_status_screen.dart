import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/connectivity_service.dart';
import '../../services/offline_sync_service.dart';
import '../../services/error_handling_service.dart';
import '../../services/app_initialization_service.dart';
import '../../services/local_storage_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/design_tokens.dart';
import '../../widgets/cards.dart';

class SystemStatusScreen extends ConsumerStatefulWidget {
  const SystemStatusScreen({super.key});

  @override
  ConsumerState<SystemStatusScreen> createState() => _SystemStatusScreenState();
}

class _SystemStatusScreenState extends ConsumerState<SystemStatusScreen> {
  bool _isRefreshing = false;
  Map<String, dynamic>? _healthCheckData;

  @override
  void initState() {
    super.initState();
    _performHealthCheck();
  }

  Future<void> _performHealthCheck() async {
    setState(() => _isRefreshing = true);
    
    try {
      final appInitService = ref.read(appInitializationServiceProvider);
      final healthData = await appInitService.performHealthCheck();
      
      setState(() {
        _healthCheckData = healthData;
        _isRefreshing = false;
      });
    } catch (e) {
      setState(() => _isRefreshing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Health check failed: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final connectivityAsync = ref.watch(connectivityProvider);
    final syncStatus = ref.watch(syncStatusProvider);

    return Scaffold(
      backgroundColor: AppTheme.neutral50,
      appBar: AppBar(
        title: const Text(
          'System Status',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppTheme.neutral900,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _isRefreshing ? null : _performHealthCheck,
            icon: _isRefreshing 
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                    ),
                  )
                : const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _performHealthCheck,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Overall Status
              _buildOverallStatus(),
              
              const SizedBox(height: 24),
              
              // Connectivity Status
              _buildConnectivityStatus(connectivityAsync),
              
              const SizedBox(height: 24),
              
              // Sync Status
              _buildSyncStatus(syncStatus),
              
              const SizedBox(height: 24),
              
              // Local Storage Status
              _buildLocalStorageStatus(),
              
              const SizedBox(height: 24),
              
              // Error Statistics
              _buildErrorStatistics(),
              
              const SizedBox(height: 24),
              
              // App Information
              _buildAppInformation(),
              
              const SizedBox(height: 24),
              
              // Actions
              _buildActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverallStatus() {
    final isHealthy = _healthCheckData?['overall']?['status'] == 'healthy';
    
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isHealthy ? Icons.check_circle : Icons.error,
                color: isHealthy ? AppTheme.success : AppTheme.error,
                size: 32,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isHealthy ? 'System Healthy' : 'System Issues Detected',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: isHealthy ? AppTheme.success : AppTheme.error,
                      ),
                    ),
                    Text(
                      isHealthy 
                          ? 'All systems are running normally'
                          : 'Some components may need attention',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.neutral600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_healthCheckData?['overall']?['timestamp'] != null) ...[
            const SizedBox(height: 12),
            Text(
              'Last checked: ${_formatTimestamp(_healthCheckData!['overall']['timestamp'])}',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.neutral500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildConnectivityStatus(AsyncValue<ConnectivityState> connectivityAsync) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.wifi,
                color: AppTheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Connectivity',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.neutral900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          connectivityAsync.when(
            data: (connectivity) => Column(
              children: [
                _buildStatusRow(
                  'Status',
                  connectivity.isOnline ? 'Online' : 'Offline',
                  connectivity.isOnline ? AppTheme.success : AppTheme.warning,
                ),
                _buildStatusRow(
                  'Connection Type',
                  connectivity.connections.isNotEmpty 
                      ? connectivity.connections.map((c) => c.name).join(', ')
                      : 'None',
                  AppTheme.neutral600,
                ),
                _buildStatusRow(
                  'Last Updated',
                  _formatTimestamp(connectivity.lastUpdated.toIso8601String()),
                  AppTheme.neutral600,
                ),
              ],
            ),
            loading: () => const CircularProgressIndicator(),
            error: (error, _) => Text(
              'Error: $error',
              style: TextStyle(color: AppTheme.error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncStatus(SyncStatus syncStatus) {
    Color statusColor;
    String statusText;
    
    switch (syncStatus.state) {
      case SyncStatusState.idle:
        statusColor = AppTheme.neutral600;
        statusText = 'Idle';
        break;
      case SyncStatusState.syncing:
        statusColor = AppTheme.primary;
        statusText = 'Syncing';
        break;
      case SyncStatusState.success:
        statusColor = AppTheme.success;
        statusText = 'Success';
        break;
      case SyncStatusState.error:
        statusColor = AppTheme.error;
        statusText = 'Error';
        break;
      case SyncStatusState.partial:
        statusColor = AppTheme.warning;
        statusText = 'Partial';
        break;
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.sync,
                color: AppTheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Synchronization',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.neutral900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildStatusRow('Status', statusText, statusColor),
          if (syncStatus.message != null)
            _buildStatusRow('Message', syncStatus.message!, AppTheme.neutral600),
          if (syncStatus.totalItems > 0) ...[
            _buildStatusRow(
              'Progress', 
              '${syncStatus.syncedItems}/${syncStatus.totalItems}',
              AppTheme.neutral600,
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: syncStatus.progress,
              backgroundColor: AppTheme.neutral200,
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
          ],
          if (syncStatus.lastSyncTime != null)
            _buildStatusRow(
              'Last Sync',
              _formatTimestamp(syncStatus.lastSyncTime!.toIso8601String()),
              AppTheme.neutral600,
            ),
          if (syncStatus.hasErrors) ...[
            const SizedBox(height: 8),
            Text(
              'Errors: ${syncStatus.errors.length}',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLocalStorageStatus() {
    final dataCounts = LocalStorageService.getDataCounts();
    final hasData = LocalStorageService.hasLocalData();
    
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.storage,
                color: AppTheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Local Storage',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.neutral900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildStatusRow(
            'Status',
            hasData ? 'Available' : 'Empty',
            hasData ? AppTheme.success : AppTheme.neutral600,
          ),
          ...dataCounts.entries.map((entry) {
            return _buildStatusRow(
              entry.key.substring(0, 1).toUpperCase() + entry.key.substring(1),
              entry.value.toString(),
              AppTheme.neutral600,
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildErrorStatistics() {
    final errorStats = ErrorHandlingService().getErrorStatistics();
    
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.bug_report,
                color: AppTheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Error Statistics',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.neutral900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildStatusRow(
            'Total Errors',
            errorStats['totalErrors'].toString(),
            AppTheme.neutral600,
          ),
          _buildStatusRow(
            'Last 24h',
            errorStats['errorsLast24h'].toString(),
            AppTheme.neutral600,
          ),
          _buildStatusRow(
            'Error Rate',
            '${errorStats['errorRate24h'].toStringAsFixed(2)}/hour',
            AppTheme.neutral600,
          ),
        ],
      ),
    );
  }

  Widget _buildAppInformation() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info,
                color: AppTheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'App Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.neutral900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildStatusRow('Version', '1.0.0', AppTheme.neutral600),
          _buildStatusRow('Environment', 'Production', AppTheme.neutral600),
          _buildStatusRow('Build', 'Release', AppTheme.neutral600),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: () async {
            try {
              final offlineSyncService = ref.read(offlineSyncServiceProvider);
              await offlineSyncService.syncPendingItems();
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Sync triggered successfully'),
                    backgroundColor: AppTheme.success,
                  ),
                );
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Sync failed: $e'),
                    backgroundColor: AppTheme.error,
                  ),
                );
              }
            }
          },
          icon: const Icon(Icons.sync),
          label: const Text('Force Sync'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () {
            final errorLog = ErrorHandlingService().exportErrorLog();
            // You could implement sharing the error log here
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Error Log'),
                content: SingleChildScrollView(
                  child: Text(
                    errorLog,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
            );
          },
          icon: const Icon(Icons.download),
          label: const Text('Export Error Log'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.neutral600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(String timestamp) {
    try {
      final date = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else {
        return '${difference.inDays}d ago';
      }
    } catch (e) {
      return 'Unknown';
    }
  }
}