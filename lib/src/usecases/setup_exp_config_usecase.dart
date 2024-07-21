import 'package:routing_nanda/src/core/circle_data.dart';
import 'package:routing_nanda/src/core/light_path.dart';
import 'package:routing_nanda/src/core/node.dart';
import 'package:routing_nanda/src/utils/logger.dart';

class SetupNetworkConfigUsecase {
  ConfigResult start({
    required int fiberCount,
    required int lambdaCount,
    required Map<int, CircleData> circlesMap,
    required Map<int, Set<int>> linksMap,
  }) {
    Logger.i.log('Configuring Network ...');

    final nodes = circlesMap.values.map(Node.fromCircle).toList();
    final lightpaths = <LightPath>[];
    for (var connection in linksMap.entries) {
      final source = connection.key;
      final targets = connection.value;
      for (var target in targets) {
        for (var fiberI = 0; fiberI < fiberCount; fiberI++) {
          for (var lambdaI = 0; lambdaI < lambdaCount; lambdaI++) {
            lightpaths.add(LightPath(
              source: source,
              target: target,
              fiber: fiberI,
              lambda: lambdaI,
            ));
          }
        }
      }
    }
    final links = linksMap.entries.fold(
      [],
      (prev, entry) =>
          prev +
          entry.value
              .map((target) => 'Node(${entry.key}) <-> Node($target)')
              .toList(),
    );
    Logger.i.log('Network Configured: \n${stringYamlWriter.write(
      {
        'Nodes': nodes,
        'Total Node': nodes.length,
        'Links': links,
        'Total Link': linksMap.values.fold(
          0,
          (prev, link) => prev + link.length,
        ),
        'Total light-path (link x fiber x lambda)': lightpaths.length,
      },
    )}');

    return ConfigResult(
      lightpaths: lightpaths,
      nodes: nodes,
      linksMap: linksMap,
    );
  }
}

class ConfigResult {
  final List<LightPath> lightpaths;
  final List<Node> nodes;
  final Map<int, Set<int>> linksMap;

  ConfigResult({
    required this.lightpaths,
    required this.nodes,
    required this.linksMap,
  });
}
