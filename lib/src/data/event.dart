import 'package:routing_nanda/src/domain/core/node.dart';

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
  final int totalRouteCount;
  final Map<int, Map<int, Map<int, bool>>> linkInfo;

  ProbRequest({
    required this.sourceId,
    required this.targetId,
    required this.route,
    required this.totalRouteCount,
    required this.linkInfo,
  });
}

class ResvRequest extends Event {
  //
}
