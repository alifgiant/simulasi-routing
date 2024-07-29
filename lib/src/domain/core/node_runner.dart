import 'dart:async';
import 'dart:math';

import 'package:async/async.dart';
import 'package:routing_nanda/src/domain/usecases/validate_config_usecase.dart';
import 'package:routing_nanda/src/utils/history_holder.dart';
import 'package:routing_nanda/src/utils/logger.dart';
import 'package:routing_nanda/src/utils/utils.dart';

import '../../data/event.dart';
import 'node.dart';

final Random _random = Random();

class NodeRunner {
  final Node node;
  final ExperimentParams expParam;
  final int Function(int from) _genRandomTarget;
  final void Function(int to, Event event) _sentEvent;

  NodeRunner({
    required this.node,
    required this.expParam,
    required int Function(int from) genRandomTarget,
    required void Function(int to, Event event) sentEvent,
  })  : _genRandomTarget = genRandomTarget,
        _sentEvent = sentEvent;

  StreamController<Event>? _streamController;
  final Map<LightPathRequest, Set<ProbSignal>> probRequestHolder = {};
  final Map<LightPathRequest, ResvResult> resvRequestHolder = {};

  StreamSubscription<Event>? _listener;

  void receive(Event event) {
    final ctlr = _streamController;
    if (ctlr == null || ctlr.isClosed) return;

    ctlr.add(event);
  }

  Stream<LightPathRequest> _generateRequests() async* {
    Logger.i.log('$node - Request generator is started');
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

      // Wait for the inter-arrival time,
      // convert [interArrivalTime]s to microsecond for accuracy
      await Future.delayed(interArrivalTime.toMsDuration());

      yield lightPathRequest;
      requestIndex += 1;
    }
  }

  void run() {
    final streamController = StreamController<Event>();
    _streamController = streamController;

    _listener = StreamGroup.merge([
      streamController.stream,
      _generateRequests(),
    ]).listen(
      (req) {
        Logger.i.log('$node - event received $req');
        switch (req) {
          case LightPathRequest():
            onLightPathRequest(req);
            break;
          case ProbSignal():
            onProbRequest(req);
            break;
          case ResvSignal():
            onResvRequest(req);
            break;
          case ReleaseSignal():
            onReleaseRequest(req);
            break;
        }
      },
    );
  }

  Future<void> onLightPathRequest(LightPathRequest req) async {
    SimulationReporter.i.reportCreated();
    final targetId = _genRandomTarget(node.id);
    final routeInfo = node.routeInfos[targetId];

    Logger.i.log(
      'Step 2 - $node: Collecting information by signaling',
    );
    if (routeInfo == null) {
      Logger.i.log('ERROR: route option from $node to $targetId is not found');
      SimulationReporter.i.reportNoRoute();
      return;
    }

    Logger.i.log(
      'Sending prob to $targetId using ${routeInfo.routeOptions.length} routes',
    );
    for (var route in routeInfo.routeOptions) {
      // start prob to each route
      final probReq = ProbSignal(
        lightPathRequest: req,
        route: route,
        totalRouteCount: routeInfo.routeOptions.length,
        linkInfo: {},
      );
      final nextNodeId = _attachLinkInfo(probReq);
      _sentEvent(nextNodeId, probReq);
    }
  }

  Future<void> onProbRequest(ProbSignal probReq) async {
    if (probReq.route.nodeIdSteps.last == node.id) {
      // if req arrived in final destination, try wavelength selection
      // access saved req if any
      final savedReq = probRequestHolder[probReq.lightPathRequest] ?? {};

      final totalCount = probReq.totalRouteCount;
      Logger.i.log(
        '$node - ProbReq arrived, ${savedReq.length + 1} of $totalCount',
      );
      if (totalCount == savedReq.length + 1) {
        // if all req have arrived, do wavelength selection
        Logger.i.log('Step 3 - $node: Route and wavelength selection');

        // combine all req, new incoming with saved and delete saved placeholder
        final processedReq = {probReq, ...savedReq};
        probRequestHolder.remove(probReq.lightPathRequest);

        _processProbReq(processedReq);
      } else {
        // not all request have arrive, store first to use later
        savedReq.add(probReq);
        probRequestHolder[probReq.lightPathRequest] = savedReq;
      }
    } else {
      final nextNodeId = _attachLinkInfo(probReq);
      _sentEvent(nextNodeId, probReq);
    }
  }

  Future<void> onResvRequest(ResvSignal req) async {
    final nodeIdRoutes = req.route.nodeIdSteps.toList();
    final lastIndex = nodeIdRoutes.length - 1;

    // start from behind to find next node link if any
    int toNodeId = -1;
    int toFiberIndex = -1;
    for (var i = lastIndex; i > 0; i--) {
      final current = nodeIdRoutes[i];
      if (current != node.id) continue;

      toNodeId = nodeIdRoutes[i - 1];
      final linkInfo = node.linkInfo[toNodeId];
      if (linkInfo == null) break;

      // find available fiber with given lambda
      final indexedFibers = linkInfo.fibers.indexed;
      final indexedFreeFibers = indexedFibers.where(
        (item) =>
            item.$2.lambdaAvailability[req.selectedLambda] == Availability.free,
      );
      if (indexedFreeFibers.isEmpty) {
        // if fiber not available for given wavelength, thus blocked
        SimulationReporter.i.reportBlocked();
        Logger.i.log('Block detected for ${req.lightPathRequest}:${req.route}');

        // propagate release request to previous node
        if (req.fromNodeId != -1) {
          _sentEvent(
            req.fromNodeId,
            ReleaseSignal(lightPathRequest: req.lightPathRequest),
          );
        }

        // early return when block is met
        return;
      } else {
        // if fiber still available for given lambda, then
        final randomSelect = _random.nextInt(indexedFreeFibers.length);
        toFiberIndex = indexedFreeFibers.elementAt(randomSelect).$1;

        // propagate resv request
        _sentEvent(
          toNodeId,
          ResvSignal(
            lightPathRequest: req.lightPathRequest,
            selectedLambda: req.selectedLambda,
            route: req.route,
            fromNodeId: node.id, // request is coming from current node
            fromFiberIndex: toFiberIndex,
          ),
        );
      }
      break;
    }

    // save reserve info and mark used in the link
    final resvResult = ResvResult(
      resvRequest: req,
      fromNodeId: req.fromNodeId,
      fromFiberIndex: req.fromFiberIndex,
      toNodeId: toNodeId,
      toFiberIndex: toFiberIndex,
    );
    resvRequestHolder[req.lightPathRequest] = resvResult;

    // use link : from
    _changeLinkStatus(
      resvResult.fromNodeId,
      resvResult.fromFiberIndex,
      req.selectedLambda,
      Availability.used,
    );

    // use link : to
    _changeLinkStatus(
      resvResult.toNodeId,
      resvResult.toFiberIndex,
      req.selectedLambda,
      Availability.used,
    );

    if (req.route.nodeIdSteps.first == node.id) {
      // resv [ResvRequest] arrive at start, then link success
      SimulationReporter.i.reportSuccess();
      Logger.i.log('Successfull link for ${req.lightPathRequest}:${req.route}');
      Logger.i.log('Hold time: ${req.lightPathRequest.holdTime}s');

      // spent hold time
      await Future.delayed(req.lightPathRequest.holdTime.toMsDuration());

      // propagate release event, start with current node
      _sentEvent(
        node.id,
        ReleaseSignal(lightPathRequest: req.lightPathRequest),
      );
    }
  }

  /// release holded link when a [req] received
  Future<void> onReleaseRequest(ReleaseSignal req) async {
    final reserveResult = resvRequestHolder[req.lightPathRequest];
    if (reserveResult == null) return;

    // release link usage : from
    _changeLinkStatus(
      reserveResult.fromNodeId,
      reserveResult.fromFiberIndex,
      reserveResult.resvRequest.selectedLambda,
      Availability.free,
    );

    // release link usage : to
    _changeLinkStatus(
      reserveResult.toNodeId,
      reserveResult.toFiberIndex,
      reserveResult.resvRequest.selectedLambda,
      Availability.free,
    );

    // remove saved req
    resvRequestHolder.remove(req.lightPathRequest);

    // start from behind to pass release req to reserve-from node
    if (reserveResult.fromNodeId == -1) return;
    _sentEvent(reserveResult.fromNodeId, req);
  }

  /// attach current node -> next node link info
  /// return next node id
  int _attachLinkInfo(ProbSignal probReq) {
    final nodeIdRoutes = probReq.route.nodeIdSteps.toList();
    int next = nodeIdRoutes[1];
    for (var i = 0; i < nodeIdRoutes.length - 1; i++) {
      final current = nodeIdRoutes[i];
      if (current != node.id) continue;

      next = nodeIdRoutes[i + 1];

      final linkInfoToNext = node.linkInfo[next];
      if (linkInfoToNext == null) break;

      probReq.linkInfo[node.id] = linkInfoToNext;
      break;
    }

    return next;
  }

  void _changeLinkStatus(
    int nodeId,
    int fiberId,
    int lambdaId,
    Availability status,
  ) {
    final toLinkInfo = node.linkInfo[nodeId];
    toLinkInfo?.fibers[fiberId].lambdaAvailability[lambdaId] = status;
  }

  void _processProbReq(Set<ProbSignal> processedReq) {
    // send reserve signal
    Logger.i.log('$node - Process ProbReq: $processedReq');
    List<PathCost> pathCosts = calculatePathCost(processedReq);

    if (pathCosts.isEmpty) {
      // if path cost is empty, then no possible path to be open, thus blocked
      SimulationReporter.i.reportBlocked();
      Logger.i.log(
        'Block detected for ${processedReq.first.lightPathRequest}:all-route',
      );
      return;
    }

    Logger.i.log('Path cost:\n${yamlWriter.write(pathCosts)}');

    // by default user first path
    PathCost selectedCost = pathCosts.first;

    if (pathCosts.length > 1) {
      // if more than one possible path, use one minimun cost
      pathCosts.sort((a, b) {
        final costCompared = a.cost.compareTo(b.cost);

        // result != 0, means costs are different, sort by cost
        if (costCompared != 0) return costCompared;

        // result == 0, means costs are same, sort by hop
        final hopCompared = a.route.length.compareTo(b.route.length);
        return hopCompared;
      });

      selectedCost = pathCosts.first; // Minimum PathCost
      final sameCosts = pathCosts.where(
        (pathCost) =>
            pathCost.cost == selectedCost.cost &&
            pathCost.route.length == selectedCost.route.length,
      );

      // if not only one minimum cost
      if (sameCosts.length != 1) {
        final randomCostId = _random.nextInt(sameCosts.length);
        selectedCost = sameCosts.elementAt(randomCostId);
      }
    }

    _sentEvent(
      node.id,
      ResvSignal(
        lightPathRequest: selectedCost.lightPathRequest,
        selectedLambda: selectedCost.lambdaId,
        route: selectedCost.route,
      ),
    );
    Logger.i.log(
      '$node - ${processedReq.first.lightPathRequest} select lamda:${selectedCost.lambdaId}, route:${selectedCost.route}, cost:${selectedCost.cost}',
    );
  }

  List<PathCost> calculatePathCost(Set<ProbSignal> processedReq) {
    final pathCosts = <PathCost>[];
    for (var probReq in processedReq) {
      // for each route, represented by diff ProbReq
      for (var lambdaId = 0; lambdaId < expParam.lambdaCount; lambdaId++) {
        final hopCosts = probReq.linkInfo.values.map(
          (e) {
            final fiberCountWithUsedLambda = e.fibers
                .where(
                  (fiber) =>
                      fiber.lambdaAvailability[lambdaId] == Availability.used,
                )
                .length;
            if (fiberCountWithUsedLambda == e.fibers.length) {
              return double.maxFinite;
            }

            final usedLambdaCount = e.fibers.fold(
              0,
              (prev, fiber) =>
                  prev +
                  fiber.lambdaAvailability
                      .where((lambda) => lambda == Availability.used)
                      .length,
            );
            final totalLamdaXFiber = expParam.fiberCount * expParam.lambdaCount;
            return fiberCountWithUsedLambda *
                usedLambdaCount /
                totalLamdaXFiber;
          },
        );
        final cost = hopCosts.any((cost) => cost == double.maxFinite)
            ? double.maxFinite
            : hopCosts.fold(0.0, (prev, cost) => prev + cost);

        /// not need to add cost if it's maximum
        if (cost == double.maxFinite) continue;

        pathCosts.add(
          PathCost(
            lightPathRequest: probReq.lightPathRequest,
            route: probReq.route,
            lambdaId: lambdaId,
            cost: cost,
          ),
        );
      }
    }

    return pathCosts;
  }

  void stop() {
    _listener?.cancel();
    _streamController?.close();
    _streamController = null;
  }
}
