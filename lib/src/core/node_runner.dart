import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:routing_nanda/src/usecases/validate_config_usecase.dart';
import 'package:routing_nanda/src/utils/logger.dart';
import 'package:routing_nanda/src/utils/utils.dart';

import 'light_path.dart';
import 'node.dart';

final Random _random = Random();

class NodeRunner {
  final Node node;

  NodeRunner({required this.node});

  StreamSubscription<LightPathRequest>? listener;

  Stream<LightPathRequest> generateRequests(ExperimentParams expParam) async* {
    Logger.i.log('Request generator for $node is started');
    int requestIndex = 1;
    while (true) {
      // Generate inter-arrival time using exponential distribution (in seconds)
      double u = _random.nextDouble();
      double interArrivalTime = -log(1 - u) / expParam.rateOfRequest;

      // Generate holding time using exponential distribution (in seconds)
      double holdingTime = -expParam.holdTime * log(1 - _random.nextDouble());
      Logger.i.log(
        '$node - Request $requestIndex incoming in ${interArrivalTime}s and active for ${expParam.holdTime}s',
      );

      // Wait for the inter-arrival time, convert [interArrivalTime]s to microsecond for accuracy
      await Future.delayed(Duration(
        microseconds: (interArrivalTime * 1000000).round(),
      ));

      yield LightPathRequest(id: requestIndex, holdTime: holdingTime);
      requestIndex += 1;
    }
  }

  void run(ExperimentParams expParam) {
    listener = generateRequests(expParam).listen(
      (req) {
        Logger.i.log('$node - request ${req.id} processed');
        Logger.i.log('Step 2: Collecting information by signaling');
        // send prob signal
        Logger.i.log('Step 3: Route and wavelength selection');
        // send signal
      },
    );
  }

  void stop() {
    listener?.cancel();
  }
}

class NodeMapper {
  final Node node;

  const NodeMapper({required this.node});

  /// run BFS to all node then save it to [routingMap]
  Node setupRouteMap(
    Set<int> allNodeId,
    Map<int, Set<int>> combinedLink,
  ) {
    // other node ids that want to be routed
    final idsExcCurrent = Set.of(allNodeId)..remove(node.id);

    for (var otherNodeId in idsExcCurrent) {
      Logger.i.log('creating predefined route from $node to $otherNodeId');

      final routes = findShortedRouteTo(
        otherNodeId,
        combinedLink.deepCopy(),
      );
      node.routingMap[otherNodeId] = routes;
    }

    return node;
  }

  /// run BFS to find route to [otherNodeId]
  /// will recursively find alternative route if a route found by removing found route
  Set<RouteInfo> findShortedRouteTo(
    int otherNodeId,
    Map<int, Set<int>> combinedLink,
  ) {
    Set<int> visitedNode = {node.id};

    Queue<WalkPlan> walkPlanQueue = Queue.of((combinedLink[node.id] ?? {}).map(
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
        final newRoute = RouteInfo(routes: plan.trail);

        // remove found route from [newCombinedLink] to try find another route
        final newCombinedLink = combinedLink.deepCopy();
        final completePath = List.from({node.id, ...plan.trail, visitedId});
        for (int i = 0; i < completePath.length - 1; i++) {
          newCombinedLink[completePath[i]]?.remove(completePath[i + 1]);
        }
        // find another route
        final anotherRoute = findShortedRouteTo(otherNodeId, newCombinedLink);

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
