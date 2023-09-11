import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../screen/root.dart';
import '../screen/topology.dart';
import 'routes.dart';

final routerProvider = Provider(
  (ref) {
    return GoRouter(
      initialLocation: Routes.root,
      debugLogDiagnostics: true,
      routes: [
        GoRoute(
          path: Routes.root,
          builder: (context, state) => const RootScreen(),
        ),
        GoRoute(
          path: Routes.editTopology,
          builder: (context, state) => const TopologyScreen(),
        ),
      ],
    );
  },
);
