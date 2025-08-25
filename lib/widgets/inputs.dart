import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../utils/design_tokens.dart';

/// 🎯 2025 MODERN INPUT SYSTEM
/// Enhanced with micro-interactions, accessibility, and premium design

/// Input size enumeration
enum InputSize { small, medium, large }

/// Input variant enumeration  
enum InputVariant { filled, outlined, underlined }

/// 🔥 MODERN TEXT FIELD - 2025 Edition
class AppTextField extends StatefulWidget {
  final String? label;
  final String? hint;
  final String? helperText;
  final String? errorText;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final bool obscureText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final IconData? prefixIcon;
  final Widget? prefixWidget;
  final IconData? suffixIcon;
  final Widget? suffixWidget;
  final VoidCallback? onSuffixTap;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final bool enabled;
  final bool readOnly;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onEditingComplete;
  final ValueChanged<String>? onFieldSubmitted;
  final FocusNode? focusNode;
  final InputSize size;
  final InputVariant variant;
  final bool autofocus;
  final TextCapitalization textCapitalization;
  final TextInputAction? textInputAction;

  const AppTextField({
    super.key,
    this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.controller,
    this.validator,
    this.obscureText = false,
    this.keyboardType,
    this.inputFormatters,
    this.prefixIcon,
    this.prefixWidget,
    this.suffixIcon,
    this.suffixWidget,
    this.onSuffixTap,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.enabled = true,
    this.readOnly = false,
    this.onTap,
    this.onChanged,
    this.onEditingComplete,
    this.onFieldSubmitted,
    this.focusNode,
    this.size = InputSize.medium,
    this.variant = InputVariant.filled,
    this.autofocus = false,
    this.textCapitalization = TextCapitalization.none,
    this.textInputAction,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _focusAnimation;
  late FocusNode _focusNode;
  late TextEditingController _controller;
  
  bool _isFocused = false;
  bool _isObscured = false;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: DesignTokens.durationMedium,
      vsync: this,
    );
    
    _focusAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: DesignTokens.curveEaseOut,
    ));
    
    _focusNode = widget.focusNode ?? FocusNode();
    _controller = widget.controller ?? TextEditingController();
    _isObscured = widget.obscureText;
    
    _focusNode.addListener(_handleFocusChange);
    _controller.addListener(_handleTextChange);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _focusNode.removeListener(_handleFocusChange);
    _controller.removeListener(_handleTextChange);
    
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    if (widget.controller == null) {
      _controller.dispose();
    }
    
    super.dispose();
  }

  void _handleFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
    
    if (_isFocused) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  void _handleTextChange() {
    if (widget.onChanged != null) {
      widget.onChanged!(_controller.text);
    }
  }

  void _toggleObscureText() {
    setState(() {
      _isObscured = !_isObscured;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasError = widget.errorText != null;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          AnimatedBuilder(
            animation: _focusAnimation,
            builder: (context, child) {
              return Text(
                widget.label!,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: hasError
                      ? AppTheme.error
                      : _isFocused
                          ? AppTheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                  fontWeight: DesignTokens.fontWeightMedium,
                ),
              );
            },
          ),
          SizedBox(height: DesignTokens.space2),
        ],
        
        AnimatedBuilder(
          animation: _focusAnimation,
          builder: (context, child) {
            return Container(
              decoration: _getContainerDecoration(theme, hasError),
              child: TextFormField(
                controller: _controller,
                focusNode: _focusNode,
                validator: widget.validator,
                obscureText: _isObscured,
                keyboardType: widget.keyboardType,
                inputFormatters: widget.inputFormatters,
                maxLines: _isObscured ? 1 : widget.maxLines,
                minLines: widget.minLines,
                maxLength: widget.maxLength,
                enabled: widget.enabled,
                readOnly: widget.readOnly,
                autofocus: widget.autofocus,
                textCapitalization: widget.textCapitalization,
                textInputAction: widget.textInputAction,
                onTap: widget.onTap,
                onEditingComplete: widget.onEditingComplete,
                onFieldSubmitted: widget.onFieldSubmitted,
                style: _getTextStyle(theme),
                decoration: _getInputDecoration(theme, hasError),
              ),
            );
          },
        ),
        
        if (widget.helperText != null || hasError) ...[
          SizedBox(height: DesignTokens.space2),
          AnimatedSwitcher(
            duration: DesignTokens.durationFast,
            child: hasError
                ? _buildErrorText(theme)
                : _buildHelperText(theme),
          ),
        ],
      ],
    );
  }

  BoxDecoration _getContainerDecoration(ThemeData theme, bool hasError) {
    if (widget.variant == InputVariant.outlined) {
      return BoxDecoration(
        borderRadius: BorderRadius.circular(_getBorderRadius()),
        border: Border.all(
          color: _getBorderColor(theme, hasError),
          width: _isFocused ? 2.0 : 1.0,
        ),
        color: widget.enabled 
          ? theme.colorScheme.surface 
          : theme.colorScheme.onSurface.withValues(alpha: 0.12),
      );
    }
    return const BoxDecoration();
  }

  InputDecoration _getInputDecoration(ThemeData theme, bool hasError) {
    return InputDecoration(
      hintText: widget.hint,
      prefixIcon: _buildPrefixIcon(theme),
      prefixIconConstraints: widget.prefixWidget != null
          ? const BoxConstraints(minWidth: 0, minHeight: 0)
          : null,
      prefix: widget.prefixWidget,
      suffixIcon: _buildSuffixIcon(theme),
      suffixIconConstraints: widget.suffixWidget != null
          ? const BoxConstraints(minWidth: 0, minHeight: 0)
          : null,
      suffix: widget.suffixWidget,
      
      // Styling based on variant
      filled: widget.variant == InputVariant.filled,
      fillColor: _getFillColor(theme),
      
      // Border styling
      border: _getBorder(),
      enabledBorder: _getBorder(),
      focusedBorder: _getFocusedBorder(theme),
      errorBorder: _getErrorBorder(),
      focusedErrorBorder: _getErrorBorder(focused: true),
      disabledBorder: _getDisabledBorder(theme),
      
      // Content styling with improved padding
      contentPadding: _getContentPadding(),
      hintStyle: _getHintStyle(theme),
      counterStyle: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
      
      // Remove default counter text for clean design
      counterText: widget.maxLength != null ? null : '',
      
      // Error styling
      errorMaxLines: 2,
      errorStyle: theme.textTheme.bodySmall?.copyWith(
        color: AppTheme.error,
        fontWeight: DesignTokens.fontWeightRegular,
      ),
    );
  }

  Widget? _buildPrefixIcon(ThemeData theme) {
    if (widget.prefixIcon == null) return null;
    
    return Icon(
      widget.prefixIcon,
      size: _getIconSize(),
      color: _isFocused
          ? AppTheme.primary
          : theme.colorScheme.onSurfaceVariant,
    );
  }

  Widget? _buildSuffixIcon(ThemeData theme) {
    if (widget.obscureText) {
      return IconButton(
        icon: Icon(
          _isObscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          size: _getIconSize(),
          color: theme.colorScheme.onSurfaceVariant,
        ),
        onPressed: _toggleObscureText,
        splashRadius: 20,
      );
    }
    
    if (widget.suffixIcon != null) {
      return IconButton(
        icon: Icon(
          widget.suffixIcon,
          size: _getIconSize(),
          color: _isFocused
              ? AppTheme.primary
              : theme.colorScheme.onSurfaceVariant,
        ),
        onPressed: widget.onSuffixTap,
        splashRadius: 20,
      );
    }
    
    return null;
  }

  Widget _buildErrorText(ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.error_outline_rounded,
          size: DesignTokens.iconSm,
          color: AppTheme.error,
        ),
        SizedBox(width: DesignTokens.space1),
        Expanded(
          child: Text(
            widget.errorText!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.error,
              fontWeight: DesignTokens.fontWeightRegular,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHelperText(ThemeData theme) {
    return Text(
      widget.helperText!,
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        fontWeight: DesignTokens.fontWeightRegular,
      ),
    );
  }

  // Style getters
  double _getBorderRadius() {
    switch (widget.size) {
      case InputSize.small:
        return DesignTokens.radiusSm;
      case InputSize.medium:
        return DesignTokens.radiusMd;
      case InputSize.large:
        return DesignTokens.radiusLg;
    }
  }

  double _getIconSize() {
    switch (widget.size) {
      case InputSize.small:
        return DesignTokens.iconSm;
      case InputSize.medium:
        return DesignTokens.iconMd;
      case InputSize.large:
        return DesignTokens.iconLg;
    }
  }

  EdgeInsets _getContentPadding() {
    switch (widget.size) {
      case InputSize.small:
        return EdgeInsets.symmetric(
          horizontal: DesignTokens.space3,
          vertical: DesignTokens.space2,
        );
      case InputSize.medium:
        return EdgeInsets.symmetric(
          horizontal: DesignTokens.space4,
          vertical: DesignTokens.space3,
        );
      case InputSize.large:
        return EdgeInsets.symmetric(
          horizontal: DesignTokens.space5,
          vertical: DesignTokens.space4,
        );
    }
  }

  TextStyle _getTextStyle(ThemeData theme) {
    final baseStyle = theme.textTheme.bodyMedium;
    
    switch (widget.size) {
      case InputSize.small:
        return baseStyle?.copyWith(
          fontSize: DesignTokens.fontSizeMd,
          fontWeight: DesignTokens.fontWeightRegular,
        ) ?? const TextStyle();
      case InputSize.medium:
        return baseStyle?.copyWith(
          fontSize: DesignTokens.fontSizeXl,
          fontWeight: DesignTokens.fontWeightRegular,
        ) ?? const TextStyle();
      case InputSize.large:
        return baseStyle?.copyWith(
          fontSize: DesignTokens.fontSize3xl,
          fontWeight: DesignTokens.fontWeightRegular,
        ) ?? const TextStyle();
    }
  }

  TextStyle _getHintStyle(ThemeData theme) {
    return _getTextStyle(theme).copyWith(
      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
      fontWeight: DesignTokens.fontWeightRegular,
    );
  }

  Color _getFillColor(ThemeData theme) {
    if (!widget.enabled) {
      return theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5);
    }
    
    return _isFocused
        ? theme.colorScheme.surface
        : theme.colorScheme.surfaceContainerHighest;
  }

  Color _getBorderColor(ThemeData theme, bool hasError) {
    if (!widget.enabled) {
      return theme.colorScheme.outline.withValues(alpha: 0.3);
    }
    
    if (hasError) {
      return AppTheme.error;
    }
    
    if (_isFocused) {
      return AppTheme.primary;
    }
    
    return theme.colorScheme.outline;
  }

  InputBorder _getBorder() {
    if (widget.variant == InputVariant.underlined) {
      return const UnderlineInputBorder(
        borderSide: BorderSide.none,
      );
    }
    
    if (widget.variant == InputVariant.outlined) {
      return const OutlineInputBorder(
        borderSide: BorderSide.none,
      );
    }
    
    // Filled variant
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(_getBorderRadius()),
      borderSide: BorderSide.none,
    );
  }

  InputBorder _getFocusedBorder(ThemeData theme) {
    if (widget.variant == InputVariant.underlined) {
      return UnderlineInputBorder(
        borderSide: BorderSide(
          color: AppTheme.primary,
          width: 2.0,
        ),
      );
    }
    
    if (widget.variant == InputVariant.outlined) {
      return const OutlineInputBorder(
        borderSide: BorderSide.none,
      );
    }
    
    // Filled variant
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(_getBorderRadius()),
      borderSide: BorderSide(
        color: AppTheme.primary,
        width: 2.0,
      ),
    );
  }

  InputBorder _getErrorBorder({bool focused = false}) {
    if (widget.variant == InputVariant.underlined) {
      return UnderlineInputBorder(
        borderSide: BorderSide(
          color: AppTheme.error,
          width: focused ? 2.0 : 1.0,
        ),
      );
    }
    
    if (widget.variant == InputVariant.outlined) {
      return const OutlineInputBorder(
        borderSide: BorderSide.none,
      );
    }
    
    // Filled variant
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(_getBorderRadius()),
      borderSide: BorderSide(
        color: AppTheme.error,
        width: focused ? 2.0 : 1.0,
      ),
    );
  }

  InputBorder _getDisabledBorder(ThemeData theme) {
    if (widget.variant == InputVariant.underlined) {
      return UnderlineInputBorder(
        borderSide: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
          width: 1.0,
        ),
      );
    }
    
    if (widget.variant == InputVariant.outlined) {
      return const OutlineInputBorder(
        borderSide: BorderSide.none,
      );
    }
    
    // Filled variant
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(_getBorderRadius()),
      borderSide: BorderSide(
        color: theme.colorScheme.outline.withValues(alpha: 0.3),
        width: 1.0,
      ),
    );
  }
}

/// 🔍 MODERN SEARCH FIELD - 2025 Edition
class SearchField extends StatefulWidget {
  final String hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final bool autofocus;
  final InputSize size;
  final List<String>? suggestions;
  final bool showSuggestions;

  const SearchField({
    super.key,
    this.hint = 'Search...',
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.autofocus = false,
    this.size = InputSize.medium,
    this.suggestions,
    this.showSuggestions = false,
  });

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late TextEditingController _controller;
  late FocusNode _focusNode;
  
  bool _isFocused = false;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: DesignTokens.durationFast,
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: DesignTokens.curveEaseOut,
    ));
    
    _controller = widget.controller ?? TextEditingController();
    _focusNode = FocusNode();
    
    _focusNode.addListener(_handleFocusChange);
    _controller.addListener(_handleTextChange);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _focusNode.removeListener(_handleFocusChange);
    _controller.removeListener(_handleTextChange);
    
    if (widget.controller == null) {
      _controller.dispose();
    }
    _focusNode.dispose();
    
    super.dispose();
  }

  void _handleFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
    
    if (_isFocused) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  void _handleTextChange() {
    setState(() {
      _hasText = _controller.text.isNotEmpty;
    });
    
    if (widget.onChanged != null) {
      widget.onChanged!(_controller.text);
    }
  }

  void _clearText() {
    _controller.clear();
    widget.onClear?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: _isFocused
            ? theme.colorScheme.surface
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(_getBorderRadius()),
        border: Border.all(
          color: _isFocused
              ? AppTheme.primary
              : Colors.transparent,
          width: _isFocused ? 2.0 : 0.0,
        ),
        boxShadow: _isFocused
            ? [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        autofocus: widget.autofocus,
        onSubmitted: widget.onSubmitted,
        style: _getTextStyle(theme),
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: _getHintStyle(theme),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: _getContentPadding(),
          prefixIcon: AnimatedBuilder(
            animation: _fadeAnimation,
            builder: (context, child) {
              return Icon(
                Icons.search_rounded,
                size: _getIconSize(),
                color: ColorTween(
                  begin: theme.colorScheme.onSurfaceVariant,
                  end: AppTheme.primary,
                ).evaluate(_fadeAnimation),
              );
            },
          ),
          suffixIcon: AnimatedSwitcher(
            duration: DesignTokens.durationFast,
            child: _hasText
                ? IconButton(
                    key: const ValueKey('clear'),
                    icon: Icon(
                      Icons.close_rounded,
                      size: _getIconSize(),
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    onPressed: _clearText,
                    splashRadius: 20,
                  )
                : null,
          ),
        ),
      ),
    );
  }

  double _getBorderRadius() {
    switch (widget.size) {
      case InputSize.small:
        return DesignTokens.radiusSm;
      case InputSize.medium:
        return DesignTokens.radiusLg;
      case InputSize.large:
        return DesignTokens.radiusXl;
    }
  }

  double _getIconSize() {
    switch (widget.size) {
      case InputSize.small:
        return DesignTokens.iconSm;
      case InputSize.medium:
        return DesignTokens.iconMd;
      case InputSize.large:
        return DesignTokens.iconLg;
    }
  }

  EdgeInsets _getContentPadding() {
    switch (widget.size) {
      case InputSize.small:
        return EdgeInsets.symmetric(
          horizontal: DesignTokens.space3,
          vertical: DesignTokens.space2,
        );
      case InputSize.medium:
        return EdgeInsets.symmetric(
          horizontal: DesignTokens.space4,
          vertical: DesignTokens.space3,
        );
      case InputSize.large:
        return EdgeInsets.symmetric(
          horizontal: DesignTokens.space5,
          vertical: DesignTokens.space4,
        );
    }
  }

  TextStyle _getTextStyle(ThemeData theme) {
    final baseStyle = theme.textTheme.bodyMedium;
    
    switch (widget.size) {
      case InputSize.small:
        return baseStyle?.copyWith(
          fontSize: DesignTokens.fontSizeMd,
          fontWeight: DesignTokens.fontWeightRegular,
        ) ?? const TextStyle();
      case InputSize.medium:
        return baseStyle?.copyWith(
          fontSize: DesignTokens.fontSizeXl,
          fontWeight: DesignTokens.fontWeightRegular,
        ) ?? const TextStyle();
      case InputSize.large:
        return baseStyle?.copyWith(
          fontSize: DesignTokens.fontSize3xl,
          fontWeight: DesignTokens.fontWeightRegular,
        ) ?? const TextStyle();
    }
  }

  TextStyle _getHintStyle(ThemeData theme) {
    return _getTextStyle(theme).copyWith(
      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
      fontWeight: DesignTokens.fontWeightRegular,
    );
  }
}

/// 💰 MODERN AMOUNT INPUT - Currency Field
class AmountField extends StatefulWidget {
  final String? label;
  final String currency;
  final double? value;
  final ValueChanged<double?>? onChanged;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final bool enabled;
  final InputSize size;
  final String? hint;

  const AmountField({
    super.key,
    this.label,
    this.currency = '\$',
    this.value,
    this.onChanged,
    this.controller,
    this.validator,
    this.enabled = true,
    this.size = InputSize.medium,
    this.hint,
  });

  @override
  State<AmountField> createState() => _AmountFieldState();
}

class _AmountFieldState extends State<AmountField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    
    if (widget.value != null) {
      _controller.text = widget.value!.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _handleChanged(String value) {
    final double? amount = double.tryParse(value);
    widget.onChanged?.call(amount);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AppTextField(
      label: widget.label,
      hint: widget.hint ?? '0.00',
      controller: _controller,
      validator: widget.validator,
      enabled: widget.enabled,
      size: widget.size,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
      ],
      onChanged: _handleChanged,
      prefixWidget: Container(
        padding: EdgeInsets.only(
          left: DesignTokens.space4,
          right: DesignTokens.space2,
        ),
        child: Text(
          widget.currency,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: DesignTokens.fontWeightMedium,
          ),
        ),
      ),
    );
  }
}

/// 📞 MODERN PHONE INPUT - International Phone Field
class PhoneField extends StatelessWidget {
  final String? label;
  final String? hint;
  final String? value;
  final ValueChanged<String>? onChanged;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final bool enabled;
  final InputSize size;
  final String countryCode;

  const PhoneField({
    super.key,
    this.label,
    this.hint,
    this.value,
    this.onChanged,
    this.controller,
    this.validator,
    this.enabled = true,
    this.size = InputSize.medium,
    this.countryCode = '+1',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AppTextField(
      label: label,
      hint: hint ?? '(555) 123-4567',
      controller: controller,
      validator: validator,
      enabled: enabled,
      size: size,
      keyboardType: TextInputType.phone,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        // Add phone number formatting here if needed
      ],
      onChanged: onChanged,
      prefixWidget: Container(
        padding: EdgeInsets.only(
          left: DesignTokens.space4,
          right: DesignTokens.space2,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              countryCode,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: DesignTokens.fontWeightMedium,
              ),
            ),
            SizedBox(width: DesignTokens.space1),
            Container(
              width: 1,
              height: 20,
              color: theme.colorScheme.outline.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}

/// 📅 MODERN DATE INPUT - Date Picker Field
class DateField extends StatefulWidget {
  final String? label;
  final String? hint;
  final DateTime? value;
  final ValueChanged<DateTime?>? onChanged;
  final String? Function(DateTime?)? validator;
  final bool enabled;
  final InputSize size;
  final DateTime? firstDate;
  final DateTime? lastDate;
  // Remove DateFormat for now - can be added with intl package
  // final DateFormat? dateFormat;

  const DateField({
    super.key,
    this.label,
    this.hint,
    this.value,
    this.onChanged,
    this.validator,
    this.enabled = true,
    this.size = InputSize.medium,
    this.firstDate,
    this.lastDate,
    // this.dateFormat,
  });

  @override
  State<DateField> createState() => _DateFieldState();
}

class _DateFieldState extends State<DateField> {
  late TextEditingController _controller;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _selectedDate = widget.value;
    _updateText();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _updateText() {
    if (_selectedDate != null) {
      // Format date - you might want to add intl package for proper formatting
      _controller.text = '${_selectedDate!.month}/${_selectedDate!.day}/${_selectedDate!.year}';
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: widget.firstDate ?? DateTime(1900),
      lastDate: widget.lastDate ?? DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppTheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _updateText();
      });
      widget.onChanged?.call(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      label: widget.label,
      hint: widget.hint ?? 'Select date',
      controller: _controller,
      enabled: widget.enabled,
      size: widget.size,
      readOnly: true,
      onTap: widget.enabled ? _selectDate : null,
      suffixIcon: Icons.calendar_today_rounded,
      onSuffixTap: widget.enabled ? _selectDate : null,
      validator: widget.validator != null
          ? (value) => widget.validator!(_selectedDate)
          : null,
    );
  }
}

/// 📝 MODERN TEXT AREA - Multi-line Input
class TextArea extends StatelessWidget {
  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final bool enabled;
  final int minLines;
  final int maxLines;
  final int? maxLength;
  final InputSize size;

  const TextArea({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.validator,
    this.onChanged,
    this.enabled = true,
    this.minLines = 3,
    this.maxLines = 6,
    this.maxLength,
    this.size = InputSize.medium,
  });

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      label: label,
      hint: hint,
      controller: controller,
      validator: validator,
      onChanged: onChanged,
      enabled: enabled,
      size: size,
      minLines: minLines,
      maxLines: maxLines,
      maxLength: maxLength,
      keyboardType: TextInputType.multiline,
      textInputAction: TextInputAction.newline,
    );
  }
}
