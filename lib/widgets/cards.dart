import 'package:flutter/material.dart';
import 'dart:ui';
import '../theme/app_theme.dart';
import '../utils/design_tokens.dart';

/// 🎯 2025 MODERN CARD SYSTEM
/// Enhanced with glassmorphism, micro-interactions, and premium design

/// Card variant enumeration
enum CardVariant { 
  elevated,     // Standard elevated card
  outlined,     // Outlined card with border
  filled,       // Filled background card
  glass,        // Glassmorphism effect
  neumorphic,   // Neumorphic depth effect
  hero          // Hero/featured cards
}

/// Card size enumeration
enum CardSize { small, medium, large, hero }

/// 🔥 MODERN CARD - 2025 Edition
class AppCard extends StatefulWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Color? color;
  final CardVariant variant;
  final CardSize size;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool enabled;
  final Color? borderColor;
  final Gradient? gradient;
  final List<BoxShadow>? customShadows;
  final double? blurIntensity;
  final bool showRipple;
  final EdgeInsets? margin;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.color,
    this.variant = CardVariant.elevated,
    this.size = CardSize.medium,
    this.borderRadius,
    this.onTap,
    this.onLongPress,
    this.enabled = true,
    this.borderColor,
    this.gradient,
    this.customShadows,
    this.blurIntensity,
    this.showRipple = true,
    this.margin,
  });

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  // Removed unused elevation animation and pressed state
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
      end: 0.98,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: DesignTokens.curveEaseOut,
    ));
    
    // No elevation animation needed
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (_isInteractive()) {
      _animationController.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (_isInteractive()) {
      _animationController.reverse();
    }
  }

  void _handleTapCancel() {
    if (_isInteractive()) {
      _animationController.reverse();
    }
  }

  bool _isInteractive() {
    return widget.enabled && (widget.onTap != null || widget.onLongPress != null);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    Widget cardContent = Container(
      margin: widget.margin,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              decoration: _getCardDecoration(theme),
              child: ClipRRect(
                borderRadius: _getBorderRadius(),
                child: _buildCardContent(theme),
              ),
            ),
          );
        },
      ),
    );

    if (_isInteractive()) {
      return GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: cardContent,
        ),
      );
    }

    return cardContent;
  }

  Widget _buildCardContent(ThemeData theme) {
    Widget content = Padding(
      padding: _getCardPadding(),
      child: widget.child,
    );

    if (widget.variant == CardVariant.glass) {
      return BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: widget.blurIntensity ?? 8.0,
          sigmaY: widget.blurIntensity ?? 8.0,
        ),
        child: content,
      );
    }

    if (_isInteractive() && widget.showRipple) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          onLongPress: widget.onLongPress,
          borderRadius: _getBorderRadius(),
          splashColor: theme.colorScheme.primary.withValues(alpha: 0.1),
          highlightColor: theme.colorScheme.primary.withValues(alpha: 0.05),
          child: content,
        ),
      );
    }

    return content;
  }

  BoxDecoration _getCardDecoration(ThemeData theme) {
    switch (widget.variant) {
      case CardVariant.elevated:
        return BoxDecoration(
          color: widget.color ?? theme.cardTheme.color,
          borderRadius: _getBorderRadius(),
          gradient: widget.gradient,
          boxShadow: widget.customShadows ?? _getElevatedShadows(theme),
        );
        
      case CardVariant.outlined:
        return BoxDecoration(
          color: widget.color ?? theme.cardTheme.color,
          borderRadius: _getBorderRadius(),
          gradient: widget.gradient,
          border: Border.all(
            color: widget.borderColor ?? theme.colorScheme.outline,
            width: 1.5,
          ),
        );
        
      case CardVariant.filled:
        return BoxDecoration(
          color: widget.color ?? theme.colorScheme.surfaceContainerHighest,
          borderRadius: _getBorderRadius(),
          gradient: widget.gradient,
        );
        
      case CardVariant.glass:
        return BoxDecoration(
          color: (widget.color ?? theme.colorScheme.surface)
              .withValues(alpha: 0.1),
          borderRadius: _getBorderRadius(),
          gradient: widget.gradient ?? DesignTokens.gradientPrimary,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 1,
          ),
          boxShadow: widget.customShadows ?? _getGlassShadows(),
        );
        
      case CardVariant.neumorphic:
        final isDark = theme.brightness == Brightness.dark;
        final baseColor = widget.color ?? theme.cardTheme.color!;
        
        return BoxDecoration(
          color: baseColor,
          borderRadius: _getBorderRadius(),
          gradient: widget.gradient,
          boxShadow: widget.customShadows ?? [
            BoxShadow(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.white.withValues(alpha: 0.8),
              offset: const Offset(-4, -4),
              blurRadius: 8,
              spreadRadius: 0,
            ),
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.4)
                  : Colors.black.withValues(alpha: 0.15),
              offset: const Offset(4, 4),
              blurRadius: 8,
              spreadRadius: 0,
            ),
          ],
        );
        
      case CardVariant.hero:
        return BoxDecoration(
          color: widget.color,
          borderRadius: _getBorderRadius(),
          gradient: widget.gradient ?? DesignTokens.gradientPrimary,
          boxShadow: widget.customShadows ?? _getHeroShadows(theme),
        );
    }
  }

  BorderRadius _getBorderRadius() {
    if (widget.borderRadius != null) {
      return widget.borderRadius!;
    }
    
    switch (widget.size) {
      case CardSize.small:
        return BorderRadius.circular(DesignTokens.radiusSm);
      case CardSize.medium:
        return BorderRadius.circular(DesignTokens.radiusLg);
      case CardSize.large:
        return BorderRadius.circular(DesignTokens.radiusXl);
      case CardSize.hero:
        return BorderRadius.circular(DesignTokens.radiusXl);
    }
  }

  EdgeInsets _getCardPadding() {
    if (widget.padding != null) {
      return widget.padding!;
    }
    
    switch (widget.size) {
      case CardSize.small:
        return EdgeInsets.all(DesignTokens.space3);
      case CardSize.medium:
        return EdgeInsets.all(DesignTokens.space4);
      case CardSize.large:
        return EdgeInsets.all(DesignTokens.space6);
      case CardSize.hero:
        return EdgeInsets.all(DesignTokens.space8);
    }
  }

  List<BoxShadow> _getElevatedShadows(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final baseElevation = _isHovered ? 1.5 : 1.0;
    
    if (isDark) {
      return DesignTokens.shadowMd.map((shadow) {
        return BoxShadow(
          color: shadow.color,
          offset: shadow.offset * baseElevation,
          blurRadius: shadow.blurRadius * baseElevation,
          spreadRadius: shadow.spreadRadius,
        );
      }).toList();
    }
    
    return DesignTokens.shadowMd.map((shadow) {
      return BoxShadow(
        color: shadow.color,
        offset: shadow.offset * baseElevation,
        blurRadius: shadow.blurRadius * baseElevation,
        spreadRadius: shadow.spreadRadius,
      );
    }).toList();
  }

  List<BoxShadow> _getGlassShadows() {
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.1),
        offset: const Offset(0, 8),
        blurRadius: 32,
        spreadRadius: -8,
      ),
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.05),
        offset: const Offset(0, 4),
        blurRadius: 16,
        spreadRadius: -4,
      ),
    ];
  }

  List<BoxShadow> _getHeroShadows(ThemeData theme) {
    final shadowColor = widget.gradient != null
        ? AppTheme.primary
        : (widget.color ?? AppTheme.primary);
    
    return [
      BoxShadow(
        color: shadowColor.withValues(alpha: 0.3),
        offset: const Offset(0, 12),
        blurRadius: 24,
        spreadRadius: -4,
      ),
      BoxShadow(
        color: shadowColor.withValues(alpha: 0.2),
        offset: const Offset(0, 6),
        blurRadius: 12,
        spreadRadius: -2,
      ),
    ];
  }
}

/// 🌌 GLASS CARD - Pure Glassmorphism Effect
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;
  final double? blurIntensity;
  final CardSize size;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
    this.onTap,
    this.blurIntensity,
    this.size = CardSize.medium,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      variant: CardVariant.glass,
      size: size,
      padding: padding,
      borderRadius: borderRadius,
      onTap: onTap,
      blurIntensity: blurIntensity,
      child: child,
    );
  }
}

/// 🕸️ NEUMORPHIC CARD - Soft UI Effect
class NeumorphicCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;
  final Color? color;
  final CardSize size;

  const NeumorphicCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
    this.onTap,
    this.color,
    this.size = CardSize.medium,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      variant: CardVariant.neumorphic,
      size: size,
      padding: padding,
      borderRadius: borderRadius,
      onTap: onTap,
      color: color,
      child: child,
    );
  }
}

/// 🎆 HERO CARD - Featured Content Card
class HeroCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;
  final Gradient? gradient;
  final Color? color;

  const HeroCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
    this.onTap,
    this.gradient,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      variant: CardVariant.hero,
      size: CardSize.hero,
      padding: padding,
      borderRadius: borderRadius,
      onTap: onTap,
      gradient: gradient,
      color: color,
      child: child,
    );
  }
}

/// 📊 MODERN STAT CARD - Metrics Display
class StatCard extends StatefulWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData? icon;
  final Color? color;
  final VoidCallback? onTap;
  final Widget? trend;
  final CardVariant variant;
  final bool showAnimation;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    this.icon,
    this.color,
    this.onTap,
    this.trend,
    this.variant = CardVariant.elevated,
    this.showAnimation = true,
  });

  @override
  State<StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<StatCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _valueAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: DesignTokens.durationSlow,
      vsync: this,
    );
    
    _valueAnimation = Tween<double>(
      begin: 0.0,
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
      curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
    ));
    
    if (widget.showAnimation) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          _animationController.forward();
        }
      });
    } else {
      _animationController.value = 1.0;
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
    final effectiveColor = widget.color ?? theme.colorScheme.primary;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return AppCard(
      variant: widget.variant,
      size: isSmallScreen ? CardSize.small : CardSize.medium,
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FadeTransition(
                opacity: _fadeAnimation,
                child: Row(
                  children: [
                    if (widget.icon != null) ...[
                      Container(
                        padding: EdgeInsets.all(
                          isSmallScreen ? DesignTokens.space2 : DesignTokens.space3,
                        ),
                        decoration: BoxDecoration(
                          color: effectiveColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                        ),
                        child: Icon(
                          widget.icon,
                          size: isSmallScreen ? DesignTokens.iconSm : DesignTokens.iconMd,
                          color: effectiveColor,
                        ),
                      ),
                      SizedBox(width: DesignTokens.space2),
                    ],
                    Expanded(
                      child: Text(
                        widget.title,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: isSmallScreen ? DesignTokens.fontSizeSm : null,
                          fontWeight: DesignTokens.fontWeightMedium,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (widget.trend != null) widget.trend!,
                  ],
                ),
              ),
              SizedBox(
                height: isSmallScreen ? DesignTokens.space2 : DesignTokens.space3,
              ),
              ScaleTransition(
                scale: _valueAnimation,
                child: Text(
                  widget.value,
                  style: (isSmallScreen 
                      ? theme.textTheme.titleLarge 
                      : theme.textTheme.headlineMedium)?.copyWith(
                    color: effectiveColor,
                    fontWeight: DesignTokens.fontWeightBold,
                    height: 1.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (widget.subtitle != null) ...[
                SizedBox(height: DesignTokens.space1),
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Text(
                    widget.subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                      fontSize: isSmallScreen ? DesignTokens.fontSizeXs : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// 🎯 MODERN ACTION CARD - Interactive Actions
class ActionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color? color;
  final VoidCallback? onTap;
  final CardVariant variant;
  final bool showBadge;
  final Widget? badge;

  const ActionCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    this.color,
    this.onTap,
    this.variant = CardVariant.elevated,
    this.showBadge = false,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = color ?? theme.colorScheme.primary;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return AppCard(
      variant: variant,
      size: isSmallScreen ? CardSize.small : CardSize.medium,
      onTap: onTap,
      child: Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(
                  isSmallScreen ? DesignTokens.space3 : DesignTokens.space4,
                ),
                decoration: BoxDecoration(
                  color: effectiveColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
                  boxShadow: [
                    BoxShadow(
                      color: effectiveColor.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  size: isSmallScreen ? DesignTokens.iconLg : DesignTokens.iconXl,
                  color: effectiveColor,
                ),
              ),
              SizedBox(
                height: isSmallScreen ? DesignTokens.space2 : DesignTokens.space3,
              ),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: DesignTokens.fontWeightSemiBold,
                  fontSize: isSmallScreen ? DesignTokens.fontSizeMd : null,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (subtitle != null) ...[
                SizedBox(height: DesignTokens.space1),
                Text(
                  subtitle!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: isSmallScreen ? DesignTokens.fontSizeXs : null,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
          if (showBadge && badge != null)
            Positioned(
              top: DesignTokens.space1,
              right: DesignTokens.space1,
              child: badge!,
            ),
        ],
      ),
    );
  }
}

/// 📝 MODERN LIST ITEM CARD - Enhanced List Items
class ListItemCard extends StatelessWidget {
  final Widget leading;
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final EdgeInsets? padding;
  final CardVariant variant;
  final bool showDivider;
  final double? height;

  const ListItemCard({
    super.key,
    required this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.padding,
    this.variant = CardVariant.filled,
    this.showDivider = false,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AppCard(
      variant: variant,
      size: CardSize.medium,
      onTap: onTap,
      padding: padding ?? EdgeInsets.all(DesignTokens.space4),
      margin: EdgeInsets.only(bottom: DesignTokens.space3),
      child: Column(
        children: [
          SizedBox(
            height: height ?? 72,
            child: Row(
              children: [
                leading,
                SizedBox(width: DesignTokens.space4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      title,
                      if (subtitle != null) ...[
                        SizedBox(height: DesignTokens.space1),
                        subtitle!,
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  SizedBox(width: DesignTokens.space4),
                  trailing!,
                ],
              ],
            ),
          ),
          if (showDivider) ...[
            SizedBox(height: DesignTokens.space3),
            Divider(
              height: 1,
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
            ),
          ],
        ],
      ),
    );
  }
}

/// 💳 BALANCE CARD - Financial Overview
class BalanceCard extends StatefulWidget {
  final String balance;
  final String? currency;
  final String? label;
  final Widget? trendWidget;
  final List<Widget>? actions;
  final VoidCallback? onTap;
  final bool showAnimation;

  const BalanceCard({
    super.key,
    required this.balance,
    this.currency = '\$',
    this.label,
    this.trendWidget,
    this.actions,
    this.onTap,
    this.showAnimation = true,
  });

  @override
  State<BalanceCard> createState() => _BalanceCardState();
}

class _BalanceCardState extends State<BalanceCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: DesignTokens.durationSlow,
      vsync: this,
    );
    
    _slideAnimation = Tween<double>(
      begin: 50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: DesignTokens.curveEaseOut,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 1.0),
    ));
    
    if (widget.showAnimation) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          _animationController.forward();
        }
      });
    } else {
      _animationController.value = 1.0;
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
    
    return HeroCard(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _slideAnimation.value),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.label ?? 'Total Balance',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontWeight: DesignTokens.fontWeightMedium,
                        ),
                      ),
                      if (widget.trendWidget != null) widget.trendWidget!,
                    ],
                  ),
                  SizedBox(height: DesignTokens.space2),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: widget.currency,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontWeight: DesignTokens.fontWeightMedium,
                          ),
                        ),
                        TextSpan(
                          text: widget.balance,
                          style: theme.textTheme.displaySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: DesignTokens.fontWeightBold,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.actions != null) ...[
                    SizedBox(height: DesignTokens.space6),
                    Row(
                      children: widget.actions!,
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
