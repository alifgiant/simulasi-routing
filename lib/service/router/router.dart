import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../screen/edit_topology_page.dart';
import '../../screen/experiment_page.dart';
import '../../screen/view_page.dart';
import '../../screen/visualization_page.dart';
import 'routes.dart';

final routerProvider = GoRouter(
  initialLocation: Routes.root,
  debugLogDiagnostics: true,
  routes: [
    ShellRoute(
      builder: (BuildContext context, GoRouterState state, Widget child) {
        return Scaffold(
          body: Row(children: [
            // Expanded(child: VisualizationPage()),
            const Expanded(child: TreeViewPage()),
            Expanded(child: child),
          ]),
        );
      },
      routes: <RouteBase>[
        GoRoute(
          path: Routes.root,
          builder: (context, state) => const EditTopologyPage(),
        ),
        GoRoute(
          path: Routes.editTopology,
          builder: (context, state) => const ExperimentPage(),
        ),
      ],
    ),
  ],
);
