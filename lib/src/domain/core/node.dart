import 'package:flutter/foundation.dart';

class Node {
  final int id;

  /// {
  ///    Node_Target : RouteInfo{
  ///       - toId
  ///       - route options:
  ///         - {1 -> 2 -> 3},
  ///         - {1 -> 2}
  ///    }
  /// }
  final Map<int, RouteInfo> routeInfos;

  /// {
  ///    Node_Target : {
  ///       fiber_id : {
  ///           wave_id : True,   // free/available
  ///           wave_id2 : False, // used
  ///       },
  ///       fiber_id2 : {
  ///           wave_id : True,   // free/available
  ///           wave_id2 : False, // used
  ///       },
  ///    }
  /// }
  final Map<int, Map<int, Map<int, bool>>> linkInfo;

  Node({
    required this.id,
    required this.routeInfos,
    required this.linkInfo,
  });

  @override
  String toString() => 'Node($id)';

  Map<String, dynamic> toJson() {
    return {
      toString(): {
        for (final entry in routeInfos.entries)
          entry.key.toString(): entry.value.routeOptions.map(
            (e) => e.toString(),
          ),
      },
    };
  }
}

class RouteInfo {
  final int toNodeId;
  final Set<RouteOptions> routeOptions;

  RouteInfo({
    required this.toNodeId,
    required this.routeOptions,
  });
}

class RouteOptions {
  final Set<int> nodeIdSteps;

  const RouteOptions({
    required this.nodeIdSteps,
  });

  @override
  String toString() => nodeIdSteps.join('->');

  @override
  int get hashCode => nodeIdSteps.fold(
        1,
        (prev, element) => prev ^ element.hashCode,
      );

  @override
  bool operator ==(covariant RouteOptions other) {
    return setEquals(nodeIdSteps, other.nodeIdSteps);
  }
}
