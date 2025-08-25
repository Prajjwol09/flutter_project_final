import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../theme/app_theme.dart';
import '../utils/design_tokens.dart';
import 'buttons.dart';
import 'inputs.dart';

/// 🎆 2025 MODERN DIALOG & MODAL COMPONENTS
/// Enhanced with glassmorphism, backdrop blur, and premium animations

// ==============================================================================
// CORE MODAL COMPONENT
// ==============================================================================

class ModernModal extends StatefulWidget {
  final Widget child;
  final bool barrierDismissible;
  final Color? barrierColor;
  final String? barrierLabel;
  final bool useRootNavigator;
  final RouteSettings? routeSettings;
  final Offset? anchorPoint;
  final bool enableDrag;
  final bool isScrollControlled;
  final double? heightFactor;
  final EdgeInsets? padding;
  final BorderRadius? borderRadius;
  final bool showDragHandle;

  const ModernModal({
    super.key,
    required this.child,
    this.barrierDismissible = true,
    this.barrierColor,
    this.barrierLabel,
    this.useRootNavigator = false,
    this.routeSettings,
    this.anchorPoint,
    this.enableDrag = true,
    this.isScrollControlled = false,
    this.heightFactor,
    this.padding,
    this.borderRadius,
    this.showDragHandle = true,
  });

  @override
  State<ModernModal> createState() => _ModernModalState();

  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    bool barrierDismissible = true,
    Color? barrierColor,
    String? barrierLabel,
    bool useRootNavigator = false,
    RouteSettings? routeSettings,
    Offset? anchorPoint,
    bool enableDrag = true,
    bool isScrollControlled = false,
    double? heightFactor,
    EdgeInsets? padding,
    BorderRadius? borderRadius,
    bool showDragHandle = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      builder: (context) => ModernModal(
        barrierDismissible: barrierDismissible,
        barrierColor: barrierColor,
        barrierLabel: barrierLabel,
        useRootNavigator: useRootNavigator,
        routeSettings: routeSettings,
        anchorPoint: anchorPoint,
        enableDrag: enableDrag,
        isScrollControlled: isScrollControlled,
        heightFactor: heightFactor,
        padding: padding,
        borderRadius: borderRadius,
        showDragHandle: showDragHandle,
        child: child,
      ),
      barrierColor: barrierColor ?? Colors.black.withValues(alpha: 0.5),
      isDismissible: barrierDismissible,
      enableDrag: enableDrag,
      isScrollControlled: isScrollControlled,
      backgroundColor: Colors.transparent,
      elevation: 0,
    );
  }
}

class _ModernModalState extends State<ModernModal>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _blurController;
  
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _blurAnimation;
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
    
    _blurController = AnimationController(
      duration: DesignTokens.durationMedium,
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
    
    _blurAnimation = Tween<double>(
      begin: 0.0,
      end: 10.0,
    ).animate(CurvedAnimation(
      parent: _blurController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: DesignTokens.curveEaseOut,
    ));
  }

  void _startAnimations() async {
    _blurController.forward();
    await Future.delayed(Duration(milliseconds: 100));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _blurController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final height = widget.heightFactor != null 
        ? mediaQuery.size.height * widget.heightFactor!
        : null;

    return AnimatedBuilder(
      animation: Listenable.merge([_animationController, _blurController]),
      builder: (context, child) {
        return BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: _blurAnimation.value,
            sigmaY: _blurAnimation.value,
          ),
          child: Container(
            height: height,
            padding: widget.padding ?? EdgeInsets.all(DesignTokens.space4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: 0.1),
                  Colors.white.withValues(alpha: 0.15),
                  Colors.white.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: widget.borderRadius ?? BorderRadius.vertical(
                top: Radius.circular(DesignTokens.radiusXl),
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.showDragHandle) _buildDragHandle(),
                      Flexible(child: widget.child),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDragHandle() {
    return Container(
      margin: EdgeInsets.only(bottom: DesignTokens.space4),
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
        ),
      ),
    );
  }
}

// ==============================================================================
// MODERN DIALOG COMPONENT
// ==============================================================================

class ModernDialog extends StatefulWidget {
  final String? title;
  final Widget? titleWidget;
  final String? content;
  final Widget? contentWidget;
  final List<Widget>? actions;
  final EdgeInsets? contentPadding;
  final EdgeInsets? actionsPadding;
  final MainAxisAlignment? actionsAlignment;
  final VerticalDirection? actionsOverflowDirection;
  final double? actionsOverflowButtonSpacing;
  final EdgeInsets? buttonPadding;
  final Color? backgroundColor;
  final double? elevation;
  final String? semanticLabel;
  final EdgeInsets? insetPadding;
  final Clip? clipBehavior;
  final ShapeBorder? shape;
  final AlignmentGeometry? alignment;
  final bool scrollable;
  final Widget? icon;
  final Color? iconColor;
  final Color? shadowColor;
  final Color? surfaceTintColor;

  const ModernDialog({
    super.key,
    this.title,
    this.titleWidget,
    this.content,
    this.contentWidget,
    this.actions,
    this.contentPadding,
    this.actionsPadding,
    this.actionsAlignment,
    this.actionsOverflowDirection,
    this.actionsOverflowButtonSpacing,
    this.buttonPadding,
    this.backgroundColor,
    this.elevation,
    this.semanticLabel,
    this.insetPadding,
    this.clipBehavior,
    this.shape,
    this.alignment,
    this.scrollable = false,
    this.icon,
    this.iconColor,
    this.shadowColor,
    this.surfaceTintColor,
  });

  @override
  State<ModernDialog> createState() => _ModernDialogState();

  static Future<T?> show<T>({
    required BuildContext context,
    String? title,
    Widget? titleWidget,
    String? content,
    Widget? contentWidget,
    List<Widget>? actions,
    bool barrierDismissible = true,
    Color? barrierColor,
    String? barrierLabel,
    bool useRootNavigator = true,
    RouteSettings? routeSettings,
    Offset? anchorPoint,
    Widget? icon,
    Color? iconColor,
  }) {
    return showDialog<T>(
      context: context,
      builder: (context) => ModernDialog(
        title: title,
        titleWidget: titleWidget,
        content: content,
        contentWidget: contentWidget,
        actions: actions,
        icon: icon,
        iconColor: iconColor,
      ),
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor ?? Colors.black.withValues(alpha: 0.6),
      barrierLabel: barrierLabel,
      useRootNavigator: useRootNavigator,
      routeSettings: routeSettings,
      anchorPoint: anchorPoint,
    );
  }
}

class _ModernDialogState extends State<ModernDialog>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _blurController;
  
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _blurAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
    
    // Add haptic feedback
    HapticFeedback.lightImpact();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: DesignTokens.durationMedium,
      vsync: this,
    );
    
    _blurController = AnimationController(
      duration: DesignTokens.durationMedium,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: DesignTokens.curveEaseOut,
    ));
    
    _blurAnimation = Tween<double>(
      begin: 0.0,
      end: 15.0,
    ).animate(CurvedAnimation(
      parent: _blurController,
      curve: Curves.easeInOut,
    ));
  }

  void _startAnimations() async {
    _blurController.forward();
    await Future.delayed(Duration(milliseconds: 100));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _blurController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AnimatedBuilder(
      animation: Listenable.merge([_animationController, _blurController]),
      builder: (context, child) {
        return BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: _blurAnimation.value,
            sigmaY: _blurAnimation.value,
          ),
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Dialog(
                backgroundColor: Colors.transparent,
                elevation: 0,
                insetPadding: widget.insetPadding ?? EdgeInsets.all(DesignTokens.space6),
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: 400,
                    minWidth: 280,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.15),
                        Colors.white.withValues(alpha: 0.1),
                        Colors.white.withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 40,
                        spreadRadius: 0,
                        offset: Offset(0, 20),
                      ),
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        blurRadius: 60,
                        spreadRadius: 10,
                        offset: Offset(0, 30),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.icon != null || widget.title != null || widget.titleWidget != null)
                        _buildHeader(theme),
                      if (widget.content != null || widget.contentWidget != null)
                        _buildContent(theme),
                      if (widget.actions != null && widget.actions!.isNotEmpty)
                        _buildActions(theme),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        DesignTokens.space6,
        DesignTokens.space6,
        DesignTokens.space6,
        widget.content != null || widget.contentWidget != null 
            ? DesignTokens.space3 
            : DesignTokens.space6,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.icon != null) ...[
            Container(
              padding: EdgeInsets.all(DesignTokens.space3),
              decoration: BoxDecoration(
                gradient: DesignTokens.gradientPrimary,
                borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.3),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: IconTheme(
                data: IconThemeData(
                  color: widget.iconColor ?? Colors.white,
                  size: 24,
                ),
                child: widget.icon!,
              ),
            ),
            SizedBox(height: DesignTokens.space4),
          ],
          if (widget.titleWidget != null)
            widget.titleWidget!
          else if (widget.title != null)
            Text(
              widget.title!,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: DesignTokens.fontWeightBold,
                color: Colors.white,
                fontSize: 20,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: widget.contentPadding ?? EdgeInsets.fromLTRB(
        DesignTokens.space6,
        0,
        DesignTokens.space6,
        DesignTokens.space4,
      ),
      child: widget.contentWidget ?? Text(
        widget.content!,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: Colors.white.withValues(alpha: 0.9),
          fontSize: 16,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildActions(ThemeData theme) {
    return Container(
      padding: widget.actionsPadding ?? EdgeInsets.fromLTRB(
        DesignTokens.space6,
        DesignTokens.space4,
        DesignTokens.space6,
        DesignTokens.space6,
      ),
      child: Row(
        mainAxisAlignment: widget.actionsAlignment ?? MainAxisAlignment.end,
        children: widget.actions!.map((action) {
          final isFirst = widget.actions!.first == action;
          return Padding(
            padding: EdgeInsets.only(
              left: isFirst ? 0 : DesignTokens.space2,
            ),
            child: action,
          );
        }).toList(),
      ),
    );
  }
}

// ==============================================================================
// SPECIALIZED DIALOG TYPES
// ==============================================================================

class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String content;
  final String confirmText;
  final String cancelText;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final bool isDestructive;
  final Widget? icon;

  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.content,
    this.confirmText = 'Confirm',
    this.cancelText = 'Cancel',
    this.onConfirm,
    this.onCancel,
    this.isDestructive = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return ModernDialog(
      icon: icon ?? Icon(
        isDestructive ? Icons.warning_rounded : Icons.help_rounded,
      ),
      iconColor: isDestructive ? AppTheme.error : DesignTokens.accent,
      title: title,
      content: content,
      actions: [
        OutlinedButton(
          onPressed: () {
            Navigator.of(context).pop(false);
            onCancel?.call();
          },
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
            foregroundColor: Colors.white.withValues(alpha: 0.8),
          ),
          child: Text(cancelText),
        ),
        PrimaryButton(
          text: confirmText,
          onPressed: () {
            Navigator.of(context).pop(true);
            onConfirm?.call();
          },
          variant: isDestructive ? ButtonVariant.outlined : ButtonVariant.primary,
        ),
      ],
    );
  }

  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String content,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    bool isDestructive = false,
    Widget? icon,
  }) {
    return ModernDialog.show<bool>(
      context: context,
      titleWidget: ConfirmationDialog(
        title: title,
        content: content,
        confirmText: confirmText,
        cancelText: cancelText,
        onConfirm: onConfirm,
        onCancel: onCancel,
        isDestructive: isDestructive,
        icon: icon,
      ),
    );
  }
}

class InputDialog extends StatefulWidget {
  final String title;
  final String? hint;
  final String? initialValue;
  final String confirmText;
  final String cancelText;
  final Function(String)? onConfirm;
  final VoidCallback? onCancel;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final bool obscureText;
  final Widget? icon;

  const InputDialog({
    super.key,
    required this.title,
    this.hint,
    this.initialValue,
    this.confirmText = 'Confirm',
    this.cancelText = 'Cancel',
    this.onConfirm,
    this.onCancel,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.icon,
  });

  @override
  State<InputDialog> createState() => _InputDialogState();

  static Future<String?> show({
    required BuildContext context,
    required String title,
    String? hint,
    String? initialValue,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    Function(String)? onConfirm,
    VoidCallback? onCancel,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? icon,
  }) {
    return ModernDialog.show<String>(
      context: context,
      titleWidget: InputDialog(
        title: title,
        hint: hint,
        initialValue: initialValue,
        confirmText: confirmText,
        cancelText: cancelText,
        onConfirm: onConfirm,
        onCancel: onCancel,
        validator: validator,
        keyboardType: keyboardType,
        obscureText: obscureText,
        icon: icon,
      ),
    );
  }
}

class _InputDialogState extends State<InputDialog> {
  late TextEditingController _controller;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ModernDialog(
      icon: widget.icon ?? Icon(Icons.edit_rounded),
      iconColor: AppTheme.primary,
      title: widget.title,
      contentWidget: Form(
        key: _formKey,
        child: AppTextField(
          controller: _controller,
          hint: widget.hint,
          validator: widget.validator,
          keyboardType: widget.keyboardType,
          obscureText: widget.obscureText,
          autofocus: true,
        ),
      ),
      actions: [
        OutlinedButton(
          onPressed: () {
            Navigator.of(context).pop();
            widget.onCancel?.call();
          },
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
            foregroundColor: Colors.white.withValues(alpha: 0.8),
          ),
          child: Text(widget.cancelText),
        ),
        PrimaryButton(
          text: widget.confirmText,
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              final value = _controller.text;
              Navigator.of(context).pop(value);
              widget.onConfirm?.call(value);
            }
          },
        ),
      ],
    );
  }
}

class LoadingDialog extends StatelessWidget {
  final String? message;
  final Widget? content;

  const LoadingDialog({
    super.key,
    this.message,
    this.content,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return ModernDialog(
      contentWidget: Container(
        padding: EdgeInsets.all(DesignTokens.space6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: DesignTokens.gradientPrimary,
                borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
              ),
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            ),
            if (message != null || content != null) ...[
              SizedBox(height: DesignTokens.space4),
              content ?? Text(
                message!,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  static Future<T?> show<T>({
    required BuildContext context,
    String? message,
    Widget? content,
  }) {
    return ModernDialog.show<T>(
      context: context,
      contentWidget: LoadingDialog(
        message: message,
        content: content,
      ),
    );
  }
}

// ==============================================================================
// UTILITY FUNCTIONS
// ==============================================================================

class ModernDialogs {
  static Future<bool?> showConfirmation({
    required BuildContext context,
    required String title,
    required String content,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    bool isDestructive = false,
    Widget? icon,
  }) {
    return ConfirmationDialog.show(
      context: context,
      title: title,
      content: content,
      confirmText: confirmText,
      cancelText: cancelText,
      isDestructive: isDestructive,
      icon: icon,
    );
  }

  static Future<String?> showInput({
    required BuildContext context,
    required String title,
    String? hint,
    String? initialValue,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? icon,
  }) {
    return InputDialog.show(
      context: context,
      title: title,
      hint: hint,
      initialValue: initialValue,
      confirmText: confirmText,
      cancelText: cancelText,
      validator: validator,
      keyboardType: keyboardType,
      obscureText: obscureText,
      icon: icon,
    );
  }

  static Future<T?> showLoading<T>({
    required BuildContext context,
    String? message,
    Widget? content,
  }) {
    return LoadingDialog.show<T>(
      context: context,
      message: message,
      content: content,
    );
  }

  static void showSuccess({
    required BuildContext context,
    required String title,
    String? content,
    VoidCallback? onConfirm,
  }) {
    ModernDialog.show(
      context: context,
      icon: Icon(Icons.check_circle_rounded),
      iconColor: AppTheme.success,
      title: title,
      content: content,
      actions: [
        PrimaryButton(
          text: 'OK',
          onPressed: () {
            Navigator.of(context).pop();
            onConfirm?.call();
          },
        ),
      ],
    );
  }

  static void showError({
    required BuildContext context,
    required String title,
    String? content,
    VoidCallback? onConfirm,
  }) {
    ModernDialog.show(
      context: context,
      icon: Icon(Icons.error_rounded),
      iconColor: AppTheme.error,
      title: title,
      content: content,
      actions: [
        PrimaryButton(
          text: 'OK',
          onPressed: () {
            Navigator.of(context).pop();
            onConfirm?.call();
          },
          variant: ButtonVariant.outlined,
        ),
      ],
    );
  }

  static void showInfo({
    required BuildContext context,
    required String title,
    String? content,
    VoidCallback? onConfirm,
  }) {
    ModernDialog.show(
      context: context,
      icon: Icon(Icons.info_rounded),
      iconColor: DesignTokens.accent,
      title: title,
      content: content,
      actions: [
        PrimaryButton(
          text: 'OK',
          onPressed: () {
            Navigator.of(context).pop();
            onConfirm?.call();
          },
        ),
      ],
    );
  }
}