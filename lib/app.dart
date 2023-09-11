import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

import 'router/router.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      // Use dark or light theme based on system setting.
      themeMode: ThemeMode.system,
      // themeMode: ThemeMode.dark,
      theme: FlexThemeData.light(
        useMaterial3: true,
        scheme: FlexScheme.indigoM3,
        // We use the nicer Material-3 Typography in both M2 and M3 mode.
        typography: Typography.material2021(platform: defaultTargetPlatform),
      ),
      darkTheme: FlexThemeData.dark(
        useMaterial3: true,
        scheme: FlexScheme.indigoM3,
        // We use the nicer Material-3 Typography in both M2 and M3 mode.
        typography: Typography.material2021(platform: defaultTargetPlatform),
      ),
      routerConfig: routerProvider,

      /// make sure that loading can be displayed in front of all other widgets
      builder: EasyLoading.init(),
    );
  }
}
