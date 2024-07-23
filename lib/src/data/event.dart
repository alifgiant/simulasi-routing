import 'package:routing_nanda/src/domain/core/node.dart';

sealed class Event {
  const Event();
}

class LightPathRequest extends Event {
  final int id;
  final double holdTime; // in seconds

  const LightPathRequest({
    required this.id,
    required this.holdTime,
  });

  @override
  String toString() => 'LightPathRequest(id:$id)';
}

class ProbRequest extends Event {
  final LightPathRequest lightPathRequest;
  final RouteOptions route;
  final int totalRouteCount;
  final Map<int, LinkInfo> linkInfo;

  const ProbRequest({
    required this.lightPathRequest,
    required this.route,
    required this.totalRouteCount,
    required this.linkInfo,
  });

  @override
  String toString() => 'ProbRequest(${lightPathRequest.hashCode}:$route)';
}

class ResvRequest extends Event {
  final LightPathRequest lightPathRequest;
  final int selectedLambda, fromNodeId, fromFiberIndex;
  final RouteOptions route;

  const ResvRequest({
    required this.lightPathRequest,
    required this.selectedLambda,
    required this.route,
    this.fromNodeId = -1,
    this.fromFiberIndex = -1,
  });
}

class ResvResult {
  final ResvRequest resvRequest;
  final int fromNodeId;
  final int fromFiberIndex;
  final int toNodeId;
  final int toFiberIndex;

  const ResvResult({
    required this.resvRequest,
    required this.fromNodeId,
    required this.fromFiberIndex,
    required this.toNodeId,
    required this.toFiberIndex,
  });
}

class ReleaseRequest extends Event {
  final LightPathRequest lightPathRequest;

  const ReleaseRequest({
    required this.lightPathRequest,
  });
}
