import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/design_tokens.dart';

/// 🎯 2025 MODERN BUTTON SYSTEM
/// Enhanced with micro-interactions, accessibility, and premium design

/// Button size enumeration
enum ButtonSize { small, medium, large, extraLarge }

/// Button variant enumeration
enum ButtonVariant { primary, secondary, outlined, ghost, gradient }

/// 🔥 PRIMARY BUTTON - Hero Actions (2025 Edition)
class PrimaryButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final bool isFullWidth;
  final ButtonSize size;
  final ButtonVariant variant;

  const PrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.isFullWidth = true,
    this.size = ButtonSize.large,
    this.variant = ButtonVariant.primary,
  });

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: DesignTokens.durationFast,
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.96,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: DesignTokens.curveEaseOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      _animationController.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      _animationController.reverse();
    }
  }

  void _handleTapCancel() {
    if (widget.onPressed != null && !widget.isLoading) {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEnabled = widget.onPressed != null && !widget.isLoading;
    
    // Size configurations
    final buttonHeight = _getButtonHeight();
    final fontSize = _getFontSize();
    final horizontalPadding = _getHorizontalPadding();
    final iconSize = _getIconSize();
    
    // Color configurations based on variant
    final backgroundColor = _getBackgroundColor(theme);
    final foregroundColor = _getForegroundColor(theme);
    
    Widget child = Row(
      mainAxisSize: widget.isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.isLoading) ...[
          SizedBox(
            width: iconSize,
            height: iconSize,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
            ),
          ),
          SizedBox(width: DesignTokens.space2),
        ] else if (widget.icon != null) ...[
          Icon(
            widget.icon,
            size: iconSize,
            color: foregroundColor,
          ),
          SizedBox(width: DesignTokens.space2),
        ],
        Text(
          widget.text,
          style: theme.textTheme.labelLarge?.copyWith(
            fontSize: fontSize,
            fontWeight: DesignTokens.fontWeightMedium,
            color: foregroundColor,
            height: 1.2,
            letterSpacing: DesignTokens.letterSpacingWide,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );

    Widget button = AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            height: buttonHeight,
            width: widget.isFullWidth ? double.infinity : null,
            decoration: BoxDecoration(
              gradient: widget.variant == ButtonVariant.gradient
                  ? DesignTokens.gradientPrimary
                  : null,
              color: widget.variant != ButtonVariant.gradient
                  ? backgroundColor
                  : null,
              borderRadius: BorderRadius.circular(_getBorderRadius()),
              border: widget.variant == ButtonVariant.outlined
                  ? Border.all(
                      color: theme.colorScheme.outline,
                      width: 1.5,
                    )
                  : null,
              boxShadow: _getShadow(theme),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: isEnabled ? widget.onPressed : null,
                onTapDown: _handleTapDown,
                onTapUp: _handleTapUp,
                onTapCancel: _handleTapCancel,
                onHover: (hovered) {
                  setState(() {
                    _isHovered = hovered;
                  });
                },
                borderRadius: BorderRadius.circular(_getBorderRadius()),
                splashColor: foregroundColor.withValues(alpha: 0.1),
                highlightColor: foregroundColor.withValues(alpha: 0.05),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: DesignTokens.space3,
                  ),
                  child: child,
                ),
              ),
            ),
          ),
        );
      },
      child: child,
    );

    return button;
  }

  double _getButtonHeight() {
    switch (widget.size) {
      case ButtonSize.small:
        return 40;
      case ButtonSize.medium:
        return 48;
      case ButtonSize.large:
        return 52;
      case ButtonSize.extraLarge:
        return 56;
    }
  }

  double _getFontSize() {
    switch (widget.size) {
      case ButtonSize.small:
        return DesignTokens.fontSizeMd;
      case ButtonSize.medium:
        return DesignTokens.fontSizeLg;
      case ButtonSize.large:
        return DesignTokens.fontSizeXl;
      case ButtonSize.extraLarge:
        return DesignTokens.fontSize2xl;
    }
  }

  double _getHorizontalPadding() {
    switch (widget.size) {
      case ButtonSize.small:
        return DesignTokens.space4;
      case ButtonSize.medium:
        return DesignTokens.space5;
      case ButtonSize.large:
        return DesignTokens.space6;
      case ButtonSize.extraLarge:
        return DesignTokens.space8;
    }
  }

  double _getIconSize() {
    switch (widget.size) {
      case ButtonSize.small:
        return DesignTokens.iconSm;
      case ButtonSize.medium:
        return DesignTokens.iconMd;
      case ButtonSize.large:
        return DesignTokens.iconLg;
      case ButtonSize.extraLarge:
        return DesignTokens.iconXl;
    }
  }

  double _getBorderRadius() {
    switch (widget.size) {
      case ButtonSize.small:
        return DesignTokens.radiusSm;
      case ButtonSize.medium:
        return DesignTokens.radiusMd;
      case ButtonSize.large:
        return DesignTokens.radiusMd;
      case ButtonSize.extraLarge:
        return DesignTokens.radiusLg;
    }
  }

  Color _getBackgroundColor(ThemeData theme) {
    final isEnabled = widget.onPressed != null && !widget.isLoading;
    
    if (!isEnabled) {
      return theme.colorScheme.outline.withValues(alpha: 0.3);
    }

    switch (widget.variant) {
      case ButtonVariant.primary:
        return _isHovered
            ? AppTheme.primaryDark
            : AppTheme.primary;
      case ButtonVariant.secondary:
        return _isHovered
            ? DesignTokens.accentDark
            : DesignTokens.accent;
      case ButtonVariant.outlined:
        return _isHovered
            ? theme.colorScheme.primary.withValues(alpha: 0.05)
            : Colors.transparent;
      case ButtonVariant.ghost:
        return _isHovered
            ? theme.colorScheme.surfaceContainerHighest
            : Colors.transparent;
      case ButtonVariant.gradient:
        return Colors.transparent; // Handled by gradient
    }
  }

  Color _getForegroundColor(ThemeData theme) {
    final isEnabled = widget.onPressed != null && !widget.isLoading;
    
    if (!isEnabled) {
      return theme.colorScheme.onSurface.withValues(alpha: 0.5);
    }

    switch (widget.variant) {
      case ButtonVariant.primary:
      case ButtonVariant.secondary:
      case ButtonVariant.gradient:
        return Colors.white;
      case ButtonVariant.outlined:
      case ButtonVariant.ghost:
        return theme.colorScheme.primary;
    }
  }

  List<BoxShadow>? _getShadow(ThemeData theme) {
    if (widget.variant == ButtonVariant.outlined ||
        widget.variant == ButtonVariant.ghost) {
      return null;
    }

    if (!_isHovered) return null;

    final shadowColor = widget.variant == ButtonVariant.primary
        ? AppTheme.primary
        : widget.variant == ButtonVariant.secondary
            ? DesignTokens.accent
            : theme.colorScheme.primary;

    return [
      BoxShadow(
        color: shadowColor.withValues(alpha: 0.3),
        blurRadius: 12,
        offset: const Offset(0, 4),
        spreadRadius: 0,
      ),
    ];
  }
}

/// 🎯 SECONDARY BUTTON - Supporting Actions (2025 Edition)
class SecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isFullWidth;
  final ButtonSize size;
  final bool isLoading;

  const SecondaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isFullWidth = true,
    this.size = ButtonSize.large,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return PrimaryButton(
      text: text,
      onPressed: onPressed,
      icon: icon,
      isFullWidth: isFullWidth,
      size: size,
      variant: ButtonVariant.outlined,
      isLoading: isLoading,
    );
  }
}

/// 🎯 TEXT BUTTON - Minimal Actions (2025 Edition)
class AppTextButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final ButtonSize size;
  final bool isLoading;

  const AppTextButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.size = ButtonSize.medium,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return PrimaryButton(
      text: text,
      onPressed: onPressed,
      icon: icon,
      isFullWidth: false,
      size: size,
      variant: ButtonVariant.ghost,
      isLoading: isLoading,
    );
  }
}

/// 🌈 GRADIENT BUTTON - Hero CTAs (2025 Edition)
class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isFullWidth;
  final ButtonSize size;
  final bool isLoading;

  const GradientButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isFullWidth = true,
    this.size = ButtonSize.large,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return PrimaryButton(
      text: text,
      onPressed: onPressed,
      icon: icon,
      isFullWidth: isFullWidth,
      size: size,
      variant: ButtonVariant.gradient,
      isLoading: isLoading,
    );
  }
}

/// 📱 FLOATING ACTION BUTTON - Modern FAB (2025 Edition)
class ModernFAB extends StatefulWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String? tooltip;
  final bool isExtended;
  final String? label;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const ModernFAB({
    super.key,
    this.onPressed,
    required this.icon,
    this.tooltip,
    this.isExtended = false,
    this.label,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  State<ModernFAB> createState() => _ModernFABState();
}

class _ModernFABState extends State<ModernFAB>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: DesignTokens.durationFast,
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.94,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: DesignTokens.curveEaseOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final backgroundColor = widget.backgroundColor ?? AppTheme.primary;
    final foregroundColor = widget.foregroundColor ?? Colors.white;

    if (widget.isExtended && widget.label != null) {
      return AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: FloatingActionButton.extended(
              onPressed: widget.onPressed,
              icon: Icon(
                widget.icon,
                color: foregroundColor,
                size: DesignTokens.iconLg,
              ),
              label: Text(
                widget.label!,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: foregroundColor,
                  fontWeight: DesignTokens.fontWeightMedium,
                ),
              ),
              backgroundColor: backgroundColor,
              foregroundColor: foregroundColor,
              elevation: 0,
              highlightElevation: 0,
              tooltip: widget.tooltip,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
              ),
            ),
          );
        },
      );
    }

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: FloatingActionButton(
            onPressed: widget.onPressed,
            tooltip: widget.tooltip,
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor,
            elevation: 0,
            highlightElevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
            ),
            child: GestureDetector(
              onTapDown: (_) {
                _animationController.forward();
              },
              onTapUp: (_) {
                _animationController.reverse();
              },
              onTapCancel: () {
                _animationController.reverse();
              },
              child: Icon(
                widget.icon,
                color: foregroundColor,
                size: DesignTokens.iconLg,
              ),
            ),
          ),
        );
      },
    );
  }
}
