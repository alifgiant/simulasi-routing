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

class PathCost {
  final LightPathRequest lightPathRequest;
  final RouteOptions route;
  final int lambdaId;
  final double cost;

  PathCost({
    required this.lightPathRequest,
    required this.route,
    required this.lambdaId,
    required this.cost,
  });

  @override
  String toString() {
    return 'PathCost(route:$route, lambda:$lambdaId, $cost)';
  }
}

class ProbSignal extends Event {
  final LightPathRequest lightPathRequest;
  final RouteOptions route;
  final int totalRouteCount;
  final Map<int, LinkInfo> linkInfo;

  const ProbSignal({
    required this.lightPathRequest,
    required this.route,
    required this.totalRouteCount,
    required this.linkInfo,
  });

  @override
  String toString() => 'ProbSignal(${lightPathRequest.hashCode}:$route)';
}

class ResvSignal extends Event {
  final LightPathRequest lightPathRequest;
  final int selectedLambda, fromNodeId, fromFiberIndex;
  final RouteOptions route;

  const ResvSignal({
    required this.lightPathRequest,
    required this.selectedLambda,
    required this.route,
    this.fromNodeId = -1,
    this.fromFiberIndex = -1,
  });

  @override
  String toString() =>
      'ResvSignal(lightPathRequest:${lightPathRequest.id}, lambda:$selectedLambda, route:$route)';
}

class ResvResult {
  final ResvSignal resvRequest;
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

class ReleaseSignal extends Event {
  final LightPathRequest lightPathRequest;

  const ReleaseSignal({
    required this.lightPathRequest,
  });

  @override
  String toString() => 'ReleaseSignal(lightPathRequest:${lightPathRequest.id})';
}
