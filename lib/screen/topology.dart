import 'package:flutter/material.dart';

class TopologyScreen extends StatelessWidget {
  const TopologyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(runtimeType.toString()),
      ),
    );
  }
}
