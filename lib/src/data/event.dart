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
  String toString() => 'LightPathRequest(id:$id)';
}

class ProbRequest extends Event {
  final LightPathRequest lightPathRequest;
  final int sourceId, targetId;
  final RouteOptions route;
  final int totalRouteCount;
  final Map<int, Map<int, Map<int, bool>>> linkInfo;

  const ProbRequest({
    required this.lightPathRequest,
    required this.sourceId,
    required this.targetId,
    required this.route,
    required this.totalRouteCount,
    required this.linkInfo,
  });
}

class ResvRequest extends Event {
  final LightPathRequest lightPathRequest;
  final int sourceId, targetId, selectedLambda;
  final RouteOptions route;

  const ResvRequest({
    required this.lightPathRequest,
    required this.sourceId,
    required this.targetId,
    required this.selectedLambda,
    required this.route,
  });
}

class ReleaseRequest extends Event {
  final ResvRequest resvRequest;

  const ReleaseRequest({
    required this.resvRequest,
  });
}
