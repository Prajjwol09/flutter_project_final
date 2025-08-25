import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../theme/app_theme.dart';
import '../utils/design_tokens.dart';

/// 🎆 2025 MODERN SNACKBAR & NOTIFICATION COMPONENTS
/// Enhanced with glassmorphism, animations, and premium user feedback

// ==============================================================================
// MODERN SNACKBAR COMPONENT
// ==============================================================================

class ModernSnackBar extends StatefulWidget {
  final String message;
  final Widget? content;
  final SnackBarType type;
  final Duration duration;
  final VoidCallback? onAction;
  final String? actionLabel;
  final Widget? leading;
  final Widget? trailing;
  final bool showCloseButton;
  final EdgeInsets? margin;
  final BorderRadius? borderRadius;
  final double? elevation;

  const ModernSnackBar({
    super.key,
    required this.message,
    this.content,
    this.type = SnackBarType.info,
    this.duration = const Duration(seconds: 4),
    this.onAction,
    this.actionLabel,
    this.leading,
    this.trailing,
    this.showCloseButton = true,
    this.margin,
    this.borderRadius,
    this.elevation,
  });

  @override
  State<ModernSnackBar> createState() => _ModernSnackBarState();

  static void show({
    required BuildContext context,
    required String message,
    Widget? content,
    SnackBarType type = SnackBarType.info,
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onAction,
    String? actionLabel,
    Widget? leading,
    Widget? trailing,
    bool showCloseButton = true,
    EdgeInsets? margin,
    BorderRadius? borderRadius,
    double? elevation,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: ModernSnackBar(
          message: message,
          content: content,
          type: type,
          duration: duration,
          onAction: onAction,
          actionLabel: actionLabel,
          leading: leading,
          trailing: trailing,
          showCloseButton: showCloseButton,
          margin: margin,
          borderRadius: borderRadius,
          elevation: elevation,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        margin: margin ?? EdgeInsets.all(DesignTokens.space4),
        shape: borderRadius != null 
            ? RoundedRectangleBorder(borderRadius: borderRadius)
            : RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
              ),
        duration: duration,
      ),
    );
  }
}

enum SnackBarType {
  success,
  error,
  warning,
  info,
  neutral,
}

class _ModernSnackBarState extends State<ModernSnackBar>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _progressController;
  
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
    
    // Add haptic feedback based on type
    _triggerHapticFeedback();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: DesignTokens.durationMedium,
      vsync: this,
    );
    
    _progressController = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.9,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: DesignTokens.curveEaseOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: DesignTokens.curveEaseOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: DesignTokens.curveEaseOut,
    ));

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.linear,
    ));
  }

  void _startAnimations() async {
    _animationController.forward();
    await Future.delayed(Duration(milliseconds: 200));
    _progressController.forward();
  }

  void _triggerHapticFeedback() {
    switch (widget.type) {
      case SnackBarType.success:
        HapticFeedback.lightImpact();
        break;
      case SnackBarType.error:
        HapticFeedback.heavyImpact();
        break;
      case SnackBarType.warning:
        HapticFeedback.mediumImpact();
        break;
      case SnackBarType.info:
      case SnackBarType.neutral:
        HapticFeedback.selectionClick();
        break;
    }
  }

  Color get _typeColor {
    switch (widget.type) {
      case SnackBarType.success:
        return AppTheme.success;
      case SnackBarType.error:
        return AppTheme.error;
      case SnackBarType.warning:
        return AppTheme.warning;
      case SnackBarType.info:
        return DesignTokens.accent;
      case SnackBarType.neutral:
        return AppTheme.neutral400;
    }
  }

  IconData get _typeIcon {
    switch (widget.type) {
      case SnackBarType.success:
        return Icons.check_circle_rounded;
      case SnackBarType.error:
        return Icons.error_rounded;
      case SnackBarType.warning:
        return Icons.warning_rounded;
      case SnackBarType.info:
        return Icons.info_rounded;
      case SnackBarType.neutral:
        return Icons.notifications_rounded;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: Listenable.merge([_animationController, _progressController]),
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: ClipRRect(
                borderRadius: widget.borderRadius ?? 
                    BorderRadius.circular(DesignTokens.radiusMd),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _typeColor.withValues(alpha: 0.2),
                          _typeColor.withValues(alpha: 0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: widget.borderRadius ?? 
                          BorderRadius.circular(DesignTokens.radiusMd),
                      border: Border.all(
                        color: _typeColor.withValues(alpha: 0.3),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _typeColor.withValues(alpha: 0.2),
                          blurRadius: 20,
                          spreadRadius: 2,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: EdgeInsets.all(DesignTokens.space4),
                          child: Row(
                            children: [
                              // Leading icon or custom widget
                              widget.leading ?? Container(
                                padding: EdgeInsets.all(DesignTokens.space2),
                                decoration: BoxDecoration(
                                  color: _typeColor.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                                ),
                                child: Icon(
                                  _typeIcon,
                                  color: _typeColor,
                                  size: 20,
                                ),
                              ),
                              
                              SizedBox(width: DesignTokens.space3),
                              
                              // Content
                              Expanded(
                                child: widget.content ?? Text(
                                  widget.message,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: DesignTokens.fontWeightMedium,
                                  ),
                                ),
                              ),
                              
                              // Action button
                              if (widget.onAction != null && widget.actionLabel != null) ...[
                                SizedBox(width: DesignTokens.space2),
                                TextButton(
                                  onPressed: widget.onAction,
                                  style: TextButton.styleFrom(
                                    foregroundColor: _typeColor,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: DesignTokens.space3,
                                      vertical: DesignTokens.space2,
                                    ),
                                  ),
                                  child: Text(
                                    widget.actionLabel!,
                                    style: TextStyle(
                                      fontWeight: DesignTokens.fontWeightSemiBold,
                                    ),
                                  ),
                                ),
                              ],
                              
                              // Trailing widget or close button
                              if (widget.trailing != null)
                                widget.trailing!
                              else if (widget.showCloseButton) ...[
                                SizedBox(width: DesignTokens.space2),
                                IconButton(
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                  },
                                  icon: Icon(
                                    Icons.close_rounded,
                                    color: Colors.white.withValues(alpha: 0.7),
                                    size: 20,
                                  ),
                                  style: IconButton.styleFrom(
                                    padding: EdgeInsets.all(DesignTokens.space1),
                                    minimumSize: Size(32, 32),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        
                        // Progress indicator
                        Container(
                          height: 3,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.vertical(
                              bottom: Radius.circular(DesignTokens.radiusMd),
                            ),
                          ),
                          child: LinearProgressIndicator(
                            value: _progressAnimation.value,
                            backgroundColor: Colors.transparent,
                            valueColor: AlwaysStoppedAnimation<Color>(_typeColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ==============================================================================
// TOAST NOTIFICATION COMPONENT
// ==============================================================================

class ModernToast {
  static OverlayEntry? _currentToast;

  static void show({
    required BuildContext context,
    required String message,
    SnackBarType type = SnackBarType.info,
    Duration duration = const Duration(seconds: 3),
    ToastPosition position = ToastPosition.top,
    EdgeInsets? margin,
  }) {
    // Remove existing toast
    hide();

    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => _ToastWidget(
        message: message,
        type: type,
        duration: duration,
        position: position,
        margin: margin,
        onDismiss: () {
          overlayEntry.remove();
          _currentToast = null;
        },
      ),
    );

    _currentToast = overlayEntry;
    overlay.insert(overlayEntry);

    // Auto-hide after duration
    Future.delayed(duration, () {
      if (_currentToast == overlayEntry) {
        hide();
      }
    });
  }

  static void hide() {
    _currentToast?.remove();
    _currentToast = null;
  }

  static void showSuccess({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 3),
    ToastPosition position = ToastPosition.top,
  }) {
    show(
      context: context,
      message: message,
      type: SnackBarType.success,
      duration: duration,
      position: position,
    );
  }

  static void showError({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 4),
    ToastPosition position = ToastPosition.top,
  }) {
    show(
      context: context,
      message: message,
      type: SnackBarType.error,
      duration: duration,
      position: position,
    );
  }

  static void showWarning({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 3),
    ToastPosition position = ToastPosition.top,
  }) {
    show(
      context: context,
      message: message,
      type: SnackBarType.warning,
      duration: duration,
      position: position,
    );
  }

  static void showInfo({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 3),
    ToastPosition position = ToastPosition.top,
  }) {
    show(
      context: context,
      message: message,
      type: SnackBarType.info,
      duration: duration,
      position: position,
    );
  }
}

enum ToastPosition {
  top,
  center,
  bottom,
}

class _ToastWidget extends StatefulWidget {
  final String message;
  final SnackBarType type;
  final Duration duration;
  final ToastPosition position;
  final EdgeInsets? margin;
  final VoidCallback onDismiss;

  const _ToastWidget({
    required this.message,
    required this.type,
    required this.duration,
    required this.position,
    this.margin,
    required this.onDismiss,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: DesignTokens.durationMedium,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: DesignTokens.curveEaseOut,
    ));

    final slideBegin = switch (widget.position) {
      ToastPosition.top => const Offset(0, -1),
      ToastPosition.center => const Offset(0, 0),
      ToastPosition.bottom => const Offset(0, 1),
    };

    _slideAnimation = Tween<Offset>(
      begin: slideBegin,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: DesignTokens.curveEaseOut,
    ));
  }

  void _startAnimations() {
    _animationController.forward();
  }

  Color get _typeColor {
    switch (widget.type) {
      case SnackBarType.success:
        return AppTheme.success;
      case SnackBarType.error:
        return AppTheme.error;
      case SnackBarType.warning:
        return AppTheme.warning;
      case SnackBarType.info:
        return DesignTokens.accent;
      case SnackBarType.neutral:
        return AppTheme.neutral400;
    }
  }

  IconData get _typeIcon {
    switch (widget.type) {
      case SnackBarType.success:
        return Icons.check_circle_rounded;
      case SnackBarType.error:
        return Icons.error_rounded;
      case SnackBarType.warning:
        return Icons.warning_rounded;
      case SnackBarType.info:
        return Icons.info_rounded;
      case SnackBarType.neutral:
        return Icons.notifications_rounded;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);

    return Positioned(
      top: widget.position == ToastPosition.top 
          ? mediaQuery.padding.top + DesignTokens.space4
          : null,
      bottom: widget.position == ToastPosition.bottom 
          ? mediaQuery.padding.bottom + DesignTokens.space4
          : null,
      left: DesignTokens.space4,
      right: DesignTokens.space4,
      child: widget.position == ToastPosition.center
          ? Center(
              child: _buildToastContent(theme),
            )
          : _buildToastContent(theme),
    );
  }

  Widget _buildToastContent(ThemeData theme) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Material(
              color: Colors.transparent,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    constraints: BoxConstraints(maxWidth: 400),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _typeColor.withValues(alpha: 0.2),
                          _typeColor.withValues(alpha: 0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                      border: Border.all(
                        color: _typeColor.withValues(alpha: 0.3),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _typeColor.withValues(alpha: 0.2),
                          blurRadius: 20,
                          spreadRadius: 2,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    padding: EdgeInsets.all(DesignTokens.space4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: EdgeInsets.all(DesignTokens.space2),
                          decoration: BoxDecoration(
                            color: _typeColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                          ),
                          child: Icon(
                            _typeIcon,
                            color: _typeColor,
                            size: 20,
                          ),
                        ),
                        SizedBox(width: DesignTokens.space3),
                        Flexible(
                          child: Text(
                            widget.message,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: DesignTokens.fontWeightMedium,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ==============================================================================
// UTILITY CLASS
// ==============================================================================

class ModernNotifications {
  static void showSnackBar({
    required BuildContext context,
    required String message,
    SnackBarType type = SnackBarType.info,
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    ModernSnackBar.show(
      context: context,
      message: message,
      type: type,
      duration: duration,
      onAction: onAction,
      actionLabel: actionLabel,
    );
  }

  static void showToast({
    required BuildContext context,
    required String message,
    SnackBarType type = SnackBarType.info,
    Duration duration = const Duration(seconds: 3),
    ToastPosition position = ToastPosition.top,
  }) {
    ModernToast.show(
      context: context,
      message: message,
      type: type,
      duration: duration,
      position: position,
    );
  }

  static void success({
    required BuildContext context,
    required String message,
    bool useToast = false,
    Duration? duration,
    ToastPosition position = ToastPosition.top,
  }) {
    if (useToast) {
      ModernToast.showSuccess(
        context: context,
        message: message,
        duration: duration ?? const Duration(seconds: 3),
        position: position,
      );
    } else {
      ModernSnackBar.show(
        context: context,
        message: message,
        type: SnackBarType.success,
        duration: duration ?? const Duration(seconds: 4),
      );
    }
  }

  static void error({
    required BuildContext context,
    required String message,
    bool useToast = false,
    Duration? duration,
    ToastPosition position = ToastPosition.top,
  }) {
    if (useToast) {
      ModernToast.showError(
        context: context,
        message: message,
        duration: duration ?? const Duration(seconds: 4),
        position: position,
      );
    } else {
      ModernSnackBar.show(
        context: context,
        message: message,
        type: SnackBarType.error,
        duration: duration ?? const Duration(seconds: 4),
      );
    }
  }

  static void warning({
    required BuildContext context,
    required String message,
    bool useToast = false,
    Duration? duration,
    ToastPosition position = ToastPosition.top,
  }) {
    if (useToast) {
      ModernToast.showWarning(
        context: context,
        message: message,
        duration: duration ?? const Duration(seconds: 3),
        position: position,
      );
    } else {
      ModernSnackBar.show(
        context: context,
        message: message,
        type: SnackBarType.warning,
        duration: duration ?? const Duration(seconds: 4),
      );
    }
  }

  static void info({
    required BuildContext context,
    required String message,
    bool useToast = false,
    Duration? duration,
    ToastPosition position = ToastPosition.top,
  }) {
    if (useToast) {
      ModernToast.showInfo(
        context: context,
        message: message,
        duration: duration ?? const Duration(seconds: 3),
        position: position,
      );
    } else {
      ModernSnackBar.show(
        context: context,
        message: message,
        type: SnackBarType.info,
        duration: duration ?? const Duration(seconds: 4),
      );
    }
  }
}