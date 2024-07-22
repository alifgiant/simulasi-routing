import 'package:flutter/foundation.dart';

import 'circle_data.dart';

class Node {
  final int id;
  final Map<int, Set<RouteInfo>> routingMap;

  Node({
    required this.id,
    Map<int, Set<RouteInfo>>? routingMap,
  }) : routingMap = routingMap ?? {};
  //{
  // final lightpaths = <LightPath>[];
  // for (var connection in linksMap.entries) {
  //   final source = connection.key;
  //   final targets = connection.value;
  //   for (var target in targets) {
  //     for (var fiberI = 0; fiberI < fiberCount; fiberI++) {
  //       for (var lambdaI = 0; lambdaI < lambdaCount; lambdaI++) {
  //         lightpaths.add(LightPath(
  //           source: source,
  //           target: target,
  //           fiber: fiberI,
  //           lambda: lambdaI,
  //         ));
  //       }
  //     }
  //   }
  //  }
  // }

  factory Node.fromCircle(CircleData circle) => Node(id: circle.id);

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
  String toString() => routes.isEmpty ? 'direct' : routes.join('->');

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
