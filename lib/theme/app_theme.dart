import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/design_tokens.dart';

/// 🎨 Finlytic 2025 - Modern Minimal Theme System
/// Inspired by Linear, Vercel, and modern SaaS applications
/// Clean, minimal, and beautiful
class AppTheme {
  // 🎯 MODERN COLOR SYSTEM - Clean & Minimal
  
  // Primary Colors - Clean Slate
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
  
  // 🎨 MODERN LIGHT THEME - Clean & Minimal
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: primary,
    scaffoldBackgroundColor: neutral50,
    
         // 🎨 Enhanced Color Scheme - Modern Minimal
     colorScheme: ColorScheme.light(
       primary: primary,
       primaryContainer: neutral100,
       secondary: accent,
       secondaryContainer: accentLight.withValues(alpha: 0.1),
       tertiary: accentLight,
       surface: Colors.white,
       onSurface: neutral900,
       onSurfaceVariant: neutral600,
       outline: neutral200,
       outlineVariant: neutral300,
       shadow: neutral900.withValues(alpha: 0.1),
       scrim: neutral900.withValues(alpha: 0.1),
       inverseSurface: neutral900,
       surfaceTint: primary,
       onPrimary: Colors.white,
       onSecondary: Colors.white,
       onTertiary: Colors.white,
       onPrimaryContainer: neutral900,
       onSecondaryContainer: neutral900,
       onTertiaryContainer: neutral900,
       onError: Colors.white,
       onErrorContainer: error,
       error: error,
       errorContainer: errorLight.withValues(alpha: 0.1),
     ),
    
    // 🔤 Typography - Clean & Modern
    textTheme: _buildTextTheme(Colors.black87),
    
    // 🎨 Component Themes - Modern & Minimal
    elevatedButtonTheme: _buildElevatedButtonTheme(),
    outlinedButtonTheme: _buildOutlinedButtonTheme(),
    textButtonTheme: _buildTextButtonTheme(),
    inputDecorationTheme: _buildInputDecorationTheme(),
    cardTheme: _buildCardTheme(),
    appBarTheme: _buildAppBarTheme(),
    bottomNavigationBarTheme: _buildBottomNavigationBarTheme(),
    floatingActionButtonTheme: _buildFloatingActionButtonTheme(),
    chipTheme: _buildChipTheme(),
    dividerTheme: _buildDividerTheme(),
    iconTheme: _buildIconTheme(),
    
    // 🎬 Animation & Transitions - Smooth & Subtle
    pageTransitionsTheme: _buildPageTransitionsTheme(),
    
    
  );
  
  // 🌙 MODERN DARK THEME - Clean & Minimal
  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: accent,
    scaffoldBackgroundColor: neutral900,
    
         // 🎨 Enhanced Color Scheme - Modern Dark
     colorScheme: ColorScheme.dark(
       primary: accent,
       primaryContainer: neutral800,
       secondary: accentLight,
       secondaryContainer: accent.withValues(alpha: 0.2),
       tertiary: accentLight,
       surface: neutral900,
       onSurface: neutral50,
       onSurfaceVariant: neutral400,
       outline: neutral700,
       outlineVariant: neutral600,
       shadow: Colors.black,
       scrim: Colors.black,
       inverseSurface: neutral50,
       surfaceTint: accent,
       onPrimary: Colors.white,
       onSecondary: Colors.white,
       onTertiary: Colors.white,
       onPrimaryContainer: neutral50,
       onSecondaryContainer: neutral50,
       onTertiaryContainer: neutral50,
       onInverseSurface: neutral900,
       onError: Colors.white,
       onErrorContainer: errorLight,
       error: error,
       errorContainer: error.withValues(alpha: 0.2),
     ),
    
    // 🔤 Typography - Clean & Modern (Dark)
    textTheme: _buildTextTheme(Colors.white),
    
         // 🎨 Component Themes - Modern & Minimal (Dark)
     elevatedButtonTheme: _buildElevatedButtonTheme(),
     outlinedButtonTheme: _buildOutlinedButtonTheme(),
     textButtonTheme: _buildTextButtonTheme(),
     inputDecorationTheme: _buildInputDecorationTheme(),
     cardTheme: _buildCardTheme(),
     bottomNavigationBarTheme: _buildBottomNavigationBarTheme(),
     floatingActionButtonTheme: _buildFloatingActionButtonTheme(),
     chipTheme: _buildChipTheme(),
     dividerTheme: _buildDividerTheme(),
     iconTheme: _buildIconTheme(),
    
    // 🎬 Animation & Transitions - Smooth & Subtle
    pageTransitionsTheme: _buildPageTransitionsTheme(),
    
    // 🔧 System UI Overlay - Clean & Modern (Dark)
    appBarTheme: _buildAppBarTheme().copyWith(
      systemOverlayStyle: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    ),
  );
  
  // 🔤 Build Modern Typography
  static TextTheme _buildTextTheme(Color textColor) {
    return GoogleFonts.interTextTheme().copyWith(
      displayLarge: GoogleFonts.inter(
        fontSize: DesignTokens.fontSize5xl,
        fontWeight: DesignTokens.fontWeightBold,
        color: textColor,
        letterSpacing: DesignTokens.letterSpacingTight,
        height: DesignTokens.lineHeightTight,
      ),
      displayMedium: GoogleFonts.inter(
        fontSize: DesignTokens.fontSize4xl,
        fontWeight: DesignTokens.fontWeightBold,
        color: textColor,
        letterSpacing: DesignTokens.letterSpacingTight,
        height: DesignTokens.lineHeightTight,
      ),
      displaySmall: GoogleFonts.inter(
        fontSize: DesignTokens.fontSize3xl,
        fontWeight: DesignTokens.fontWeightBold,
        color: textColor,
        letterSpacing: DesignTokens.letterSpacingTight,
        height: DesignTokens.lineHeightTight,
      ),
      headlineLarge: GoogleFonts.inter(
        fontSize: DesignTokens.fontSize2xl,
        fontWeight: DesignTokens.fontWeightSemiBold,
        color: textColor,
        letterSpacing: DesignTokens.letterSpacingNormal,
        height: DesignTokens.lineHeightTight,
      ),
      headlineMedium: GoogleFonts.inter(
        fontSize: DesignTokens.fontSizeXl,
        fontWeight: DesignTokens.fontWeightSemiBold,
        color: textColor,
        letterSpacing: DesignTokens.letterSpacingNormal,
        height: DesignTokens.lineHeightTight,
      ),
      headlineSmall: GoogleFonts.inter(
        fontSize: DesignTokens.fontSizeLg,
        fontWeight: DesignTokens.fontWeightSemiBold,
        color: textColor,
        letterSpacing: DesignTokens.letterSpacingNormal,
        height: DesignTokens.lineHeightTight,
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: DesignTokens.fontSizeMd,
        fontWeight: DesignTokens.fontWeightMedium,
        color: textColor,
        letterSpacing: DesignTokens.letterSpacingNormal,
        height: DesignTokens.lineHeightNormal,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: DesignTokens.fontSizeBase,
        fontWeight: DesignTokens.fontWeightMedium,
        color: textColor,
        letterSpacing: DesignTokens.letterSpacingNormal,
        height: DesignTokens.lineHeightNormal,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: DesignTokens.fontSizeSm,
        fontWeight: DesignTokens.fontWeightMedium,
        color: textColor,
        letterSpacing: DesignTokens.letterSpacingNormal,
        height: DesignTokens.lineHeightNormal,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: DesignTokens.fontSizeBase,
        fontWeight: DesignTokens.fontWeightRegular,
        color: textColor,
        letterSpacing: DesignTokens.letterSpacingNormal,
        height: DesignTokens.lineHeightNormal,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: DesignTokens.fontSizeSm,
        fontWeight: DesignTokens.fontWeightRegular,
        color: textColor,
        letterSpacing: DesignTokens.letterSpacingNormal,
        height: DesignTokens.lineHeightNormal,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: DesignTokens.fontSizeXs,
        fontWeight: DesignTokens.fontWeightRegular,
        color: textColor,
        letterSpacing: DesignTokens.letterSpacingNormal,
        height: DesignTokens.lineHeightNormal,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: DesignTokens.fontSizeSm,
        fontWeight: DesignTokens.fontWeightMedium,
        color: textColor,
        letterSpacing: DesignTokens.letterSpacingWide,
        height: DesignTokens.lineHeightTight,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: DesignTokens.fontSizeXs,
        fontWeight: DesignTokens.fontWeightMedium,
        color: textColor,
        letterSpacing: DesignTokens.letterSpacingWide,
        height: DesignTokens.lineHeightTight,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: DesignTokens.fontSizeXs,
        fontWeight: DesignTokens.fontWeightMedium,
        color: textColor,
        letterSpacing: DesignTokens.letterSpacingWide,
        height: DesignTokens.lineHeightTight,
      ),
    );
  }
  
  // 🎨 Build Modern Button Themes
  static ElevatedButtonThemeData _buildElevatedButtonTheme() {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        shadowColor: Colors.transparent,
        backgroundColor: primary,
        foregroundColor: Colors.white,
        disabledBackgroundColor: neutral300,
        disabledForegroundColor: neutral500,
        surfaceTintColor: Colors.transparent,
        padding: EdgeInsets.symmetric(
          horizontal: DesignTokens.space3,
          vertical: DesignTokens.space2,
        ),
        minimumSize: Size(0, DesignTokens.buttonHeightMd),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        ),
        textStyle: GoogleFonts.inter(
          fontSize: DesignTokens.fontSizeSm,
          fontWeight: DesignTokens.fontWeightMedium,
          letterSpacing: DesignTokens.letterSpacingWide,
        ),
      ),
    );
  }
  
  static OutlinedButtonThemeData _buildOutlinedButtonTheme() {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        elevation: 0,
        shadowColor: Colors.transparent,
        backgroundColor: Colors.transparent,
        foregroundColor: primary,
        disabledBackgroundColor: Colors.transparent,
        disabledForegroundColor: neutral400,
        surfaceTintColor: Colors.transparent,
        side: BorderSide(color: neutral300, width: 1),
        padding: EdgeInsets.symmetric(
          horizontal: DesignTokens.space3,
          vertical: DesignTokens.space2,
        ),
        minimumSize: Size(0, DesignTokens.buttonHeightMd),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        ),
        textStyle: GoogleFonts.inter(
          fontSize: DesignTokens.fontSizeSm,
          fontWeight: DesignTokens.fontWeightMedium,
          letterSpacing: DesignTokens.letterSpacingWide,
        ),
      ),
    );
  }
  
  static TextButtonThemeData _buildTextButtonTheme() {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        elevation: 0,
        shadowColor: Colors.transparent,
        backgroundColor: Colors.transparent,
        foregroundColor: accent,
        disabledBackgroundColor: Colors.transparent,
        disabledForegroundColor: neutral400,
        surfaceTintColor: Colors.transparent,
        padding: EdgeInsets.symmetric(
          horizontal: DesignTokens.space2,
          vertical: DesignTokens.space1,
        ),
        minimumSize: Size(0, DesignTokens.buttonHeightSm),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
        ),
        textStyle: GoogleFonts.inter(
          fontSize: DesignTokens.fontSizeSm,
          fontWeight: DesignTokens.fontWeightMedium,
          letterSpacing: DesignTokens.letterSpacingWide,
        ),
      ),
    );
  }
  
  // 🎨 Build Modern Input Theme
  static InputDecorationTheme _buildInputDecorationTheme() {
    return InputDecorationTheme(
      filled: true,
      fillColor: neutral50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        borderSide: BorderSide(color: neutral200, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        borderSide: BorderSide(color: neutral200, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        borderSide: BorderSide(color: accent, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        borderSide: BorderSide(color: error, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        borderSide: BorderSide(color: error, width: 2),
      ),
      contentPadding: EdgeInsets.symmetric(
        horizontal: DesignTokens.space2,
        vertical: DesignTokens.space2,
      ),
      hintStyle: GoogleFonts.inter(
        fontSize: DesignTokens.fontSizeSm,
        color: neutral400,
        fontWeight: DesignTokens.fontWeightRegular,
      ),
      labelStyle: GoogleFonts.inter(
        fontSize: DesignTokens.fontSizeSm,
        color: neutral600,
        fontWeight: DesignTokens.fontWeightMedium,
      ),
      floatingLabelStyle: GoogleFonts.inter(
        fontSize: DesignTokens.fontSizeSm,
        color: accent,
        fontWeight: DesignTokens.fontWeightMedium,
      ),
    );
  }
  
       // 🎨 Build Modern Card Theme
     static CardThemeData _buildCardTheme() {
       return CardThemeData(
         elevation: 0,
         shadowColor: Colors.transparent,
         color: Colors.white,
         shape: RoundedRectangleBorder(
           borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
           side: BorderSide(color: neutral200, width: 1),
         ),
         margin: EdgeInsets.zero,
       );
     }
  
  // 🎨 Build Modern App Bar Theme
  static AppBarTheme _buildAppBarTheme() {
    return AppBarTheme(
      elevation: 0,
      shadowColor: Colors.transparent,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      foregroundColor: primary,
      centerTitle: false,
      titleTextStyle: GoogleFonts.inter(
        fontSize: DesignTokens.fontSizeLg,
        fontWeight: DesignTokens.fontWeightSemiBold,
        color: primary,
        letterSpacing: DesignTokens.letterSpacingNormal,
      ),
      toolbarTextStyle: GoogleFonts.inter(
        fontSize: DesignTokens.fontSizeSm,
        fontWeight: DesignTokens.fontWeightMedium,
        color: neutral600,
        letterSpacing: DesignTokens.letterSpacingNormal,
      ),
      iconTheme: IconThemeData(
        color: neutral600,
        size: DesignTokens.iconMd,
      ),
      actionsIconTheme: IconThemeData(
        color: neutral600,
        size: DesignTokens.iconMd,
      ),
    );
  }
  
  // 🎨 Build Modern Bottom Navigation Theme
  static BottomNavigationBarThemeData _buildBottomNavigationBarTheme() {
    return BottomNavigationBarThemeData(
      elevation: 0,
      backgroundColor: Colors.white,
      selectedItemColor: accent,
      unselectedItemColor: neutral400,
      selectedLabelStyle: GoogleFonts.inter(
        fontSize: DesignTokens.fontSizeXs,
        fontWeight: DesignTokens.fontWeightMedium,
        letterSpacing: DesignTokens.letterSpacingWide,
      ),
      unselectedLabelStyle: GoogleFonts.inter(
        fontSize: DesignTokens.fontSizeXs,
        fontWeight: DesignTokens.fontWeightRegular,
        letterSpacing: DesignTokens.letterSpacingWide,
      ),
      type: BottomNavigationBarType.fixed,
    );
  }
  
  // 🎨 Build Modern Floating Action Button Theme
  static FloatingActionButtonThemeData _buildFloatingActionButtonTheme() {
    return FloatingActionButtonThemeData(
      elevation: DesignTokens.elevation4,
             backgroundColor: accent,
       foregroundColor: Colors.white,
       shape: RoundedRectangleBorder(
         borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
       ),
    );
  }
  
  // 🎨 Build Modern Chip Theme
  static ChipThemeData _buildChipTheme() {
    return ChipThemeData(
      backgroundColor: neutral100,
      selectedColor: accent.withValues(alpha: 0.1),
      disabledColor: neutral200,
      labelStyle: GoogleFonts.inter(
        fontSize: DesignTokens.fontSizeSm,
        fontWeight: DesignTokens.fontWeightMedium,
        color: neutral700,
      ),
      secondaryLabelStyle: GoogleFonts.inter(
        fontSize: DesignTokens.fontSizeSm,
        fontWeight: DesignTokens.fontWeightMedium,
        color: accent,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: DesignTokens.space2,
        vertical: DesignTokens.space1,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
      ),
      side: BorderSide(color: neutral200, width: 1),
      elevation: 0,
      shadowColor: Colors.transparent,
    );
  }
  
  // 🎨 Build Modern Divider Theme
  static DividerThemeData _buildDividerTheme() {
    return DividerThemeData(
      color: neutral200,
      thickness: 1,
      space: DesignTokens.space2,
    );
  }
  
  // 🎨 Build Modern Icon Theme
  static IconThemeData _buildIconTheme() {
    return IconThemeData(
      color: neutral600,
      size: DesignTokens.iconMd,
    );
  }
  
  // 🎬 Build Modern Page Transitions
  static PageTransitionsTheme _buildPageTransitionsTheme() {
    return PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
        TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
      },
    );
  }
}
