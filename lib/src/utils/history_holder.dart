import 'package:flutter/material.dart';

class HistoryHolder extends ChangeNotifier {
  HistoryHolder._();

  static final i = HistoryHolder._();

  final List<String> _logs = [];
  Iterable<String> get logs => _logs;

  String dump() => _logs.join('\n');

  void log(String s) => _logs.add(s);
  void clear() {
    _logs.clear();
    notifyListeners();

    SimulationReporter.i.clear();
  }
}

class SimulationReporter {
  SimulationReporter._();

  static final i = SimulationReporter._();

  int noRouteFoundReq = 0, successRouteReq = 0, blockedRouteReq = 0;

  void clear() {
    noRouteFoundReq = 0;
    successRouteReq = 0;
    blockedRouteReq = 0;
  }
}
