import 'package:flutter/material.dart';
import 'package:routing_nanda/src/debouncer.dart';

import 'circle_data.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Map<int, CircleData> circles = {};
  final Map<int, Set<int>> connections = {};
  final Debouncer debouncer = Debouncer();

  @override
  void dispose() {
    super.dispose();
    debouncer.dispose();
  }

  bool isDragging = false;
  double offeredLoad = 0.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Routing Simulation')),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 3,
            child: Builder(
              builder: (ctx) => Padding(
                padding: const EdgeInsets.only(
                  left: 20,
                  right: 20,
                  bottom: 20,
                ),
                child: Stack(
                  children: [
                    GestureDetector(
                      onTapUp: onTapCanvas,
                      onPanUpdate: (details) => setState(() {
                        for (var circle in circles.values) {
                          circle.position += details.delta;
                        }
                      }),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.grey.shade300,
                        ),
                      ),
                    ),
                    CustomPaint(
                      painter: LinePainter(circles, connections),
                    ),
                    ...drawNode(ctx),
                    if (isDragging)
                      Positioned(
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
                          onAcceptWithDetails: (detail) {
                            setState(() => circles.remove(detail.data.id));
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
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
                            decoration: const InputDecoration(
                              hintText: 'contoh: 0-1, 2-3, 1-2',
                              hintStyle: TextStyle(color: Colors.black38),
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 3,
                            onChanged: onConnectionChanged,
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
                              width: 42,
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
                              width: 42,
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
                              offeredLoad.toString(),
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                          Slider(
                            value: offeredLoad,
                            divisions: 100,
                            onChanged: (val) =>
                                setState(() => offeredLoad = val),
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
          ),
          const SizedBox(width: 20),
        ],
      ),
    );
  }

  void onConnectionChanged(String s) {
    debouncer.start(() {
      final splitted = s.split(',');
      Map<int, Set<int>> newCons = {};
      for (var element in splitted) {
        final trimmed = element.trim();
        final nodes = trimmed.split('-').map(int.tryParse);
        if (nodes.any((n) => n == null) || nodes.length != 2) {
          continue;
        }

        final source = nodes.first! < nodes.last! ? nodes.first! : nodes.last!;
        final target = nodes.first! < nodes.last! ? nodes.last! : nodes.first!;

        final currentCons = newCons[source] ?? {};
        currentCons.add(target);
        newCons[source] = currentCons;
      }
      setState(() {
        connections
          ..clear()
          ..addAll(newCons);
      });
    });
  }

  Iterable<Widget> drawNode(BuildContext ctx) {
    return circles.values.map(
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
            child: node,
            onDragUpdate: (details) {
              final localPosition = circle.position + details.delta;
              setState(() {
                circle.position = localPosition;
                isDragging = true;
              });
            },
            onDragEnd: (detail) {
              RenderBox renderBox = ctx.findRenderObject() as RenderBox;
              Offset localPosition = renderBox.globalToLocal(
                // add offset to counter removed top padding
                detail.offset + const Offset(0, 20),
              );
              setState(() {
                circle.position = localPosition;
                isDragging = false;
              });
            },
          ),
        );
      },
    );
  }

  void onTapCanvas(TapUpDetails tapDetail) {
    final id = circles.isEmpty ? 0 : circles.keys.last + 1;
    final newCircle = CircleData(id, tapDetail.localPosition);
    setState(() => circles[id] = newCircle);
  }
}

class LinePainter extends CustomPainter {
  final Map<int, CircleData> circles;
  final Map<int, Set<int>> connections;

  const LinePainter(this.circles, this.connections);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 2.0;

    for (final circleId in connections.keys) {
      final cons = connections[circleId];
      final startCircle = circles[circleId];
      if (cons == null || startCircle == null) continue;

      for (final otherCircleId in cons) {
        final endCircle = circles[otherCircleId];
        if (endCircle == null) continue;

        canvas.drawLine(
          startCircle.position,
          endCircle.position,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

extension ContextExt on BuildContext {
  // configuration
  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => theme.colorScheme;
}
