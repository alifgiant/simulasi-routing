import 'package:routing_nanda/src/core/node.dart';
import 'package:routing_nanda/src/core/node_runner.dart';
import 'package:routing_nanda/src/usecases/setup_exp_config_usecase.dart';
import 'package:routing_nanda/src/utils/logger.dart';
import 'package:routing_nanda/src/utils/utils.dart';

class RouteFinderUsecase {
  Map<int, Node> start(
    ConfigResult config,
    int fiberCount,
    int lambdaCount,
  ) {
    final nodes = config.circlesMap.map(
      (key, value) {
        // combine forward and backward link
        final combinedLinks = config.linksMap.deepCopy();
        for (final entry in config.reversedLinksMap.entries) {
          combinedLinks[entry.key] = {
            ...?combinedLinks[entry.key],
            ...entry.value,
          };
        }
        final nodeMapper = NodeMapper(nodeId: value.id);
        final routeMap = nodeMapper.setupRouteMap(
          config.circlesMap.keys.toSet(),
          combinedLinks,
        );
        final linkMap = nodeMapper.setupLinkMap(
          combinedLinks,
          fiberCount,
          lambdaCount,
        );

        return MapEntry(
          key,
          Node(id: value.id, routingMap: routeMap, linkInfo: linkMap),
        );
      },
    );
    Logger.i.log('pre-defined paths:\n${yamlWriter.write(
      nodes.values.map((e) => e.toJson()).toList(),
    )}');
    return nodes;
  }
}
