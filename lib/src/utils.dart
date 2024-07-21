import 'package:flutter/material.dart';

extension ContextExt on BuildContext {
  // configuration
  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => theme.colorScheme;
}
