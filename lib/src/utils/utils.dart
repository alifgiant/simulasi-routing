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
    final bytes = utf8.encode(this);
    final anchor = document.createElement('a') as HTMLAnchorElement
      ..href = "data:application/octet-stream;base64,${base64Encode(bytes)}"
      ..style.display = 'none'
      ..download = fileName;

    document.body!.appendChild(anchor);
    anchor.click();
    document.body!.removeChild(anchor);
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
