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

  int _noRouteFoundReq = 0, _successRouteReq = 0, _blockedRouteReq = 0;

  void reportNoRoute() => _noRouteFoundReq += 1;
  void reportSuccess() => _successRouteReq += 1;
  void reportBlocked() => _blockedRouteReq += 1;

  Map<String, int> readReport() {
    return {
      'no-route': _noRouteFoundReq,
      'success': _successRouteReq,
      'blocked': _blockedRouteReq,
    };
  }

  void clear() {
    _noRouteFoundReq = 0;
    _successRouteReq = 0;
    _blockedRouteReq = 0;
  }
}
