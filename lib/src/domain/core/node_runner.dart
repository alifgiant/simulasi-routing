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
  final int Function(int from) _genRandomTarget;
  final void Function(int to, Event event) _sentEvent;

  NodeRunner({
    required this.node,
    required int Function(int from) genRandomTarget,
    required void Function(int to, Event event) sentEvent,
  })  : _genRandomTarget = genRandomTarget,
        _sentEvent = sentEvent;

  final StreamController<Event> _streamController = StreamController();
  final Map<LightPathRequest, Set<ProbRequest>> probRequestHolder = {};
  final Map<LightPathRequest, ResvResult> resvRequestHolder = {};

  StreamSubscription<Event>? _listener;

  void receive(Event event) => _streamController.add(event);

  Stream<LightPathRequest> _generateRequests(ExperimentParams expParam) async* {
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
          case ReleaseRequest():
            onReleaseRequest(req);
            break;
        }
      },
    );
  }

  Future<void> onLightPathRequest(LightPathRequest req) async {
    Logger.i.log('Step 2 - $node: Collecting information by signaling');
    final targetId = _genRandomTarget(node.id);
    final routeInfo = node.routeInfos[targetId];
    if (routeInfo == null) {
      Logger.i.log('ERROR: route option from $node to $targetId is not found');
      SimulationReporter.i.reportNoRoute();
      return;
    }

    for (var route in routeInfo.routeOptions) {
      // start prob to each route
      final probReq = ProbRequest(
        lightPathRequest: req,
        route: route,
        totalRouteCount: routeInfo.routeOptions.length,
        linkInfo: {},
      );
      final nextNodeId = _attachLinkInfo(probReq);
      _sentEvent(nextNodeId, probReq);
    }
  }

  Future<void> onProbRequest(ProbRequest probReq) async {
    if (probReq.route.nodeIdSteps.last == node.id) {
      // if req arrived in final destination, try wavelength selection
      // access saved req if any
      final savedReq = probRequestHolder[probReq.lightPathRequest] ?? {};

      final totalCount = probReq.totalRouteCount;
      if (totalCount == savedReq.length + 1) {
        // if all req have arrived, do wavelength selection
        Logger.i.log('Step 3 - $node: Route and wavelength selection');

        // combine all req, new incoming with saved and delete saved placeholder
        final processedReq = {probReq, ...savedReq};
        probRequestHolder.remove(probReq.lightPathRequest);

        // send reserve signal
        // select a fiber based on wavelenght and hold for a duration
        Logger.i.log('processedReq: $processedReq');
      } else {
        // not all request have arrive, store first to use later
        savedReq.add(probReq);
        probRequestHolder[probReq.lightPathRequest] = savedReq;

        Logger.i.log(
          '$node - ProbReq arrived, ${savedReq.length} of $totalCount',
        );
      }
    } else {
      final nextNodeId = _attachLinkInfo(probReq);
      _sentEvent(nextNodeId, probReq);
    }
  }

  Future<void> onResvRequest(ResvRequest req) async {
    final nodeIdRoutes = req.route.nodeIdSteps.toList();
    final lastIndex = nodeIdRoutes.length - 1;

    // start from behind to find next node link
    int toNodeId = -1;
    int toFiberIndex = -1;
    for (var i = lastIndex; i > 0; i--) {
      final current = nodeIdRoutes[i];
      if (current != node.id) continue;

      toNodeId = nodeIdRoutes[i - 1];
      final linkInfo = node.linkInfo[toNodeId];
      if (linkInfo == null) break;

      // find available fiber with given lambda
      final indexedFibers = linkInfo.fibers.indexed.where(
        (item) => item.$2.lambdaAvailability[req.selectedLambda],
      );
      if (indexedFibers.isEmpty) {
        // if fiber not available for given wavelength, thus blocked
        SimulationReporter.i.reportBlocked();

        // propagate release request to previous node
        if (req.fromNodeId != -1) {
          _sentEvent(
            req.fromNodeId,
            ReleaseRequest(lightPathRequest: req.lightPathRequest),
          );
        }
      } else {
        // if fiber still available for given lambda, then
        final randomSelect = _random.nextInt(indexedFibers.length);
        toFiberIndex = indexedFibers.elementAt(randomSelect).$1;

        // propagate resv request
        _sentEvent(
          toNodeId,
          ResvRequest(
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
      false,
    );

    // use link : to
    _changeLinkStatus(
      resvResult.toNodeId,
      resvResult.toFiberIndex,
      req.selectedLambda,
      false,
    );

    if (req.route.nodeIdSteps.first == node.id) {
      // resv [ResvRequest] arrive at start, then link success
      SimulationReporter.i.reportSuccess();

      // spent hold time
      await Future.delayed(req.lightPathRequest.holdTime.toMsDuration());

      // propagate release event
      _sentEvent(
        req.fromNodeId,
        ReleaseRequest(lightPathRequest: req.lightPathRequest),
      );
    }
  }

  /// release holded link when a [req] received
  Future<void> onReleaseRequest(ReleaseRequest req) async {
    final reserveResult = resvRequestHolder[req.lightPathRequest];
    if (reserveResult == null) return;

    // release link usage : from
    _changeLinkStatus(
      reserveResult.fromNodeId,
      reserveResult.fromFiberIndex,
      reserveResult.resvRequest.selectedLambda,
      true,
    );

    // release link usage : to
    _changeLinkStatus(
      reserveResult.toNodeId,
      reserveResult.toFiberIndex,
      reserveResult.resvRequest.selectedLambda,
      true,
    );

    // remove saved req
    resvRequestHolder.remove(req.lightPathRequest);

    // start from behind to pass release req to reserve-from node
    if (reserveResult.fromNodeId == -1) return;
    _sentEvent(reserveResult.fromNodeId, req);
  }

  /// attach current node -> next node link info
  /// return next node id
  int _attachLinkInfo(ProbRequest probReq) {
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

  void _changeLinkStatus(int nodeId, int fiberId, int lambdaId, bool status) {
    final toLinkInfo = node.linkInfo[nodeId];
    toLinkInfo?.fibers[fiberId].lambdaAvailability[lambdaId] = status;
  }

  void stop() {
    _listener?.cancel();
    _streamController.close();
  }
}
