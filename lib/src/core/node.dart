import 'dart:collection';

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

  /// run BFS to all node then save it to [routingMap]
  void setupRouteMap(
    Map<int, Set<int>> combinedLink,
    Set<int> allNodeId,
  ) {
    Set<int> visitedNode = {id};

    Queue<WalkPlan> walkPlanQueue = Queue.of((combinedLink[id] ?? {}).map(
      (e) => WalkPlan(trail: {}, next: e),
    ));
    if (walkPlanQueue.isEmpty) return;

    while (walkPlanQueue.isNotEmpty) {
      final plan = walkPlanQueue.removeFirst();
      if (visitedNode.contains(plan.next)) continue;

      // mark visited
      visitedNode.add(plan.next);

      // get previous mapped route and add new found route
      final prevRoutes = routingMap[plan.next] ?? {};
      prevRoutes.add(RouteInfo(routes: plan.trail));
      routingMap[plan.next] = prevRoutes;

      // try setup alternative route
      final completePath = {id, ...plan.trail, plan.next}.toList();
      final newCombinedLink = {
        for (final entry in combinedLink.entries) entry.key: entry.value.toSet()
      };
      for (int i = 0; i < completePath.length - 1; i++) {
        newCombinedLink[completePath[i]]?.remove(completePath[i + 1]);
      }

      setupRouteMap(newCombinedLink, allNodeId);

      // add new walk plan to queue
      final links = combinedLink[plan.next];
      if (links == null) continue;
      walkPlanQueue.addAll(
        links.map(
          (e) => WalkPlan(
            trail: {...plan.trail, plan.next},
            next: e,
          ),
        ),
      );
    }
  }

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

class WalkPlan {
  final Set<int> trail;
  final int next;

  const WalkPlan({
    required this.trail,
    required this.next,
  });

  @override
  String toString() => 'next:$next, trail:$trail';
}
