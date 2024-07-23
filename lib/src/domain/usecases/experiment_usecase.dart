import 'dart:math';

import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:routing_nanda/src/data/event.dart';
import 'package:routing_nanda/src/domain/core/node.dart';
import 'package:routing_nanda/src/domain/core/node_runner.dart';
import 'package:routing_nanda/src/domain/usecases/validate_config_usecase.dart';
import 'package:routing_nanda/src/utils/history_holder.dart';
import 'package:routing_nanda/src/utils/logger.dart';

final Random _random = Random();

class ExperimentUsecase {
  Map<int, NodeRunner> nodeRunners = {};

  int genRandomTarget(int from) {
    final otherIds = nodeRunners.keys.where((e) => e != from);
    final randomIndex = _random.nextInt(otherIds.length);
    return otherIds.elementAt(randomIndex);
  }

  void sentEvent(int to, Event event) {
    final nodeRunner = nodeRunners[to];
    if (nodeRunner == null) {
      Logger.i.log('ERROR: node target not found');
      return;
    }

    nodeRunner.receive(event);
  }

  Future<void> start(
    Map<int, Node> routingMap,
    ExperimentParams expParam,
  ) async {
    // reset simulation reporter everytime experiment start
    SimulationReporter.i.clear();

    nodeRunners = routingMap.map(
      (key, value) => MapEntry(
        key,
        NodeRunner(
          node: value,
          expParam: expParam,
          genRandomTarget: genRandomTarget,
          sentEvent: sentEvent,
        ),
      ),
    );
    for (var node in nodeRunners.values) {
      node.run();
    }

    // let experiment run for as long as [experimentDuration]
    final targetDuration = Duration(seconds: expParam.experimentDuration);
    final experimentStartTime = DateTime.now();
    Duration passedTime = DateTime.now().difference(experimentStartTime);
    do {
      // update progress every second,
      // because minimal experimentDuration is 10s
      await Future.delayed(const Duration(seconds: 1));
      passedTime = DateTime.now().difference(experimentStartTime);
      final completion =
          passedTime.inMilliseconds / targetDuration.inMilliseconds;
      EasyLoading.showProgress(
        completion <= 1 ? completion : 1,
        status: 'Simulation Running',
        maskType: EasyLoadingMaskType.black,
      );
    } while (passedTime < targetDuration);

    for (var node in nodeRunners.values) {
      node.stop();
    }
  }
}
