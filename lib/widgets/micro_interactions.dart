import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../theme/app_theme.dart';
import '../utils/design_tokens.dart';

/// 🎆 2025 MODERN MICRO-INTERACTIONS & ANIMATIONS
/// Enhanced with gesture-based interactions, haptic feedback, and premium UX

// ==============================================================================
// ANIMATED BUTTON MICRO-INTERACTIONS
// ==============================================================================

class AnimatedTapButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Duration duration;
  final double scaleValue;
  final bool enableHaptics;
  final HapticFeedbackType hapticType;
  final BorderRadius? borderRadius;
  final EdgeInsets? padding;

  const AnimatedTapButton({
    super.key,
    required this.child,
    this.onTap,
    this.duration = const Duration(milliseconds: 150),
    this.scaleValue = 0.95,
    this.enableHaptics = true,
    this.hapticType = HapticFeedbackType.light,
    this.borderRadius,
    this.padding,
  });

  @override
  State<AnimatedTapButton> createState() => _AnimatedTapButtonState();
}

enum HapticFeedbackType {
  light,
  medium,
  heavy,
  selection,
}

class _AnimatedTapButtonState extends State<AnimatedTapButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scaleValue,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.8,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _triggerHapticFeedback() {
    if (!widget.enableHaptics) return;
    
    switch (widget.hapticType) {
      case HapticFeedbackType.light:
        HapticFeedback.lightImpact();
        break;
      case HapticFeedbackType.medium:
        HapticFeedback.mediumImpact();
        break;
      case HapticFeedbackType.heavy:
        HapticFeedback.heavyImpact();
        break;
      case HapticFeedbackType.selection:
        HapticFeedback.selectionClick();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        _animationController.forward();
        _triggerHapticFeedback();
      },
      onTapUp: (_) {
        _animationController.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () {
        _animationController.reverse();
      },
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: _opacityAnimation.value,
              child: Container(
                padding: widget.padding,
                decoration: BoxDecoration(
                  borderRadius: widget.borderRadius,
                ),
                child: widget.child,
              ),
            ),
          );
        },
      ),
    );
  }
}

// ==============================================================================
// FLOATING ACTION BUTTON MICRO-INTERACTIONS
// ==============================================================================

class AnimatedFloatingButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final Color? backgroundColor;
  final double size;
  final bool isExpanded;
  final List<FloatingActionButtonChild>? children;

  const AnimatedFloatingButton({
    super.key,
    this.onPressed,
    required this.child,
    this.backgroundColor,
    this.size = 56.0,
    this.isExpanded = false,
    this.children,
  });

  @override
  State<AnimatedFloatingButton> createState() => _AnimatedFloatingButtonState();
}

class FloatingActionButtonChild {
  final Widget child;
  final String label;
  final VoidCallback onPressed;
  final Color? backgroundColor;

  const FloatingActionButtonChild({
    required this.child,
    required this.label,
    required this.onPressed,
    this.backgroundColor,
  });
}

class _AnimatedFloatingButtonState extends State<AnimatedFloatingButton>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _rotationController;
  late AnimationController _scaleController;
  
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fabScaleAnimation;
  
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _mainController = AnimationController(
      duration: DesignTokens.durationMedium,
      vsync: this,
    );
    
    _rotationController = AnimationController(
      duration: DesignTokens.durationMedium,
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: Duration(milliseconds: 150),
      vsync: this,
    );

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.125, // 45 degrees
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: DesignTokens.curveEaseOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: DesignTokens.curveEaseOut,
    ));

    _fabScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _mainController.dispose();
    _rotationController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
    });

    if (_isExpanded) {
      _mainController.forward();
      _rotationController.forward();
    } else {
      _mainController.reverse();
      _rotationController.reverse();
    }

    HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        // Backdrop
        if (_isExpanded)
          GestureDetector(
            onTap: _toggleExpansion,
            child: AnimatedBuilder(
              animation: _mainController,
              builder: (context, child) {
                return Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.black.withValues(alpha: 0.3 * _scaleAnimation.value),
                );
              },
            ),
          ),

        // Child buttons
        if (widget.children != null)
          ...widget.children!.asMap().entries.map((entry) {
            final index = entry.key;
            final child = entry.value;
            
            return AnimatedBuilder(
              animation: _mainController,
              builder: (context, _) {
                final offset = (index + 1) * 70.0 * _scaleAnimation.value;
                return Positioned(
                  bottom: offset,
                  right: 0,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Opacity(
                      opacity: _scaleAnimation.value,
                      child: _buildChildButton(child),
                    ),
                  ),
                );
              },
            );
          }),

        // Main FAB
        AnimatedBuilder(
          animation: Listenable.merge([_rotationController, _scaleController]),
          builder: (context, child) {
            return Transform.scale(
              scale: _fabScaleAnimation.value,
              child: Transform.rotate(
                angle: _rotationAnimation.value * 2 * math.pi,
                child: FloatingActionButton(
                  onPressed: widget.children != null ? _toggleExpansion : widget.onPressed,
                  backgroundColor: widget.backgroundColor ?? AppTheme.primary,
                  elevation: 8,
                  child: widget.child,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildChildButton(FloatingActionButtonChild child) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: DesignTokens.space3,
            vertical: DesignTokens.space2,
          ),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          ),
          child: Text(
            child.label,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: DesignTokens.fontWeightMedium,
            ),
          ),
        ),
        SizedBox(width: DesignTokens.space2),
        AnimatedTapButton(
          onTap: () {
            _toggleExpansion();
            child.onPressed();
          },
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: child.backgroundColor ?? DesignTokens.accent,
              borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: child.child,
          ),
        ),
      ],
    );
  }
}

// ==============================================================================
// PARALLAX SCROLL EFFECTS
// ==============================================================================

class ParallaxScrollView extends StatefulWidget {
  final List<Widget> children;
  final double parallaxStrength;
  final Widget? backgroundWidget;
  final ScrollController? controller;

  const ParallaxScrollView({
    super.key,
    required this.children,
    this.parallaxStrength = 0.5,
    this.backgroundWidget,
    this.controller,
  });

  @override
  State<ParallaxScrollView> createState() => _ParallaxScrollViewState();
}

class _ParallaxScrollViewState extends State<ParallaxScrollView> {
  late ScrollController _scrollController;
  double _scrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.controller ?? ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    if (widget.controller == null) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  void _onScroll() {
    setState(() {
      _scrollOffset = _scrollController.offset;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (widget.backgroundWidget != null)
          Positioned.fill(
            child: Transform.translate(
              offset: Offset(0, _scrollOffset * widget.parallaxStrength),
              child: widget.backgroundWidget!,
            ),
          ),
        ListView(
          controller: _scrollController,
          children: widget.children,
        ),
      ],
    );
  }
}

// ==============================================================================
// STAGGERED ANIMATIONS
// ==============================================================================

class StaggeredAnimationList extends StatefulWidget {
  final List<Widget> children;
  final Duration duration;
  final Duration delay;
  final Curve curve;
  final Axis direction;

  const StaggeredAnimationList({
    super.key,
    required this.children,
    this.duration = const Duration(milliseconds: 600),
    this.delay = const Duration(milliseconds: 100),
    this.curve = Curves.easeOutCubic,
    this.direction = Axis.vertical,
  });

  @override
  State<StaggeredAnimationList> createState() => _StaggeredAnimationListState();
}

class _StaggeredAnimationListState extends State<StaggeredAnimationList>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _fadeAnimations;
  late List<Animation<Offset>> _slideAnimations;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startStaggeredAnimations();
  }

  void _initializeAnimations() {
    _controllers = List.generate(
      widget.children.length,
      (index) => AnimationController(
        duration: widget.duration,
        vsync: this,
      ),
    );

    _fadeAnimations = _controllers.map((controller) {
      return Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: widget.curve,
      ));
    }).toList();

    _slideAnimations = _controllers.map((controller) {
      final offset = widget.direction == Axis.vertical
          ? Offset(0, 0.3)
          : Offset(0.3, 0);
      
      return Tween<Offset>(
        begin: offset,
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: widget.curve,
      ));
    }).toList();
  }

  void _startStaggeredAnimations() async {
    for (int i = 0; i < _controllers.length; i++) {
      await Future.delayed(widget.delay);
      if (mounted) {
        _controllers[i].forward();
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.direction == Axis.vertical
        ? Column(
            children: _buildAnimatedChildren(),
          )
        : Row(
            children: _buildAnimatedChildren(),
          );
  }

  List<Widget> _buildAnimatedChildren() {
    return widget.children.asMap().entries.map((entry) {
      final index = entry.key;
      final child = entry.value;

      return AnimatedBuilder(
        animation: Listenable.merge([
          _fadeAnimations[index],
          _slideAnimations[index],
        ]),
        builder: (context, _) {
          return FadeTransition(
            opacity: _fadeAnimations[index],
            child: SlideTransition(
              position: _slideAnimations[index],
              child: child,
            ),
          );
        },
      );
    }).toList();
  }
}

// ==============================================================================
// MORPHING CONTAINER
// ==============================================================================

class MorphingContainer extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Color? fromColor;
  final Color? toColor;
  final BorderRadius? fromBorderRadius;
  final BorderRadius? toBorderRadius;
  final EdgeInsets? fromPadding;
  final EdgeInsets? toPadding;
  final bool isAnimated;

  const MorphingContainer({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.fromColor,
    this.toColor,
    this.fromBorderRadius,
    this.toBorderRadius,
    this.fromPadding,
    this.toPadding,
    required this.isAnimated,
  });

  @override
  State<MorphingContainer> createState() => _MorphingContainerState();
}

class _MorphingContainerState extends State<MorphingContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _colorAnimation;
  late Animation<BorderRadius?> _borderRadiusAnimation;
  late Animation<EdgeInsets?> _paddingAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _colorAnimation = ColorTween(
      begin: widget.fromColor,
      end: widget.toColor,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: DesignTokens.curveEaseOut,
    ));

    _borderRadiusAnimation = BorderRadiusTween(
      begin: widget.fromBorderRadius,
      end: widget.toBorderRadius,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: DesignTokens.curveEaseOut,
    ));

    _paddingAnimation = EdgeInsetsTween(
      begin: widget.fromPadding,
      end: widget.toPadding,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: DesignTokens.curveEaseOut,
    ));
  }

  @override
  void didUpdateWidget(MorphingContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isAnimated != oldWidget.isAnimated) {
      if (widget.isAnimated) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          padding: _paddingAnimation.value,
          decoration: BoxDecoration(
            color: _colorAnimation.value,
            borderRadius: _borderRadiusAnimation.value,
          ),
          child: widget.child,
        );
      },
    );
  }
}

// ==============================================================================
// RIPPLE EFFECT
// ==============================================================================

class RippleEffect extends StatefulWidget {
  final Widget child;
  final Color rippleColor;
  final Duration duration;
  final VoidCallback? onTap;

  const RippleEffect({
    super.key,
    required this.child,
    this.rippleColor = Colors.white,
    this.duration = const Duration(milliseconds: 300),
    this.onTap,
  });

  @override
  State<RippleEffect> createState() => _RippleEffectState();
}

class _RippleEffectState extends State<RippleEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rippleAnimation;
  late Animation<double> _fadeAnimation;
  
  Offset? _tapPosition;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _rippleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.3,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startRipple(Offset position) {
    setState(() {
      _tapPosition = position;
      _isAnimating = true;
    });
    
    _controller.forward().then((_) {
      setState(() {
        _isAnimating = false;
      });
      _controller.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (details) {
        _startRipple(details.localPosition);
        widget.onTap?.call();
      },
      child: Stack(
        children: [
          widget.child,
          if (_isAnimating && _tapPosition != null)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return CustomPaint(
                    painter: RipplePainter(
                      center: _tapPosition!,
                      radius: _rippleAnimation.value,
                      color: widget.rippleColor.withValues(alpha: _fadeAnimation.value),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class RipplePainter extends CustomPainter {
  final Offset center;
  final double radius;
  final Color color;

  RipplePainter({
    required this.center,
    required this.radius,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (radius <= 0) return;

    final maxRadius = math.sqrt(size.width * size.width + size.height * size.height);
    final currentRadius = maxRadius * radius;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, currentRadius, paint);
  }

  @override
  bool shouldRepaint(RipplePainter oldDelegate) {
    return oldDelegate.center != center ||
           oldDelegate.radius != radius ||
           oldDelegate.color != color;
  }
}

// ==============================================================================
// UTILITY MIXINS AND HELPERS
// ==============================================================================

mixin HapticFeedbackMixin {
  void triggerLightHaptic() => HapticFeedback.lightImpact();
  void triggerMediumHaptic() => HapticFeedback.mediumImpact();
  void triggerHeavyHaptic() => HapticFeedback.heavyImpact();
  void triggerSelectionHaptic() => HapticFeedback.selectionClick();
}

class MicroInteractionUtils {
  static void delayedAction(Duration delay, VoidCallback action) {
    Future.delayed(delay, action);
  }

  static void staggeredActions(
    List<VoidCallback> actions,
    Duration staggerDelay,
  ) {
    for (int i = 0; i < actions.length; i++) {
      Future.delayed(
        Duration(milliseconds: staggerDelay.inMilliseconds * i),
        actions[i],
      );
    }
  }

  static AnimationController createBounceController({
    required TickerProvider vsync,
    Duration duration = const Duration(milliseconds: 600),
  }) {
    return AnimationController(duration: duration, vsync: vsync);
  }

  static Animation<double> createBounceAnimation(AnimationController controller) {
    return Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.elasticOut,
    ));
  }

  static Animation<Offset> createSlideAnimation(
    AnimationController controller, {
    Offset begin = const Offset(0, 1),
    Offset end = Offset.zero,
  }) {
    return Tween<Offset>(
      begin: begin,
      end: end,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: DesignTokens.curveEaseOut,
    ));
  }
}