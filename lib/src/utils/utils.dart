import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:web/web.dart';

extension ContextExt on BuildContext {
  // configuration
  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => theme.colorScheme;
}

extension StringExt on String {
  void downloadAsFile({String? filename}) {
    final fileName = filename ?? 'logs-${DateTime.now()}.txt';
    final mimeType = fileName.endsWith(
      '.json',
    )
        ? 'application/json'
        : 'text/plain';
    document.createElement('a') as HTMLAnchorElement
      ..href = '${Uri.dataFromString(
        this,
        mimeType: mimeType,
        encoding: utf8,
      )}'
      ..style.display = 'none'
      ..download = fileName
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

extension DoubleExt on double {
  int toMicrosecondsInt() => (this * 1000000).round();
  Duration toMsDuration() => Duration(microseconds: (this * 1000000).round());
}
