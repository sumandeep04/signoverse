import 'package:flutter/material.dart';

/// Defines the consistent color palette for the SignOverse application.
class AppColors {
  // Primary colors based on the Figma palette (Dark Teal/Green)
  static const Color primary = Color(0xFF143C3C); // Dark Teal/Green: #143C3C

  // Secondary color (Muted Green) - Used for cards and accents
  static const Color secondary = Color(0xFFF5F5F5); // Light Grey

  // Accent/Light Background (Off-White) - Used for main body background
  static const Color lightBackground = Color(0xFFFFFFFF); // White

  // Tertiary/Action color (Orange) - Used for important buttons/CTAs
  static const Color action = Color(0xFFF7934C); // Orange: #F7934C

  // Text and Dark elements color (Near Black)
  static const Color darkText = Color(0xFF1B2426); // Near Black: #1B2426

  // Light text and icons (Typically used on Primary or Secondary backgrounds)
  static const Color lightText = Colors.white;

  // A slight modification for input/secondary cards for better separation
  static const Color lightCard = Color(0xFFF5F5F5); // Light Grey

  // We can derive a slightly darker version of the secondary for contrast
  static const Color secondaryDark = Color(0xFF5A7B68);
  static Color buttonShadow = Colors.black.withOpacity(0.3);

  // FIX: Implemented the missing background getter.
  // It is set to use the explicit lightBackground color.
  static Color get background => lightBackground;

  /// NEW: Added the surface getter. This is typically used for cards,
  /// dialogs, and navigation bars to lift them slightly off the background.
  static Color get surface => lightCard;

  // FIX: Re-added and defined missing getters to resolve compilation errors
  // in files like courses_screen.dart (per uploaded image).
  static Color get accent => action; // Alias for the action color
  static Color get darkPrimary => primary;

  static Color get white => Colors.white;

}
