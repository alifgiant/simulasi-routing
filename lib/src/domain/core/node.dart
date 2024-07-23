import 'package:flutter/foundation.dart';

class Node {
  final int id;

  /// {
  ///    Node_Target : RouteInfo{
  ///       {1 -> 2 -> 3},
  ///       {1 -> 2}
  ///    }
  /// }
  final Map<int, Set<RouteInfo>> routingMap;

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
    required this.routingMap,
    required this.linkInfo,
  });

  @override
  String toString() => 'Node($id)';

  Map<String, dynamic> toJson() {
    return {
      toString(): {
        for (final entry in routingMap.entries)
          entry.key.toString(): entry.value.map((e) => e.toString()),
      },
    };
  }
}

class RouteInfo {
  final Set<int> routes;

  const RouteInfo({
    required this.routes,
  });

  @override
  String toString() => routes.join('->');

  @override
  int get hashCode => routes.fold(
        1,
        (prev, element) => prev ^ element.hashCode,
      );

  @override
  bool operator ==(covariant RouteInfo other) {
    return setEquals(routes, other.routes);
  }
}
