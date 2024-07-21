import 'package:flutter/material.dart';
import 'package:routing_nanda/src/home_controller.dart';
import 'package:routing_nanda/src/vm.dart';

import 'circle_data.dart';
import 'line_painter.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return VmView(
      createVm: (context) => HomeController(),
      builder: (controller) => HomeView(controller: controller),
    );
  }
}

class HomeView extends StatelessWidget {
  final HomeController controller;

  const HomeView({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Routing Simulation')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            simulationArea(),
            const SizedBox(width: 20),
            configArea(),
          ],
        ),
      ),
    );
  }

  Widget configArea() {
    return Expanded(
      flex: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ListView(
              children: [
                const Text('Pengaturan', style: TextStyle(fontSize: 21)),
                const SizedBox(height: 4),
                ExpansionTile(
                  title: const Text('Koneksi'),
                  tilePadding: EdgeInsets.zero,
                  children: [
                    const SizedBox(height: 4),
                    TextField(
                      controller: controller.connectionCtlr,
                      decoration: const InputDecoration(
                        hintText: 'contoh: 0-1, 2-3, 1-2',
                        hintStyle: TextStyle(color: Colors.black38),
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      onChanged: controller.onConnectionChanged,
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
                ExpansionTile(
                  title: const Text('Konfigurasi'),
                  tilePadding: EdgeInsets.zero,
                  children: [
                    const SizedBox(height: 4),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Banyak Serat'),
                      trailing: SizedBox(
                        width: 52,
                        child: TextField(
                          textAlign: TextAlign.right,
                          decoration: const InputDecoration(
                            isDense: true,
                            hintText: '1',
                            hintStyle: TextStyle(color: Colors.black38),
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (s) {},
                        ),
                      ),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Panjang Gelombang'),
                      trailing: SizedBox(
                        width: 52,
                        child: TextField(
                          textAlign: TextAlign.right,
                          decoration: const InputDecoration(
                            isDense: true,
                            hintText: '1',
                            hintStyle: TextStyle(color: Colors.black38),
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (s) {},
                        ),
                      ),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Beban'),
                      trailing: Text(
                        controller.offeredLoad.toString(),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    Slider(
                      value: controller.offeredLoad,
                      divisions: 100,
                      onChanged: controller.changeLoad,
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ],
            ),
          ),
          FilledButton(
            onPressed: () {},
            style: FilledButton.styleFrom(
              visualDensity: VisualDensity.comfortable,
            ),
            child: const Text('Mulai Simulasi'),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget simulationArea() {
    return Expanded(
      flex: 3,
      child: Builder(
        builder: (ctx) => Stack(
          children: [
            GestureDetector(
              onTapUp: controller.onTapCanvas,
              onPanUpdate: controller.onPanCanvas,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey.shade300,
                ),
              ),
            ),
            CustomPaint(
              painter: LinePainter(
                controller.circles,
                controller.connections,
              ),
            ),
            ...nodes(ctx),
            if (controller.isDragging) trashBinView(),
          ],
        ),
      ),
    );
  }

  Widget trashBinView() {
    return Positioned(
      left: 10,
      top: 10,
      child: DragTarget<CircleData>(
          builder: (_, __, ___) => Container(
                height: 50,
                width: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.red.shade400,
                    width: 3,
                  ),
                  color: Colors.red.shade100,
                ),
                child: Icon(
                  Icons.delete_rounded,
                  color: Colors.red.shade400,
                ),
              ),
          onAcceptWithDetails: controller.onDeleteNode),
    );
  }

  Iterable<Widget> nodes(BuildContext ctx) {
    return controller.circles.values.map(
      (circle) {
        final node = CircleAvatar(
          radius: 20,
          backgroundColor: Colors.blue,
          child: Text(circle.id.toString()),
        );
        return Positioned(
          left: circle.position.dx - 20,
          top: circle.position.dy - 20,
          child: Draggable<CircleData>(
            data: circle,
            feedback: node,
            childWhenDragging: const SizedBox.shrink(),
            onDragUpdate: (details) => controller.onDragNode(details, circle),
            onDragEnd: (details) => controller.onDragEnd(
              details,
              circle,
              ctx.findRenderObject() as RenderBox,
            ),
            child: node,
          ),
        );
      },
    );
  }
}
