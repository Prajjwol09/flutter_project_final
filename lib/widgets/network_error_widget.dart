import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/connectivity_service.dart';
import '../theme/app_theme.dart';
import '../utils/design_tokens.dart';

class NetworkErrorWidget extends ConsumerWidget {
  final String? message;
  final VoidCallback? onRetry;
  final bool showRetryButton;
  final bool isFullScreen;

  const NetworkErrorWidget({
    super.key,
    this.message,
    this.onRetry,
    this.showRetryButton = true,
    this.isFullScreen = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivityAsync = ref.watch(connectivityProvider);

    return connectivityAsync.when(
      data: (connectivity) {
        if (connectivity.isOnline) {
          // If online, don't show network error
          return const SizedBox.shrink();
        }

        return _buildOfflineWidget(context, connectivity);
      },
      loading: () => _buildLoadingWidget(),
      error: (error, stack) => _buildErrorWidget(context, error.toString()),
    );
  }

  Widget _buildOfflineWidget(BuildContext context, ConnectivityState connectivity) {
    if (isFullScreen) {
      return Scaffold(
        backgroundColor: AppTheme.neutral50,
        body: _buildOfflineContent(context, connectivity),
      );
    }

    return Container(
      padding: EdgeInsets.all(DesignTokens.space4),
      margin: EdgeInsets.all(DesignTokens.space4),
      decoration: BoxDecoration(
        color: AppTheme.warning.withOpacity(0.1),
        border: Border.all(
          color: AppTheme.warning.withOpacity(0.3),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
      ),
      child: _buildOfflineContent(context, connectivity),
    );
  }

  Widget _buildOfflineContent(BuildContext context, ConnectivityState connectivity) {
    return Column(
      mainAxisAlignment: isFullScreen ? MainAxisAlignment.center : MainAxisAlignment.start,
      children: [
        Icon(
          Icons.wifi_off,
          size: isFullScreen ? 64 : 32,
          color: AppTheme.warning,
        ),
        SizedBox(height: DesignTokens.space3),
        Text(
          isFullScreen ? 'No Internet Connection' : 'Offline',
          style: TextStyle(
            fontSize: isFullScreen ? 24 : 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.neutral900,
          ),
        ),
        SizedBox(height: DesignTokens.space2),
        Text(
          message ?? 
          (isFullScreen 
            ? 'You\'re currently offline. Some features may not be available until you reconnect to the internet.'
            : 'Working offline with local data'),
          style: TextStyle(
            fontSize: isFullScreen ? 16 : 14,
            color: AppTheme.neutral600,
          ),
          textAlign: TextAlign.center,
        ),
        if (isFullScreen) ...[
          SizedBox(height: DesignTokens.space4),
          _buildConnectionDetails(connectivity),
        ],
        if (showRetryButton && onRetry != null) ...[
          SizedBox(height: DesignTokens.space4),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildConnectionDetails(ConnectivityState connectivity) {
    return Container(
      padding: EdgeInsets.all(DesignTokens.space3),
      decoration: BoxDecoration(
        color: AppTheme.neutral100,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Connection Status',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.neutral900,
            ),
          ),
          SizedBox(height: DesignTokens.space2),
          _buildStatusRow('Status', connectivity.status.name.toUpperCase()),
          _buildStatusRow('Last Updated', _formatTime(connectivity.lastUpdated)),
          if (connectivity.connections.isNotEmpty)
            _buildStatusRow(
              'Connection Types', 
              connectivity.connections.map((c) => c.name).join(', ')
            ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: DesignTokens.space1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.neutral600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppTheme.neutral800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Container(
      padding: EdgeInsets.all(DesignTokens.space4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
            ),
          ),
          SizedBox(height: DesignTokens.space2),
          Text(
            'Checking connection...',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.neutral600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context, String error) {
    return Container(
      padding: EdgeInsets.all(DesignTokens.space4),
      decoration: BoxDecoration(
        color: AppTheme.error.withOpacity(0.1),
        border: Border.all(
          color: AppTheme.error.withOpacity(0.3),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            size: 24,
            color: AppTheme.error,
          ),
          SizedBox(height: DesignTokens.space2),
          Text(
            'Connection Error',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.error,
            ),
          ),
          SizedBox(height: DesignTokens.space1),
          Text(
            'Unable to check connection status',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.neutral600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}

/// Banner widget to show at the top of screens when offline
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivityAsync = ref.watch(connectivityProvider);

    return connectivityAsync.when(
      data: (connectivity) {
        if (connectivity.isOnline) {
          return const SizedBox.shrink();
        }

        return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: DesignTokens.space4,
            vertical: DesignTokens.space2,
          ),
          decoration: BoxDecoration(
            color: AppTheme.warning,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                Icons.wifi_off,
                size: 16,
                color: Colors.white,
              ),
              SizedBox(width: DesignTokens.space2),
              Expanded(
                child: Text(
                  'You\'re offline. Changes will sync when connection is restored.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

/// Sync status indicator widget
class SyncStatusIndicator extends ConsumerWidget {
  const SyncStatusIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivityAsync = ref.watch(connectivityProvider);
    
    return connectivityAsync.when(
      data: (connectivity) {
        final icon = connectivity.isOnline 
            ? Icons.cloud_done
            : Icons.cloud_off;
        final color = connectivity.isOnline 
            ? AppTheme.success
            : AppTheme.warning;
        final tooltip = connectivity.isOnline 
            ? 'Online - Data synced'
            : 'Offline - Working with local data';

        return Tooltip(
          message: tooltip,
          child: Icon(
            icon,
            size: 16,
            color: color,
          ),
        );
      },
      loading: () => SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
          strokeWidth: 1.5,
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.neutral400),
        ),
      ),
      error: (_, __) => Icon(
        Icons.error_outline,
        size: 16,
        color: AppTheme.error,
      ),
    );
  }
}