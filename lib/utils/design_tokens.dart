import 'package:flutter/material.dart';

/// 🎨 Finlytic 2025 - Modern Minimal Design System
/// Inspired by Linear, Vercel, and modern SaaS applications
/// Clean, minimal, and beautiful
class DesignTokens {
  // 🎯 COLOR SYSTEM - Modern Minimal
  
  // Primary Colors - Clean Blue
  static const Color primary = Color(0xFF0F172A);      // Slate 900
  static const Color primaryLight = Color(0xFF334155);  // Slate 700
  static const Color primaryDark = Color(0xFF020617);   // Slate 950
  
  // Accent Colors - Subtle Blue
  static const Color accent = Color(0xFF3B82F6);       // Blue 500
  static const Color accentLight = Color(0xFF60A5FA);  // Blue 400
  static const Color accentDark = Color(0xFF2563EB);   // Blue 600
  
  // Success Colors - Clean Green
  static const Color success = Color(0xFF10B981);      // Emerald 500
  static const Color successLight = Color(0xFF34D399); // Emerald 400
  
  // Warning Colors - Warm Amber
  static const Color warning = Color(0xFFF59E0B);      // Amber 500
  static const Color warningLight = Color(0xFFFBBF24); // Amber 400
  
  // Error Colors - Clean Red
  static const Color error = Color(0xFFEF4444);        // Red 500
  static const Color errorLight = Color(0xFFF87171);   // Red 400
  
  // Neutral Scale - Clean Grays
  static const Color neutral50 = Color(0xFFFAFAFA);    // Background
  static const Color neutral100 = Color(0xFFF5F5F5);   // Surface
  static const Color neutral200 = Color(0xFFE5E5E5);   // Border
  static const Color neutral300 = Color(0xFFD4D4D4);   // Divider
  static const Color neutral400 = Color(0xFFA3A3A3);   // Muted Text
  static const Color neutral500 = Color(0xFF737373);   // Secondary Text
  static const Color neutral600 = Color(0xFF525252);   // Primary Muted
  static const Color neutral700 = Color(0xFF404040);   // Primary Dark
  static const Color neutral800 = Color(0xFF262626);   // Dark Surface
  static const Color neutral900 = Color(0xFF171717);   // Primary Text
  
  // 📐 SPACING SYSTEM - Clean 8px Grid
  static const double space0 = 0.0;
  static const double space1 = 8.0;      // Base unit
  static const double space2 = 16.0;     // Small spacing
  static const double space3 = 24.0;     // Medium spacing
  static const double space4 = 32.0;     // Large spacing
  static const double space5 = 40.0;     // Extra large
  static const double space6 = 48.0;     // Section spacing
  static const double space8 = 64.0;     // Page spacing
  static const double space10 = 80.0;    // Hero spacing
  static const double space12 = 96.0;    // Major sections
  
  // 🔘 RADIUS SYSTEM - Subtle & Modern
  static const double radiusXs = 4.0;    // Subtle elements
  static const double radiusSm = 6.0;    // Small components
  static const double radiusMd = 8.0;    // Standard buttons/inputs
  static const double radiusLg = 12.0;   // Cards & containers
  static const double radiusXl = 16.0;   // Hero cards
  static const double radius2xl = 24.0;  // Major containers
  static const double radiusFull = 9999.0; // Pills & circles
  
  // 🎬 ANIMATION SYSTEM - Smooth & Subtle
  static const Duration durationFast = Duration(milliseconds: 150);
  static const Duration durationMedium = Duration(milliseconds: 250);
  static const Duration durationSlow = Duration(milliseconds: 350);
  
  // Animation Curves - Natural & Smooth
  static const Curve curveEaseOut = Curves.easeOutCubic;
  static const Curve curveEaseIn = Curves.easeInCubic;
  static const Curve curveEaseInOut = Curves.easeInOutCubic;
  
  // 📱 BREAKPOINTS - Responsive Design
  static const double breakpointMobile = 480;
  static const double breakpointTablet = 768;
  static const double breakpointDesktop = 1024;
  static const double breakpointWide = 1440;
  
  // 🔢 TYPOGRAPHY SCALE - Clean & Readable
  static const double fontSizeXs = 12.0;
  static const double fontSizeSm = 14.0;
  static const double fontSizeBase = 16.0;
  static const double fontSizeMd = 18.0;
  static const double fontSizeLg = 20.0;
  static const double fontSizeXl = 24.0;
  static const double fontSize2xl = 28.0;
  static const double fontSize3xl = 32.0;
  static const double fontSize4xl = 36.0;
  static const double fontSize5xl = 48.0;
  
  // Font Weights - Clean & Modern
  static const FontWeight fontWeightLight = FontWeight.w300;
  static const FontWeight fontWeightRegular = FontWeight.w400;
  static const FontWeight fontWeightMedium = FontWeight.w500;
  static const FontWeight fontWeightSemiBold = FontWeight.w600;
  static const FontWeight fontWeightBold = FontWeight.w700;
  
  // Line Heights - Optimal Readability
  static const double lineHeightTight = 1.25;
  static const double lineHeightNormal = 1.5;
  static const double lineHeightRelaxed = 1.75;
  
  // Letter Spacing - Clean & Modern
  static const double letterSpacingTight = -0.5;
  static const double letterSpacingNormal = 0.0;
  static const double letterSpacingWide = 0.5;
  static const double letterSpacingWider = 1.0;
  
  // 🔳 ELEVATION SYSTEM - Subtle Shadows
  static const double elevation0 = 0;
  static const double elevation1 = 1;
  static const double elevation2 = 2;
  static const double elevation3 = 4;
  static const double elevation4 = 8;
  static const double elevation5 = 12;
  
  // Shadow Definitions - Clean & Subtle
  static const List<BoxShadow> shadowSm = [
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 4,
      offset: Offset(0, 1),
    ),
  ];
  
  static const List<BoxShadow> shadowMd = [
    BoxShadow(
      color: Color(0x0F000000),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];
  
  static const List<BoxShadow> shadowLg = [
    BoxShadow(
      color: Color(0x15000000),
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];
  
  static const List<BoxShadow> shadowXl = [
    BoxShadow(
      color: Color(0x20000000),
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
  ];
  
  // 📏 ICON SIZES - Consistent & Clean
  static const double iconXs = 16.0;
  static const double iconSm = 20.0;
  static const double iconMd = 24.0;
  static const double iconLg = 32.0;
  static const double iconXl = 40.0;
  
  // 🎯 COMPONENT SIZES - Clean & Consistent
  static const double buttonHeightSm = 36.0;
  static const double buttonHeightMd = 44.0;
  static const double buttonHeightLg = 52.0;
  
  static const double inputHeightSm = 36.0;
  static const double inputHeightMd = 44.0;
  static const double inputHeightLg = 52.0;
  
  // 🎨 GRADIENT DEFINITIONS - Subtle & Modern
  static const LinearGradient gradientPrimary = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient gradientAccent = LinearGradient(
    colors: [accent, accentLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // 🎭 GLASSMORPHISM EFFECTS - Clean & Modern
  static const Color glassBackground = Color(0x80FFFFFF);
  static const Color glassBorder = Color(0x20FFFFFF);
  static const double glassBlur = 20.0;
  
  // Dark Theme Glass
  static const Color glassBackgroundDark = Color(0x40000000);
  static const Color glassBorderDark = Color(0x20FFFFFF);
  
  // 📱 DEVICE SPECIFIC - Clean & Consistent
  static const EdgeInsets safeAreaPadding = EdgeInsets.all(space2);
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(horizontal: space2);
  static const EdgeInsets cardPadding = EdgeInsets.all(space2);
  static const EdgeInsets listItemPadding = EdgeInsets.symmetric(
    horizontal: space2,
    vertical: space1,
  );
  
  // 🔢 Z-INDEX SYSTEM - Clean & Organized
  static const int zIndexBase = 0;
  static const int zIndexDropdown = 10;
  static const int zIndexSticky = 20;
  static const int zIndexFixed = 30;
  static const int zIndexModal = 40;
  static const int zIndexPopover = 50;
  static const int zIndexTooltip = 60;
  static const int zIndexToast = 70;
}