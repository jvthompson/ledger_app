import 'package:flutter/material.dart';

/// Shared layout constants, copied from the Write app's widget-level magic
/// numbers so Ledger's chrome matches it exactly, factored into one place.
class AppDimens {
  AppDimens._();

  static const double menuBarHeight = 32;
  static const double toolbarHeight = 44;
  static const double statusBarHeight = 28;

  static const double toolbarButtonSize = 32;
  static const double toolbarButtonRadius = 4;
  static const double toolbarIconSize = 20;

  static const double toolbarDividerPaddingH = 6;
  static const double toolbarDividerHeight = 24;
  static const double toolbarPaddingH = 8;

  static const double dropdownControlHeight = 32;

  static const Color borderColor = Colors.black26;
}
