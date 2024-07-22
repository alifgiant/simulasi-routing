import 'dart:async';
import 'dart:math';

import 'package:routing_nanda/src/usecases/validate_config_usecase.dart';
import 'package:routing_nanda/src/utils/logger.dart';

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
      // Generate inter-arrival time using exponential distribution
      double u = _random.nextDouble();
      double interArrivalTime = -log(1 - u) / expParam.rateOfRequest;
      Logger.i.log(
        '$node-$requestIndex-interArrivalTime: $interArrivalTime >> rateOfRequest: ${expParam.rateOfRequest}',
      );

      // Wait for the inter-arrival time
      await Future.delayed(
        Duration(microseconds: (interArrivalTime * 1000000).round()),
      );

      // Generate holding time using exponential distribution
      double holdingTime = -expParam.holdTime * log(1 - _random.nextDouble());
      Logger.i.log(
        '$node-$requestIndex-holdingTime: $interArrivalTime >> holdTime: ${expParam.holdTime}',
      );

      yield LightPathRequest(id: requestIndex, holdTime: holdingTime);
      requestIndex += 1;
    }
  }

  void run(ExperimentParams expParam) {
    listener = generateRequests(expParam).listen(
      (req) {
        Logger.i.log('Lightpath request ${req.id} received');
        Logger.i.log('Step 2: Collecting information by signaling');
        Logger.i.log('Step 3: Route and wavelength selection');
      },
    );
  }

  void stop() {
    listener?.cancel();
  }
}
