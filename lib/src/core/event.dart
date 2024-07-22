import 'package:routing_nanda/src/core/node.dart';

sealed class Event {
  const Event();
}

class LightPathRequest extends Event {
  final int id;
  final double holdTime;

  const LightPathRequest({
    required this.id,
    required this.holdTime,
  });

  @override
  String toString() {
    return 'LightPathRequest(id:$id)';
  }
}

class ProbRequest extends Event {
  final int sourceId, targetId;
  final RouteInfo route;

  ProbRequest({
    required this.sourceId,
    required this.targetId,
    required this.route,
  });
  // final List<LightPath> i;
}

class ResvRequest extends Event {
  //
}
