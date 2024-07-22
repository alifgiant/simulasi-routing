import 'package:routing_nanda/src/core/node.dart';
import 'package:routing_nanda/src/core/node_runner.dart';
import 'package:routing_nanda/src/usecases/setup_exp_config_usecase.dart';
import 'package:routing_nanda/src/utils/logger.dart';
import 'package:routing_nanda/src/utils/utils.dart';

class RouteFinderUsecase {
  Map<int, Node> start(ConfigResult config) {
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

        Node node = Node.fromCircle(value);
        node = NodeMapper(node: node).setupRouteMap(
          config.circlesMap.keys.toSet(),
          combinedLinks,
        );

        return MapEntry(key, node);
      },
    );
    Logger.i.log('pre-defined paths:\n${yamlWriter.write(
      nodes.values.map((e) => e.toJson()).toList(),
    )}');
    return nodes;
  }
}
