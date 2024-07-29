import 'package:flutter/foundation.dart';
import 'package:routing_nanda/src/utils/logger.dart';

class Node {
  final int id;

  /// {
  ///    Node_Target : RouteInfo{
  ///       - toId
  ///       - route options:
  ///         - {1 -> 2 -> 3},
  ///         - {1 -> 2}
  ///    }
  /// }
  final Map<int, RouteInfo> routeInfos;

  /// {
  ///    Node_Target : {
  ///       fiber_id : {
  ///           wave_id : True,   // free/available
  ///           wave_id2 : False, // used
  ///       },
  ///       fiber_id2 : {
  ///           wave_id : True,   // free/available
  ///           wave_id2 : False, // used
  ///       },
  ///    }
  /// }
  final Map<int, LinkInfo> linkInfo;

  Node({
    required this.id,
    required this.routeInfos,
    required this.linkInfo,
  });

  @override
  String toString() => 'Node($id)';

  Map<String, dynamic> toJson() {
    return {
      toString(): {
        for (final entry in routeInfos.entries)
          entry.key.toString(): entry.value.routeOptions.map(
            (e) => e.toString(),
          ),
      },
    };
  }
}

class RouteInfo {
  final int toNodeId;
  final Set<RouteOptions> routeOptions;

  RouteInfo({
    required this.toNodeId,
    required this.routeOptions,
  });
}

class RouteOptions {
  final Set<int> nodeIdSteps;

  const RouteOptions({
    required this.nodeIdSteps,
  });

  int get length => nodeIdSteps.length;

  @override
  String toString() => nodeIdSteps.join('->');

  @override
  int get hashCode => nodeIdSteps.fold(
        1,
        (prev, element) => prev ^ element.hashCode,
      );

  @override
  bool operator ==(covariant RouteOptions other) {
    return setEquals(nodeIdSteps, other.nodeIdSteps);
  }
}

class LinkInfo {
  final int toNodeId;
  final List<Fiber> fibers;

  const LinkInfo({
    required this.toNodeId,
    required this.fibers,
  });

  @override
  String toString() => yamlWriter.write({
        'toNodeId': toNodeId,
        'fibers': fibers,
      });
}

class Fiber {
  final int fiberId;
  final List<Availability> lambdaAvailability;

  const Fiber({
    required this.fiberId,
    required this.lambdaAvailability,
  });

  @override
  String toString() => yamlWriter.write({
        'fiberId': fiberId,
        'wavelength availability': {
          for (var item in lambdaAvailability.indexed)
            'w${item.$1.toString()}': item.$2.name,
        },
      });
}

enum Availability { used, available }
