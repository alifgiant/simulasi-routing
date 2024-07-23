import 'dart:async';
import 'dart:math';

import 'package:async/async.dart';
import 'package:routing_nanda/src/domain/usecases/validate_config_usecase.dart';
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
    final routeOptions = node.routingMap[targetId];
    if (routeOptions == null) {
      Logger.i.log('ERROR: route option from $node to $targetId is not found');
      return;
    }

    for (var route in routeOptions) {
      final probReq = ProbRequest(
        lightPathRequest: req,
        sourceId: node.id,
        targetId: targetId,
        route: route,
        totalRouteCount: routeOptions.length,
        linkInfo: {},
      );
      final nextNodeId = _attachLinkInfo(probReq);
      _sentEvent(nextNodeId, probReq);
    }

    // // send prob signal
    // Logger.i.log('Step 3: Route and wavelength selection');
    // send signal
  }

  Future<void> onProbRequest(ProbRequest probReq) async {
    if (probReq.targetId == node.id) {
      // final destination arrived
    } else {
      final nextNodeId = _attachLinkInfo(probReq);
      _sentEvent(nextNodeId, probReq);
    }
  }

  Future<void> onResvRequest(ResvRequest req) async {
    // select a fiber based on wavelenght and hold for a duration
  }

  Future<void> onReleaseRequest(ReleaseRequest req) async {
    // release hold immediately
  }

  /// attach current node to next node link info
  /// return next node id
  int _attachLinkInfo(ProbRequest probReq) {
    final nodeIdRoutes = probReq.route.routes.toList();
    int next = nodeIdRoutes[1];
    for (var i = 0; i < nodeIdRoutes.length - 1; i++) {
      final current = nodeIdRoutes[i];
      next = nodeIdRoutes[i + 1];
      if (current != node.id) continue;

      final linkInfoToNext = node.linkInfo[next];
      if (linkInfoToNext == null) continue;

      probReq.linkInfo[node.id] = linkInfoToNext;
    }

    return next;
  }

  void stop() {
    _listener?.cancel();
    _streamController.close();
  }
}
