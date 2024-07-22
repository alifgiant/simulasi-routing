import 'package:routing_nanda/src/data/circle_data.dart';
import 'package:routing_nanda/src/utils/logger.dart';

class SetupNetworkConfigUsecase {
  ConfigResult start({
    required int fiberCount,
    required int lambdaCount,
    required Map<int, CircleData> circlesMap,
    required Map<int, Set<int>> linksMap,
  }) {
    Logger.i.log('Configuring Network ...');
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
        'Total light-path (link x fiber x lambda)':
            linksMap.length * fiberCount * lambdaCount,
      },
    )}');

    return ConfigResult(
      circlesMap: circlesMap,
      linksMap: linksMap,
    );
  }
}

class ConfigResult {
  final Map<int, CircleData> circlesMap;
  final Map<int, Set<int>> linksMap;
  final Map<int, Set<int>> reversedLinksMap;

  ConfigResult({
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
