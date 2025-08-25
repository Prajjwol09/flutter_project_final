import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import '../../theme/app_theme.dart';
import '../../utils/design_tokens.dart';
import '../../widgets/buttons.dart';
import '../../widgets/inputs.dart';
import '../../widgets/cards.dart';
import '../../providers/auth_provider.dart';

/// 🎆 2025 MODERN EDIT PROFILE SCREEN
/// Enhanced with neural network gradients, glassmorphism, and premium form design
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  
  bool _isLoading = false;
  String _selectedCurrency = 'USD';
  
  late AnimationController _animationController;
  late AnimationController _backgroundController;
  late AnimationController _profileController;
  
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _backgroundAnimation;
  late Animation<double> _profileScaleAnimation;

  final List<String> _currencies = [
    'USD', 'EUR', 'GBP', 'JPY', 'CAD', 'AUD', 'CHF', 'CNY', 'INR', 'NPR'
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimationSequence();
    
    final user = ref.read(userProvider).value;
    if (user != null) {
      _nameController.text = user.name;
      _emailController.text = user.email;
      _phoneController.text = user.phoneNumber ?? '';
      _selectedCurrency = user.currency;
    }
  }

  void _initializeAnimations() {
    // Main animation controller
    _animationController = AnimationController(
      duration: DesignTokens.durationMedium,
      vsync: this,
    );
    
    // Background animation controller (continuous)
    _backgroundController = AnimationController(
      duration: Duration(milliseconds: 8000),
      vsync: this,
    );
    
    // Profile animation controller
    _profileController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );
    
    // Main animations
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
    
    // Background animation
    _backgroundAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _backgroundController,
      curve: Curves.easeInOut,
    ));
    
    // Profile scale animation
    _profileScaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _profileController,
      curve: Curves.elasticOut,
    ));
  }

  void _startAnimationSequence() async {
    // Set status bar style
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
    );
    
    // Start background animation (continuous)
    _backgroundController.repeat(reverse: true);
    
    // Start profile animation
    await Future.delayed(Duration(milliseconds: 300));
    _profileController.forward();
    
    await Future.delayed(Duration(milliseconds: 200));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _backgroundController.dispose();
    _profileController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(userProvider).value;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final updatedUser = user.copyWith(
        name: _nameController.text,
        email: _emailController.text,
        phoneNumber: _phoneController.text.isNotEmpty ? _phoneController.text : null,
        currency: _selectedCurrency,
      );

      await ref.read(userProvider.notifier).updateUser(updatedUser);
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(DesignTokens.space4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(DesignTokens.space4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
            ),
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      body: AnimatedBuilder(
        animation: _backgroundController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(DesignTokens.accent, DesignTokens.accentDark, _backgroundAnimation.value)!,
                  Color.lerp(AppTheme.primary, AppTheme.primaryLight, _backgroundAnimation.value)!,
                  Color.lerp(AppTheme.primaryDark, DesignTokens.accent, _backgroundAnimation.value)!,
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
            child: SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: _buildMainContent(theme),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMainContent(ThemeData theme) {
    return CustomScrollView(
      slivers: [
        _buildModernAppBar(theme),
        SliverPadding(
          padding: EdgeInsets.all(DesignTokens.space4),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildProfilePhotoSection(theme),
              SizedBox(height: DesignTokens.space8),
              _buildPersonalInfoForm(theme),
              SizedBox(height: DesignTokens.space8),
              _buildPreferencesSection(theme),
              SizedBox(height: DesignTokens.space8),
              _buildSaveButton(),
              SizedBox(height: 80), // Extra bottom padding
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildModernAppBar(ThemeData theme) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: Container(
        margin: EdgeInsets.only(left: DesignTokens.space4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        ),
        child: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_rounded, color: Colors.white),
        ),
      ),
      title: Text(
        'Edit Profile',
        style: theme.textTheme.headlineMedium?.copyWith(
          fontWeight: DesignTokens.fontWeightBold,
          color: Colors.white,
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: 0.3),
              offset: Offset(0, 2),
              blurRadius: 8,
            ),
          ],
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withValues(alpha: 0.1),
              ],
            ),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: EdgeInsets.fromLTRB(
                DesignTokens.space4,
                kToolbarHeight + 40,
                DesignTokens.space4,
                DesignTokens.space4,
              ),
              child: Text(
                'Update your personal information',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontWeight: DesignTokens.fontWeightMedium,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      offset: Offset(0, 1),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfilePhotoSection(ThemeData theme) {
    return Center(
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _profileController,
            builder: (context, child) {
              return Transform.scale(
                scale: _profileScaleAnimation.value,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: DesignTokens.accent,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          child: Icon(
                            Icons.person_rounded,
                            size: 60,
                            color: Colors.white,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: DesignTokens.gradientPrimary,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primary.withValues(alpha: 0.3),
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: IconButton(
                              onPressed: _changeProfilePicture,
                              icon: Icon(
                                Icons.camera_alt_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          SizedBox(height: DesignTokens.space3),
          Text(
            'Tap to change photo',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
              fontWeight: DesignTokens.fontWeightMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoForm(ThemeData theme) {
    return AppCard(
      variant: CardVariant.glass,
      borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
      padding: EdgeInsets.all(DesignTokens.space4),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Personal Information',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: DesignTokens.fontWeightSemiBold,
                color: Colors.white,
                fontSize: 18,
              ),
            ),
            SizedBox(height: DesignTokens.space4),
            
            AppTextField(
              controller: _nameController,
              label: 'Full Name',
              hint: 'Enter your full name',
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Please enter your name';
                return null;
              },
            ),
            
            SizedBox(height: DesignTokens.space4),
            
            AppTextField(
              controller: _emailController,
              label: 'Email',
              hint: 'Enter your email',
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Please enter your email';
                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value!)) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
            
            SizedBox(height: DesignTokens.space4),
            
            AppTextField(
              controller: _phoneController,
              label: 'Phone Number (Optional)',
              hint: 'Enter your phone number',
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferencesSection(ThemeData theme) {
    return AppCard(
      variant: CardVariant.glass,
      borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
      padding: EdgeInsets.all(DesignTokens.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Preferences',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: DesignTokens.fontWeightSemiBold,
              color: Colors.white,
              fontSize: 18,
            ),
          ),
          SizedBox(height: DesignTokens.space4),
          _buildModernCurrencySelection(theme),
        ],
      ),
    );
  }

  Widget _buildModernCurrencySelection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Currency',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 14,
            fontWeight: DesignTokens.fontWeightMedium,
          ),
        ),
        SizedBox(height: DesignTokens.space2),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: DesignTokens.space4,
            vertical: DesignTokens.space3,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCurrency,
              isExpanded: true,
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Colors.white.withValues(alpha: 0.8),
              ),
              dropdownColor: AppTheme.primaryDark,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: DesignTokens.fontWeightMedium,
              ),
              items: _currencies.map((currency) {
                return DropdownMenuItem<String>(
                  value: currency,
                  child: Text(
                    currency,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: DesignTokens.fontWeightMedium,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedCurrency = value);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: Container(
        decoration: BoxDecoration(
          gradient: DesignTokens.gradientPrimary,
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.3),
              blurRadius: 20,
              spreadRadius: 2,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: PrimaryButton(
          text: _isLoading ? 'Saving...' : 'Save Changes',
          onPressed: _isLoading ? null : _saveProfile,
          isLoading: _isLoading,
        ),
      ),
    );
  }

  void _changeProfilePicture() {
    // TODO: Implement profile picture change functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Profile picture change will be implemented'),
        backgroundColor: DesignTokens.accent,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(DesignTokens.space4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        ),
      ),
    );
  }
}