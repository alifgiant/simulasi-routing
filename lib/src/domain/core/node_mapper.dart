import 'dart:collection';

import 'package:routing_nanda/src/utils/logger.dart';
import 'package:routing_nanda/src/utils/utils.dart';

import 'node.dart';

class NodeMapper {
  final int nodeId;

  const NodeMapper({required this.nodeId});

  /// run BFS to all node then save it to [routingMap]
  Map<int, RouteInfo> setupRouteMap(
    Set<int> allNodeId,
    Map<int, Set<int>> combinedLink,
  ) {
    Map<int, RouteInfo> routingMap = {};

    // other node ids that want to be routed
    final idsExcCurrent = Set.of(allNodeId)..remove(nodeId);

    for (var otherNodeId in idsExcCurrent) {
      Logger.i.log('creating predefined route from $nodeId to $otherNodeId');

      final routes = _findShortedRouteTo(
        otherNodeId,
        combinedLink.deepCopy(),
      );
      routingMap[otherNodeId] = RouteInfo(
        toNodeId: otherNodeId,
        routeOptions: routes,
      );
    }

    return routingMap;
  }

  /// run BFS to find route to [otherNodeId]
  /// will recursively find alternative route if a route found by removing found route
  Set<RouteOptions> _findShortedRouteTo(
    int otherNodeId,
    Map<int, Set<int>> combinedLink,
  ) {
    Set<int> visitedNode = {nodeId};

    Queue<WalkPlan> walkPlanQueue = Queue.of((combinedLink[nodeId] ?? {}).map(
      (e) => WalkPlan(trail: {}, next: e),
    ));

    // if no plan to walk, then no route will be found
    if (walkPlanQueue.isEmpty) return {};

    while (walkPlanQueue.isNotEmpty) {
      final plan = walkPlanQueue.removeFirst();
      final visitedId = plan.next;

      // if have been visited before, skip process
      if (visitedNode.contains(visitedId)) continue;

      // mark visited
      visitedNode.add(visitedId);

      final isTargetFound = visitedId == otherNodeId;
      if (isTargetFound) {
        // create a new route
        final newRoute = RouteOptions(
          nodeIdSteps: {nodeId, ...plan.trail, visitedId},
        );

        // create [newCombinedLink] to contain routes with removed
        // remove found route from [newCombinedLink] to try find another route
        final newCombinedLink = combinedLink.deepCopy();
        final newRouteList = newRoute.nodeIdSteps.toList();
        for (int i = 0; i < newRouteList.length - 1; i++) {
          final link = newCombinedLink[newRouteList[i]];
          if (link == null) continue;

          link.remove(newRouteList[i + 1]);
        }
        // find another route
        final anotherRoute = _findShortedRouteTo(otherNodeId, newCombinedLink);

        // return all found route to [otherNodeId]
        return {
          newRoute,
          ...anotherRoute,
        };
      } else {
        // add new walk plan to queue
        final links = combinedLink[visitedId];
        if (links == null) continue;
        walkPlanQueue.addAll(
          links.map(
            (e) => WalkPlan(trail: {...plan.trail, visitedId}, next: e),
          ),
        );
      }
    }

    // if no more plan to walk, then no route is found
    return {};
  }

  Map<int, Map<int, Map<int, bool>>> setupLinkMap(
    Map<int, Set<int>> combinedLinks,
    int fiberCount,
    int lambdaCount,
  ) {
    final links = combinedLinks[nodeId];
    if (links == null || links.isEmpty) return {};

    return {
      for (var linkId in links)
        linkId: {
          for (int f = 0; f < fiberCount; f++)
            f: {
              for (int w = 0; w < lambdaCount; w++) w: false,
            },
        },
    };
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
