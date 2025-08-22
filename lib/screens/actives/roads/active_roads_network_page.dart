import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sisged/_widgets/map/map_interactive.dart';
import 'package:sisged/_widgets/map/shimmer/map_loading_shimmer.dart';
import 'package:sisged/screens/commons/footBar/foot_bar.dart';
import 'package:sisged/screens/commons/upBar/up_bar.dart';
import 'active_roads_controller.dart';

class ActiveRoadsNetworkPage extends StatefulWidget {
  final List<String>? selectedRegionNames;
  final void Function(String?)? onRegionTap;
  final double? height;

  const ActiveRoadsNetworkPage({
    super.key,
    this.selectedRegionNames,
    this.onRegionTap,
    this.height = 320,
  });

  @override
  State<ActiveRoadsNetworkPage> createState() => _ActiveRoadsNetworkPageState();
}

class _ActiveRoadsNetworkPageState extends State<ActiveRoadsNetworkPage> {
  bool _bootstrapped = false;

  Future<void> _bootstrapOnce(BuildContext context) async {
    if (_bootstrapped) return;
    _bootstrapped = true;

    final controller = context.read<ActiveRoadsController>();

    // Anexa o overlay para tooltips
    final overlay = Overlay.of(context);
    controller.attachOverlay(overlay);

    // Carrega dados se necessário
    if (controller.roadDataMap.isEmpty && !controller.loading) {
      await controller.load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rodovias carregadas com sucesso')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ActiveRoadsController(),
      builder: (context, _) {
        // Executa bootstrap após o primeiro frame
        WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrapOnce(context));

        return Scaffold(
          backgroundColor: Colors.white,
          body: Stack(
            children: [
              Consumer<ActiveRoadsController>(
                builder: (context, controller, __) {
                  return Column(
                    children: [
                      const UpBar(),
                      Expanded(
                        child: controller.loading
                            ? const MapLoadingShimmer()
                            : ValueListenableBuilder<String?>(
                          valueListenable: controller.selectedPolylineId,
                          builder: (context, selectedId, _) {
                            final styledPolylines = controller.buildStyledPolylines();
                            return MapInteractivePage(
                              tappablePolylines: styledPolylines,
                              onClearPolylineSelection: () async => controller.clearSelection(),
                              onSelectPolyline: (poly) async =>
                                  controller.selectPolylineByTag(poly.tag?.toString()),
                              onShowPolylineTooltip: ({
                                required BuildContext context,
                                required Offset position,
                                required Object? tag,
                              }) async {
                                final strTag = tag?.toString();
                                if (strTag != null) {
                                  controller.showPolylineTooltip(
                                    context: context,
                                    position: position,
                                    tag: strTag,
                                  );
                                }
                              },
                            );
                          },
                        ),
                      ),
                      const FootBar(),
                    ],
                  );
                },
              ),
              // seus fab/overlays adicionais aqui
            ],
          ),
        );
      },
    );
  }
}
