import 'dart:async';

import 'package:flutter/material.dart';

class SimulationNotifier extends ChangeNotifier {
  SimulationNotifier._();

  static final SimulationNotifier i = SimulationNotifier._();

  Timer? timer;
  bool isRunning = false;
  List<LightPathResult> pathResults = List.empty(growable: true);

  void start(
    Duration duration,
  ) {
    timer?.cancel();

    isRunning = true;
    pathResults.clear();
    notifyListeners();

    timer = Timer(duration, () {
      isRunning = false;
      notifyListeners();
    });
  }

  void report(LightPathResult pathResult) {
    pathResults.add(pathResult);
  }
}

class LightPathRequest {}

class LightPathResult {
  final bool isSucess;

  const LightPathResult({required this.isSucess});
}
