import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:async/async.dart';
import 'package:routing_nanda/src/domain/usecases/validate_config_usecase.dart';
import 'package:routing_nanda/src/utils/logger.dart';
import 'package:routing_nanda/src/utils/utils.dart';

import '../../data/event.dart';
import 'node.dart';

final Random _random = Random();

class NodeRunner {
  final Node node;
  final Map<int, Node> nodeMap;

  NodeRunner({
    required this.node,
    required this.nodeMap,
  });

  final StreamController<Event> _streamController = StreamController();

  StreamSubscription<Event>? _listener;

  void sentEvent(Event event) => _streamController.add(event);

  Stream<LightPathRequest> _generateRequests(ExperimentParams expParam) async* {
    Logger.i.log('Request generator for $node is started');
    int requestIndex = 1;
    while (true) {
      // Generate inter-arrival time using exponential distribution (in seconds)
      double u = _random.nextDouble();
      double interArrivalTime = -log(1 - u) / expParam.rateOfRequest;

      // Generate holding time using exponential distribution (in seconds)
      double holdingTime = -expParam.holdTime * log(1 - _random.nextDouble());
      final lightPathRequest = LightPathRequest(
        id: requestIndex,
        holdTime: holdingTime,
      );
      Logger.i.log(
        '$node - $lightPathRequest incoming in ${interArrivalTime}s',
      );

      // Wait for the inter-arrival time, convert [interArrivalTime]s to microsecond for accuracy
      await Future.delayed(Duration(
        microseconds: (interArrivalTime * 1000000).round(),
      ));

      yield lightPathRequest;
      requestIndex += 1;
    }
  }

  void run(ExperimentParams expParam) {
    _listener = StreamGroup.merge([
      _streamController.stream,
      _generateRequests(expParam),
    ]).listen(
      (req) {
        Logger.i.log('$node - event received $req');
        switch (req) {
          case LightPathRequest():
            onLightPathRequest(req);
            break;
          case ProbRequest():
            onProbRequest(req);
            break;
          case ResvRequest():
            onResvRequest(req);
            break;
        }
      },
    );
  }

  Future<void> onLightPathRequest(LightPathRequest req) async {
    Logger.i.log('Step 2 - $node: Collecting information by signaling');
    final otherIds = nodeMap.keys.where((key) => key != node.id);
    final targetId = otherIds.elementAt(_random.nextInt(otherIds.length));
    final routeOptions = node.routingMap[targetId];
    if (routeOptions == null) {
      Logger.i.log('ERROR: route option from $node to $otherIds is not found');
      return;
    }

    for (var routes in routeOptions) {
      final probReq = ProbRequest(
        sourceId: node.id,
        targetId: targetId,
        route: routes,
        totalRouteCount: routeOptions.length,
        linkInfo: {},
      );
      // routes.routes.iterator
    }

    // // send prob signal
    // Logger.i.log('Step 3: Route and wavelength selection');
    // send signal
  }

  Future<void> onProbRequest(ProbRequest req) async {
    //
  }

  Future<void> onResvRequest(ResvRequest req) async {
    //
  }

  void stop() {
    _listener?.cancel();
    _streamController.close();
  }
}

class NodeMapper {
  final int nodeId;

  const NodeMapper({required this.nodeId});

  /// run BFS to all node then save it to [routingMap]
  Map<int, Set<RouteInfo>> setupRouteMap(
    Set<int> allNodeId,
    Map<int, Set<int>> combinedLink,
  ) {
    Map<int, Set<RouteInfo>> routingMap = {};

    // other node ids that want to be routed
    final idsExcCurrent = Set.of(allNodeId)..remove(nodeId);

    for (var otherNodeId in idsExcCurrent) {
      Logger.i.log('creating predefined route from $nodeId to $otherNodeId');

      final routes = _findShortedRouteTo(
        otherNodeId,
        combinedLink.deepCopy(),
      );
      routingMap[otherNodeId] = routes;
    }

    return routingMap;
  }

  /// run BFS to find route to [otherNodeId]
  /// will recursively find alternative route if a route found by removing found route
  Set<RouteInfo> _findShortedRouteTo(
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
        final newRoute = RouteInfo(routes: plan.trail);

        // remove found route from [newCombinedLink] to try find another route
        final newCombinedLink = combinedLink.deepCopy();
        final completePath = List.from({nodeId, ...plan.trail, visitedId});
        for (int i = 0; i < completePath.length - 1; i++) {
          newCombinedLink[completePath[i]]?.remove(completePath[i + 1]);
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
