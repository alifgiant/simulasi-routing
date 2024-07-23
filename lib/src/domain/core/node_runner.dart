import 'dart:async';
import 'dart:math';

import 'package:async/async.dart';
import 'package:routing_nanda/src/domain/usecases/validate_config_usecase.dart';
import 'package:routing_nanda/src/utils/history_holder.dart';
import 'package:routing_nanda/src/utils/logger.dart';

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
  final Map<ResvRequest, ResvResult> resvRequestHolder = {};

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
      final probReq = ProbRequest(
        lightPathRequest: req,
        sourceId: node.id,
        targetId: targetId,
        route: route,
        totalRouteCount: routeInfo.routeOptions.length,
        linkInfo: {},
      );
      final nextNodeId = _attachLinkInfo(probReq);
      _sentEvent(nextNodeId, probReq);
    }
  }

  Future<void> onProbRequest(ProbRequest probReq) async {
    if (probReq.targetId == node.id) {
      // req arrived in final destination
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
    // select a fiber based on wavelenght and hold for a duration
  }

  /// release holded link when a [req] received
  Future<void> onReleaseRequest(ReleaseRequest req) async {
    final reserveResult = resvRequestHolder[req.resvRequest];
    if (reserveResult == null) return;

    // release link usage
    final fromLinkInfo = node.linkInfo[reserveResult.fromNodeId];
    fromLinkInfo?.fibers[reserveResult.fromFiberIndex]
        .lambdaAvailability[reserveResult.resvRequest.selectedLambda] = true;

    final toLinkInfo = node.linkInfo[reserveResult.toNodeId];
    toLinkInfo?.fibers[reserveResult.toFiberIndex]
        .lambdaAvailability[reserveResult.resvRequest.selectedLambda] = true;
    resvRequestHolder.remove(req.resvRequest);

    final nodeIdRoutes = req.resvRequest.route.nodeIdSteps.toList();
    final lastIndex = nodeIdRoutes.length - 1;

    // start from behind to pass release req to prev node
    for (var i = lastIndex; i > 0; i--) {
      final current = nodeIdRoutes[i];
      if (current != node.id) continue;

      final prevNodeId = nodeIdRoutes[i - 1];
      _sentEvent(prevNodeId, req);
      break;
    }
  }

  /// attach current node to next node link info
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

  void stop() {
    _listener?.cancel();
    _streamController.close();
  }
}

class ResvResult {
  final ResvRequest resvRequest;
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
