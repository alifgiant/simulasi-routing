import 'package:routing_nanda/src/core/node.dart';
import 'package:routing_nanda/src/usecases/setup_exp_config_usecase.dart';
import 'package:routing_nanda/src/utils/logger.dart';

class RouteFinderUsecase {
  Map<int, Node> start(ConfigResult config) {
    final nodes = config.circlesMap.map(
      (key, value) {
        // combine forward and backward link
        final combinedLinks = Map.of(config.linksMap);
        for (final entry in config.reversedLinksMap.entries) {
          combinedLinks[entry.key] = {
            ...?combinedLinks[entry.key],
            ...entry.value,
          };
        }

        return MapEntry(
          key,
          Node.fromCircle(value)
            ..setupRouteMap(
              combinedLinks,
              config.circlesMap.keys.toSet(),
            ),
        );
      },
    );
    Logger.i.log('pre-defined paths:\n${yamlWriter.write(
      nodes.values.map((e) => e.toJson()).toList(),
    )}');
    return nodes;
  }

  void setup() {
    //
  }
}
