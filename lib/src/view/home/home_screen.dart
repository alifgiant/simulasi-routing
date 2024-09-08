import 'package:flutter/material.dart';
import 'package:routing_nanda/src/domain/core/vm.dart';
import 'package:routing_nanda/src/domain/usecases/experiment_usecase.dart';
import 'package:routing_nanda/src/domain/usecases/route_finder_usecase.dart';
import 'package:routing_nanda/src/utils/history_holder.dart';
import 'package:routing_nanda/src/view/history/history_screen.dart';
import 'package:routing_nanda/src/view/home/home_controller.dart';

import '../../data/circle_data.dart';
import '../../domain/usecases/setup_exp_config_usecase.dart';
import '../../domain/usecases/validate_config_usecase.dart';
import '../../utils/line_painter.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return VmView(
      createVm: (context) => HomeController(
        validateParamUsecase: ValidateParamUsecase(),
        setupNetworkConfigUsecase: SetupNetworkConfigUsecase(),
        routeFinderUsecase: RouteFinderUsecase(),
        experimentUsecase: ExperimentUsecase(),
      ),
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
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Routing Simulation'),
            const SizedBox(width: 10),
            FilledButton.tonal(
              onPressed: controller.importConfig,
              child: const Text('Import'),
            ),
            const SizedBox(width: 4),
            FilledButton.tonal(
              onPressed: controller.circlesMap.isNotEmpty
                  ? controller.exportConfig
                  : null,
              child: const Text('Export'),
            ),
          ],
        ),
        actions: [
          IconButton.outlined(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => const HistoryScreen(),
            )),
            icon: const Icon(Icons.history),
          ),
          const SizedBox(width: 12)
        ],
      ),
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
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Durasi Simulasi (detik)'),
                  trailing: Text(
                    controller.experimentDuration.toString(),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                Slider(
                  value: controller.experimentDuration.toDouble(),
                  min: 0,
                  max: 240,
                  divisions: 24,
                  onChanged: controller.changeExperimentDuration,
                ),
                const SizedBox(height: 12),
                ExpansionTile(
                  title: const Text('Koneksi'),
                  tilePadding: EdgeInsets.zero,
                  initiallyExpanded: true,
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
                  title: const Text('Parameter'),
                  tilePadding: EdgeInsets.zero,
                  children: [
                    const SizedBox(height: 4),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Banyak Serat'),
                      trailing: Text(
                        controller.fiberCount.toString(),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    Slider(
                      value: controller.fiberCount.toDouble(),
                      min: 1,
                      max: 24,
                      divisions: 24,
                      onChanged: controller.changeFiber,
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Panjang Gelombang'),
                      trailing: Text(
                        controller.lambdaCount.toString(),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    Slider(
                      value: controller.lambdaCount.toDouble(),
                      min: 1,
                      max: 24,
                      divisions: 24,
                      onChanged: controller.changeLambda,
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Beban Jaringan'),
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
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Rata-rata waktu penggunaan jalur (detik)',
                      ),
                      trailing: Text(
                        controller.holdingTime.toString(),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    Slider(
                      value: controller.holdingTime.toDouble(),
                      min: 1,
                      max: 20,
                      divisions: 10,
                      onChanged: controller.changeHoldTime,
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ],
            ),
          ),
          Builder(
            builder: (context) => FilledButton(
              onPressed: () async {
                await controller.onStartSimulation();
                if (!context.mounted) return;

                final reports = SimulationReporter.i.readReport();

                final success = (reports['success'] ?? 1);
                final blocked = (reports['blocked'] ?? 0);
                final totalRouting = success + blocked;
                final blockingProb = blocked / totalRouting;

                showDialog(
                  context: context,
                  builder: (_) => Dialog(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Simulation Result',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 21),
                          ),
                          const SizedBox(height: 12),
                          ...reports.entries.map(
                            (entry) => Text('${entry.key} = ${entry.value}'),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Blocking Probablity: $blockingProb',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
              style: FilledButton.styleFrom(
                visualDensity: VisualDensity.comfortable,
              ),
              child: const Text('Mulai Simulasi'),
            ),
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
                controller.circlesMap,
                controller.linksMap,
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
        onAcceptWithDetails: controller.onDeleteNode,
      ),
    );
  }

  Iterable<Widget> nodes(BuildContext ctx) {
    return controller.circlesMap.values.map(
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
