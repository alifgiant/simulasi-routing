import 'package:routing_nanda/src/core/circle_data.dart';
import 'package:routing_nanda/src/core/light_path.dart';
import 'package:routing_nanda/src/utils/logger.dart';

class SetupNetworkConfigUsecase {
  ConfigResult start({
    required int fiberCount,
    required int lambdaCount,
    required Map<int, CircleData> circlesMap,
    required Map<int, Set<int>> linksMap,
  }) {
    Logger.i.log('Configuring Network ...');

    final lightpaths = <String, LightPath>{};
    for (var connection in linksMap.entries) {
      final source = connection.key;
      final targets = connection.value;
      for (var target in targets) {
        for (var fiberI = 0; fiberI < fiberCount; fiberI++) {
          for (var lambdaI = 0; lambdaI < lambdaCount; lambdaI++) {
            lightpaths['$source:$target:$fiberI:$lambdaI'] = LightPath(
              source: source,
              target: target,
              fiber: fiberI,
              lambda: lambdaI,
            );
            // lightpaths.add(LightPath(
            //   source: source,
            //   target: target,
            //   fiber: fiberI,
            //   lambda: lambdaI,
            // ));
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
    Logger.i.log('Network Configured: \n${yamlWriter.write(
      {
        'Nodes': circlesMap.values,
        'Total Node': circlesMap.length,
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
      circlesMap: circlesMap,
      linksMap: linksMap,
    );
  }
}

class ConfigResult {
  final Map<String, LightPath> lightpaths;
  final Map<int, CircleData> circlesMap;
  final Map<int, Set<int>> linksMap;
  final Map<int, Set<int>> reversedLinksMap;

  ConfigResult({
    required this.lightpaths,
    required this.circlesMap,
    required this.linksMap,
  }) : reversedLinksMap = {} {
    // setup reverse link
    for (var entry in linksMap.entries) {
      final source = entry.key;
      for (var target in entry.value) {
        final reverseSet = reversedLinksMap[target] ?? {};
        reverseSet.add(source);
        reversedLinksMap[target] = reverseSet;
      }
    }
  }
}
