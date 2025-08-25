import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../theme/app_theme.dart';
import '../utils/design_tokens.dart';
import 'buttons.dart';

/// 🎆 2025 MODERN LOADING & SHIMMER COMPONENTS
/// Enhanced with neural network aesthetics, advanced animations, and glassmorphism

// ==============================================================================
// MODERN LOADING STATE COMPONENT
// ==============================================================================

class ModernLoadingState extends StatefulWidget {
  final String? message;
  final double? size;
  final LoadingType type;
  final Color? color;
  final bool showBackground;
  final Widget? customIcon;

  const ModernLoadingState({
    super.key,
    this.message,
    this.size,
    this.type = LoadingType.circular,
    this.color,
    this.showBackground = true,
    this.customIcon,
  });

  @override
  State<ModernLoadingState> createState() => _ModernLoadingStateState();
}

enum LoadingType {
  circular,
  dots,
  pulse,
  wave,
  neuralNetwork,
}

class _ModernLoadingStateState extends State<ModernLoadingState>
    with TickerProviderStateMixin {
  late AnimationController _primaryController;
  late AnimationController _secondaryController;
  late AnimationController _backgroundController;
  
  late Animation<double> _primaryAnimation;
  late Animation<double> _secondaryAnimation;
  late Animation<double> _backgroundAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
  }

  void _initializeAnimations() {
    _primaryController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _secondaryController = AnimationController(
      duration: Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _backgroundController = AnimationController(
      duration: Duration(milliseconds: 3000),
      vsync: this,
    );

    _primaryAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _primaryController,
      curve: Curves.easeInOut,
    ));

    _secondaryAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _secondaryController,
      curve: Curves.easeInOut,
    ));
    
    _backgroundAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _backgroundController,
      curve: Curves.easeInOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _primaryController,
      curve: DesignTokens.curveEaseOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _primaryController,
      curve: Curves.elasticOut,
    ));
  }

  void _startAnimations() {
    _primaryController.repeat();
    _secondaryController.repeat();
    _backgroundController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _primaryController.dispose();
    _secondaryController.dispose();
    _backgroundController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loadingColor = widget.color ?? AppTheme.primary;
    
    return AnimatedBuilder(
      animation: Listenable.merge([
        _primaryController,
        _secondaryController,
        _backgroundController,
      ]),
      builder: (context, child) {
        return Container(
          decoration: widget.showBackground
              ? BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.lerp(AppTheme.primary, AppTheme.primaryDark, _backgroundAnimation.value)!.withValues(alpha: 0.05),
                      Color.lerp(AppTheme.neutral100, AppTheme.neutral50, _backgroundAnimation.value)!.withValues(alpha: 0.03),
                      Color.lerp(DesignTokens.accent, AppTheme.primaryLight, _backgroundAnimation.value)!.withValues(alpha: 0.05),
                    ],
                    stops: [0.0, 0.5, 1.0],
                  ),
                )
              : null,
          child: Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLoadingIndicator(loadingColor),
                    if (widget.message != null) ...[
                      SizedBox(height: DesignTokens.space6),
                      _buildLoadingMessage(theme),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingIndicator(Color color) {
    final size = widget.size ?? 48.0;
    
    switch (widget.type) {
      case LoadingType.circular:
        return _buildCircularLoader(size, color);
      case LoadingType.dots:
        return _buildDotsLoader(size, color);
      case LoadingType.pulse:
        return _buildPulseLoader(size, color);
      case LoadingType.wave:
        return _buildWaveLoader(size, color);
      case LoadingType.neuralNetwork:
        return _buildNeuralNetworkLoader(size, color);
    }
  }

  Widget _buildCircularLoader(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: DesignTokens.gradientPrimary,
        borderRadius: BorderRadius.circular(size / 2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: CircularProgressIndicator(
        strokeWidth: 3,
        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        backgroundColor: Colors.white.withValues(alpha: 0.3),
      ),
    );
  }

  Widget _buildDotsLoader(double size, Color color) {
    return SizedBox(
      width: size * 2,
      height: size / 2,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(3, (index) {
          final delay = index * 0.2;
          return AnimatedBuilder(
            animation: _primaryController,
            builder: (context, child) {
              final animationValue = math.sin(
                (_primaryAnimation.value + delay) * 2 * math.pi,
              ).abs();
              return Transform.scale(
                scale: 0.5 + (animationValue * 0.5),
                child: Container(
                  width: size / 4,
                  height: size / 4,
                  decoration: BoxDecoration(
                    gradient: DesignTokens.gradientPrimary,
                    borderRadius: BorderRadius.circular(size / 8),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.3 * animationValue),
                        blurRadius: 10 * animationValue,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }

  Widget _buildPulseLoader(double size, Color color) {
    return AnimatedBuilder(
      animation: _primaryController,
      builder: (context, child) {
        final scale = 0.8 + (_primaryAnimation.value * 0.4);
        final opacity = 1.0 - _primaryAnimation.value;
        return Transform.scale(
          scale: scale,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              gradient: DesignTokens.gradientPrimary,
              borderRadius: BorderRadius.circular(size / 2),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3 * opacity),
                  blurRadius: 30 * scale,
                  spreadRadius: 10 * scale,
                ),
              ],
            ),
            child: widget.customIcon ?? Icon(
              Icons.trending_up_rounded,
              color: Colors.white,
              size: size / 2,
            ),
          ),
        );
      },
    );
  }

  Widget _buildWaveLoader(double size, Color color) {
    return SizedBox(
      width: size * 1.5,
      height: size / 2,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(5, (index) {
          return AnimatedBuilder(
            animation: _primaryController,
            builder: (context, child) {
              final waveValue = math.sin(
                (_primaryAnimation.value * 2 * math.pi) + (index * 0.5),
              );
              final height = (size / 4) + (waveValue * (size / 8));
              return Container(
                width: size / 8,
                height: height.abs(),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [color, color.withValues(alpha: 0.6)],
                  ),
                  borderRadius: BorderRadius.circular(size / 16),
                ),
              );
            },
          );
        }),
      ),
    );
  }

  Widget _buildNeuralNetworkLoader(double size, Color color) {
    return CustomPaint(
      size: Size(size, size),
      painter: NeuralNetworkPainter(
        animation: _primaryAnimation,
        secondaryAnimation: _secondaryAnimation,
        color: color,
      ),
    );
  }

  Widget _buildLoadingMessage(ThemeData theme) {
    return AnimatedBuilder(
      animation: _secondaryController,
      builder: (context, child) {
        final opacity = 0.6 + (_secondaryAnimation.value * 0.4);
        return Opacity(
          opacity: opacity,
          child: Text(
            widget.message!,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: AppTheme.primary,
              fontWeight: DesignTokens.fontWeightMedium,
              shadows: [
                Shadow(
                  color: AppTheme.primary.withValues(alpha: 0.3),
                  blurRadius: 10,
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        );
      },
    );
  }
}

class NeuralNetworkPainter extends CustomPainter {
  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final Color color;

  NeuralNetworkPainter({
    required this.animation,
    required this.secondaryAnimation,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 3;

    // Draw neural network nodes
    final nodes = [
      Offset(center.dx, center.dy - radius),
      Offset(center.dx - radius * 0.6, center.dy + radius * 0.3),
      Offset(center.dx + radius * 0.6, center.dy + radius * 0.3),
    ];

    // Draw connections
    paint.color = color.withValues(alpha: 0.3 + (animation.value * 0.4));
    for (int i = 0; i < nodes.length; i++) {
      for (int j = i + 1; j < nodes.length; j++) {
        canvas.drawLine(nodes[i], nodes[j], paint);
      }
    }

    // Draw nodes
    for (int i = 0; i < nodes.length; i++) {
      final nodeAnimation = math.sin(
        (animation.value + (i * 0.3)) * 2 * math.pi,
      ).abs();
      final nodeSize = 8 + (nodeAnimation * 4);
      
      paint
        ..style = PaintingStyle.fill
        ..color = color.withValues(alpha: 0.8 + (nodeAnimation * 0.2));
      
      canvas.drawCircle(nodes[i], nodeSize, paint);
    }
  }

  @override
  bool shouldRepaint(NeuralNetworkPainter oldDelegate) {
    return animation.value != oldDelegate.animation.value ||
           secondaryAnimation.value != oldDelegate.secondaryAnimation.value;
  }
}

// ==============================================================================
// MODERN ERROR STATE COMPONENT
// ==============================================================================

class ModernErrorState extends StatefulWidget {
  final String message;
  final VoidCallback? onRetry;
  final IconData? icon;
  final String? title;
  final String? retryText;
  final bool showBackground;

  const ModernErrorState({
    super.key,
    required this.message,
    this.onRetry,
    this.icon,
    this.title,
    this.retryText,
    this.showBackground = true,
  });

  @override
  State<ModernErrorState> createState() => _ModernErrorStateState();
}

class _ModernErrorStateState extends State<ModernErrorState>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _backgroundController;
  late AnimationController _iconController;
  
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _backgroundAnimation;
  late Animation<double> _iconBounceAnimation;
  late Animation<double> _scaleAnimation;

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
    
    _backgroundController = AnimationController(
      duration: Duration(milliseconds: 4000),
      vsync: this,
    );
    
    _iconController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: DesignTokens.curveEaseOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _backgroundAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _backgroundController,
      curve: Curves.easeInOut,
    ));

    _iconBounceAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _iconController,
      curve: Curves.elasticOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
  }

  void _startAnimations() async {
    _backgroundController.repeat(reverse: true);
    await Future.delayed(Duration(milliseconds: 200));
    _animationController.forward();
    await Future.delayed(Duration(milliseconds: 500));
    _iconController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _backgroundController.dispose();
    _iconController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AnimatedBuilder(
      animation: Listenable.merge([
        _animationController,
        _backgroundController,
        _iconController,
      ]),
      builder: (context, child) {
        return Container(
          decoration: widget.showBackground
              ? BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.lerp(AppTheme.error, AppTheme.error.withRed(180), _backgroundAnimation.value)!.withValues(alpha: 0.05),
                      Color.lerp(AppTheme.neutral100, AppTheme.neutral50, _backgroundAnimation.value)!.withValues(alpha: 0.03),
                      Color.lerp(AppTheme.warning, AppTheme.errorLight, _backgroundAnimation.value)!.withValues(alpha: 0.05),
                    ],
                    stops: [0.0, 0.5, 1.0],
                  ),
                )
              : null,
          child: Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Padding(
                    padding: EdgeInsets.all(DesignTokens.space6),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildErrorIcon(),
                        SizedBox(height: DesignTokens.space6),
                        _buildErrorTitle(theme),
                        SizedBox(height: DesignTokens.space3),
                        _buildErrorMessage(theme),
                        if (widget.onRetry != null) ...[
                          SizedBox(height: DesignTokens.space8),
                          _buildRetryButton(),
                        ],
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

  Widget _buildErrorIcon() {
    return AnimatedBuilder(
      animation: _iconController,
      builder: (context, child) {
        return Transform.scale(
          scale: _iconBounceAnimation.value,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.error, AppTheme.error.withRed(180)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.error.withValues(alpha: 0.3 * _iconBounceAnimation.value),
                  blurRadius: 30 * _iconBounceAnimation.value,
                  spreadRadius: 5 * _iconBounceAnimation.value,
                ),
              ],
            ),
            child: Icon(
              widget.icon ?? Icons.error_outline_rounded,
              size: 40,
              color: Colors.white,
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorTitle(ThemeData theme) {
    return Text(
      widget.title ?? 'Oops! Something went wrong',
      style: theme.textTheme.headlineMedium?.copyWith(
        fontWeight: DesignTokens.fontWeightBold,
        color: AppTheme.error,
        fontSize: 24,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildErrorMessage(ThemeData theme) {
    return Text(
      widget.message,
      style: theme.textTheme.bodyLarge?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        fontSize: 16,
        height: 1.5,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildRetryButton() {
    return PrimaryButton(
      text: widget.retryText ?? 'Try Again',
      onPressed: widget.onRetry,
      variant: ButtonVariant.outlined,
      icon: Icons.refresh_rounded,
    );
  }
}

// ==============================================================================
// MODERN EMPTY STATE COMPONENT
// ==============================================================================

class ModernEmptyState extends StatefulWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final VoidCallback? onAction;
  final String? actionLabel;
  final bool showBackground;
  final Widget? illustration;

  const ModernEmptyState({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.onAction,
    this.actionLabel,
    this.showBackground = true,
    this.illustration,
  });

  @override
  State<ModernEmptyState> createState() => _ModernEmptyStateState();
}

class _ModernEmptyStateState extends State<ModernEmptyState>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _backgroundController;
  late AnimationController _floatController;
  
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _backgroundAnimation;
  late Animation<double> _floatAnimation;
  late Animation<double> _scaleAnimation;

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
    
    _backgroundController = AnimationController(
      duration: Duration(milliseconds: 6000),
      vsync: this,
    );
    
    _floatController = AnimationController(
      duration: Duration(milliseconds: 3000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: DesignTokens.curveEaseOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _backgroundAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _backgroundController,
      curve: Curves.easeInOut,
    ));

    _floatAnimation = Tween<double>(
      begin: -5.0,
      end: 5.0,
    ).animate(CurvedAnimation(
      parent: _floatController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
  }

  void _startAnimations() async {
    _backgroundController.repeat(reverse: true);
    _floatController.repeat(reverse: true);
    await Future.delayed(Duration(milliseconds: 200));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _backgroundController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AnimatedBuilder(
      animation: Listenable.merge([
        _animationController,
        _backgroundController,
        _floatController,
      ]),
      builder: (context, child) {
        return Container(
          decoration: widget.showBackground
              ? BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.lerp(AppTheme.neutral200, AppTheme.neutral100, _backgroundAnimation.value)!.withValues(alpha: 0.3),
                      Color.lerp(AppTheme.neutral100, AppTheme.neutral50, _backgroundAnimation.value)!.withValues(alpha: 0.2),
                      Color.lerp(AppTheme.primary, AppTheme.primaryLight, _backgroundAnimation.value)!.withValues(alpha: 0.1),
                    ],
                    stops: [0.0, 0.5, 1.0],
                  ),
                )
              : null,
          child: Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Padding(
                    padding: EdgeInsets.all(DesignTokens.space6),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildEmptyIcon(),
                        SizedBox(height: DesignTokens.space6),
                        _buildEmptyTitle(theme),
                        if (widget.subtitle != null) ...[
                          SizedBox(height: DesignTokens.space3),
                          _buildEmptySubtitle(theme),
                        ],
                        if (widget.onAction != null && widget.actionLabel != null) ...[
                          SizedBox(height: DesignTokens.space8),
                          _buildActionButton(),
                        ],
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

  Widget _buildEmptyIcon() {
    return AnimatedBuilder(
      animation: _floatController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatAnimation.value),
          child: widget.illustration ?? Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.neutral300.withValues(alpha: 0.3),
                  AppTheme.neutral200.withValues(alpha: 0.2),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
              border: Border.all(
                color: AppTheme.neutral300.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Icon(
              widget.icon ?? Icons.inbox_outlined,
              size: 60,
              color: AppTheme.neutral400,
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyTitle(ThemeData theme) {
    return Text(
      widget.title,
      style: theme.textTheme.headlineMedium?.copyWith(
        fontWeight: DesignTokens.fontWeightBold,
        color: theme.colorScheme.onSurface,
        fontSize: 24,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildEmptySubtitle(ThemeData theme) {
    return Text(
      widget.subtitle!,
      style: theme.textTheme.bodyLarge?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        fontSize: 16,
        height: 1.5,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildActionButton() {
    return PrimaryButton(
      text: widget.actionLabel!,
      onPressed: widget.onAction,
      icon: Icons.add_rounded,
    );
  }
}

// ==============================================================================
// MODERN SHIMMER COMPONENTS
// ==============================================================================

class ModernShimmer extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Color? baseColor;
  final Color? highlightColor;
  final ShimmerDirection direction;

  const ModernShimmer({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1500),
    this.baseColor,
    this.highlightColor,
    this.direction = ShimmerDirection.ltr,
  });

  @override
  State<ModernShimmer> createState() => _ModernShimmerState();
}

enum ShimmerDirection {
  ltr,
  rtl,
  ttb,
  btt,
}

class _ModernShimmerState extends State<ModernShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    
    _animation = Tween<double>(
      begin: -2.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _animationController.repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = widget.baseColor ?? 
        (isDark ? AppTheme.neutral800 : AppTheme.neutral200);
    final highlightColor = widget.highlightColor ?? 
        (isDark ? AppTheme.neutral700 : AppTheme.neutral100);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            final gradientTransform = _GradientTransform(
              _animation.value,
              widget.direction,
              bounds,
            );
            
            return LinearGradient(
              colors: [
                baseColor,
                baseColor,
                highlightColor,
                baseColor,
                baseColor,
              ],
              stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
              transform: gradientTransform,
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

class _GradientTransform extends GradientTransform {
  final double percent;
  final ShimmerDirection direction;
  final Rect bounds;

  const _GradientTransform(
    this.percent,
    this.direction,
    this.bounds,
  );

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    switch (direction) {
      case ShimmerDirection.ltr:
        return Matrix4.translationValues(
          (bounds.width + bounds.width) * percent, 0.0, 0.0);
      case ShimmerDirection.rtl:
        return Matrix4.translationValues(
          -(bounds.width + bounds.width) * percent, 0.0, 0.0);
      case ShimmerDirection.ttb:
        return Matrix4.translationValues(
          0.0, (bounds.height + bounds.height) * percent, 0.0);
      case ShimmerDirection.btt:
        return Matrix4.translationValues(
          0.0, -(bounds.height + bounds.height) * percent, 0.0);
    }
  }
}

// ==============================================================================
// SHIMMER PLACEHOLDER COMPONENTS
// ==============================================================================

class ModernShimmerBox extends StatelessWidget {
  final double height;
  final double? width;
  final BorderRadius? borderRadius;
  final EdgeInsets? margin;
  final Color? baseColor;
  final Color? highlightColor;

  const ModernShimmerBox({
    super.key,
    required this.height,
    this.width,
    this.borderRadius,
    this.margin,
    this.baseColor,
    this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: margin,
      child: ModernShimmer(
        baseColor: baseColor ?? (isDark ? AppTheme.neutral800 : AppTheme.neutral200),
        highlightColor: highlightColor ?? (isDark ? AppTheme.neutral700 : AppTheme.neutral100),
        child: Container(
          height: height,
          width: width,
          decoration: BoxDecoration(
            color: baseColor ?? (isDark ? AppTheme.neutral800 : AppTheme.neutral200),
            borderRadius: borderRadius ?? BorderRadius.circular(DesignTokens.radiusMd),
            border: Border.all(
              color: (isDark ? AppTheme.neutral700 : AppTheme.neutral100).withValues(alpha: 0.3),
              width: 1,
            ),
          ),
        ),
      ),
    );
  }
}

class ModernListItemShimmer extends StatelessWidget {
  final bool showAvatar;
  final bool showTrailing;
  final EdgeInsets? padding;

  const ModernListItemShimmer({
    super.key,
    this.showAvatar = true,
    this.showTrailing = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? EdgeInsets.symmetric(
        horizontal: DesignTokens.space4,
        vertical: DesignTokens.space3,
      ),
      child: Row(
        children: [
          if (showAvatar) ...[
            ModernShimmerBox(
              height: 48,
              width: 48,
              borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
            ),
            SizedBox(width: DesignTokens.space3),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ModernShimmerBox(
                  height: 16,
                  width: double.infinity,
                ),
                SizedBox(height: DesignTokens.space2),
                ModernShimmerBox(
                  height: 14,
                  width: MediaQuery.of(context).size.width * 0.6,
                ),
              ],
            ),
          ),
          if (showTrailing) ...[
            SizedBox(width: DesignTokens.space3),
            ModernShimmerBox(
              height: 20,
              width: 80,
            ),
          ],
        ],
      ),
    );
  }
}

class ModernCardShimmer extends StatelessWidget {
  final double height;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final bool showHeader;
  final bool showContent;
  final bool showFooter;

  const ModernCardShimmer({
    super.key,
    required this.height,
    this.padding,
    this.margin,
    this.showHeader = true,
    this.showContent = true,
    this.showFooter = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? EdgeInsets.all(DesignTokens.space4),
      padding: padding ?? EdgeInsets.all(DesignTokens.space4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        border: Border.all(
          color: AppTheme.neutral200.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showHeader) ...[
            Row(
              children: [
                ModernShimmerBox(
                  height: 24,
                  width: 24,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                ),
                SizedBox(width: DesignTokens.space3),
                Expanded(
                  child: ModernShimmerBox(
                    height: 20,
                    width: double.infinity,
                  ),
                ),
              ],
            ),
            SizedBox(height: DesignTokens.space4),
          ],
          if (showContent) ...[
            ModernShimmerBox(
              height: height - (showHeader ? 60 : 0) - (showFooter ? 40 : 0),
              width: double.infinity,
            ),
          ],
          if (showFooter) ...[
            SizedBox(height: DesignTokens.space4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ModernShimmerBox(
                  height: 16,
                  width: 100,
                ),
                ModernShimmerBox(
                  height: 16,
                  width: 60,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class ModernProfileShimmer extends StatelessWidget {
  const ModernProfileShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(DesignTokens.space6),
      child: Column(
        children: [
          // Profile header
          Row(
            children: [
              ModernShimmerBox(
                height: 80,
                width: 80,
                borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
              ),
              SizedBox(width: DesignTokens.space4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ModernShimmerBox(
                      height: 24,
                      width: double.infinity,
                    ),
                    SizedBox(height: DesignTokens.space2),
                    ModernShimmerBox(
                      height: 16,
                      width: MediaQuery.of(context).size.width * 0.7,
                    ),
                    SizedBox(height: DesignTokens.space2),
                    ModernShimmerBox(
                      height: 14,
                      width: MediaQuery.of(context).size.width * 0.5,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: DesignTokens.space8),
          
          // Stats section
          Row(
            children: List.generate(3, (index) {
              return Expanded(
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: DesignTokens.space2),
                  child: Column(
                    children: [
                      ModernShimmerBox(
                        height: 32,
                        width: double.infinity,
                      ),
                      SizedBox(height: DesignTokens.space2),
                      ModernShimmerBox(
                        height: 16,
                        width: double.infinity,
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
          
          SizedBox(height: DesignTokens.space8),
          
          // List items
          ...List.generate(5, (index) => ModernListItemShimmer(
            padding: EdgeInsets.only(bottom: DesignTokens.space3),
          )),
        ],
      ),
    );
  }
}

class ModernChartShimmer extends StatelessWidget {
  final double height;
  final bool showLegend;

  const ModernChartShimmer({
    super.key,
    required this.height,
    this.showLegend = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(DesignTokens.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showLegend) ...[
            Row(
              children: List.generate(3, (index) {
                return Expanded(
                  child: Container(
                    margin: EdgeInsets.only(right: DesignTokens.space3),
                    child: Row(
                      children: [
                        ModernShimmerBox(
                          height: 12,
                          width: 12,
                          borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                        ),
                        SizedBox(width: DesignTokens.space2),
                        Expanded(
                          child: ModernShimmerBox(
                            height: 14,
                            width: double.infinity,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
            SizedBox(height: DesignTokens.space6),
          ],
          ModernShimmerBox(
            height: height,
            width: double.infinity,
            borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          ),
        ],
      ),
    );
  }
}

// ==============================================================================
// UTILITY ALIASES FOR BACKWARD COMPATIBILITY
// ==============================================================================

// Keep the old class names as aliases for backward compatibility
typedef LoadingState = ModernLoadingState;
typedef ErrorState = ModernErrorState;
typedef EmptyState = ModernEmptyState;
typedef ShimmerLoading = ModernShimmerBox;
typedef ListItemShimmer = ModernListItemShimmer;
typedef CardShimmer = ModernCardShimmer;
