import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:web/web.dart';

extension ContextExt on BuildContext {
  // configuration
  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => theme.colorScheme;
}

extension StringExt on String {
  void downloadAsFile() {
    document.createElement('a') as HTMLAnchorElement
      ..href = '${Uri.dataFromString(
        this,
        mimeType: 'text/plain',
        encoding: utf8,
      )}'
      ..style.display = 'none'
      ..download = 'logs-${DateTime.now()}.txt'
      ..click();
  }
}

extension MapRouteExt on Map<int, Set<int>> {
  Map<int, Set<int>> deepCopy() {
    final copiedMap = {
      for (var entry in entries) entry.key: Set.of(entry.value),
    };
    return copiedMap;
  }
}
