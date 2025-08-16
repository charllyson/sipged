import 'package:flutter/material.dart';
import '../../../../_blocs/actives/road_bloc.dart';
import '../../../../_widgets/map/map_generic_interactive.dart';
import '../../../../_widgets/map/shimmer/map_loading_shimmer.dart';
import '../../../../_datas/actives/roads/road_data.dart';
import '../../../commons/upBar/up_bar.dart';
import '../../../commons/footBar/foot_bar.dart';
import 'modal/modal_info_on_tap_road.dart';
import 'tooltip/map_tooltip_overlay_widget.dart';

class ModalRoadNetworkPage extends StatefulWidget {
  final List<String>? selectedRegionNames;
  final void Function(String?)? onRegionTap;
  final double? height;

  const ModalRoadNetworkPage({
    super.key,
    this.selectedRegionNames,
    this.onRegionTap,
    this.height = 320,
  });

  @override
  State<ModalRoadNetworkPage> createState() => _ModalRoadNetworkPageState();
}

class _ModalRoadNetworkPageState extends State<ModalRoadNetworkPage> {
  bool _loading = true;
  late RoadsBloc _roadsBloc;
  late ValueNotifier<String?> _selectedPolylineIdNotifier;
  late OverlayState _overlayState;

  @override
  void initState() {
    super.initState();
    _roadsBloc = RoadsBloc();
    _selectedPolylineIdNotifier = ValueNotifier<String?>(null);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final overlay = Overlay.of(context);
      _overlayState = overlay;
        });

    _carregarDadosIniciais();
  }

  Future<void> _carregarDadosIniciais() async {
    setState(() => _loading = true);
    try {
      await _roadsBloc.carregarRodoviasDoFirebase();
      _selectedPolylineIdNotifier.value = null;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rodovias carregadas com sucesso')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar rodovias: $e')),
        );
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _selectedPolylineIdNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Overlay(
        initialEntries: [
          OverlayEntry(
            builder: (context) => Stack(
              children: [
                Column(
                  children: [
                    const UpBar(),
                    Expanded(
                      child: _loading
                          ? const MapLoadingShimmer()
                          : ValueListenableBuilder<String?>(
                        valueListenable: _selectedPolylineIdNotifier,
                        builder: (context, selectedId, _) {
                          final styledPolylines =
                          _roadsBloc.gerarPolylinesEstilizadas(
                            selectedId: selectedId,
                          );
                          return MapInteractivePage<RoadData>(
                            tappablePolylines: styledPolylines,
                            onClearPolylineSelection: () async {
                              _selectedPolylineIdNotifier.value = null;
                            },
                            onSelectPolyline: (poly) async {
                              _selectedPolylineIdNotifier.value = poly.tag;
                            },
                              onShowPolylineTooltip: ({
                                required context,
                                required position,
                                required tag,
                              }) async {
                                final road = _roadsBloc.roadDataMap[tag];
                                if (road != null) {
                                  RoadTooltipOverlayLayer.show(
                                    overlayState: _overlayState,
                                    position: position,
                                    road: road,
                                    onVerMais: () {
                                      showDialog(
                                        context: context,
                                        barrierDismissible: true,
                                        builder: (_) => Dialog(
                                          backgroundColor: Colors.transparent,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            height: MediaQuery.of(context).size.height * 0.7,
                                            width: MediaQuery.of(context).size.width * 0.8,
                                            child: RoadDetailsView(road: road),
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                }
                              }
                          );
                        },
                      ),
                    ),
                    const FootBar(),
                  ],
                ),
                /*GeoJsonActionsFloatingButtons(
                  onImportGeoJson: handleImportGeoJson,
                  onDeleteCollection: () => deleteFirstCollectionFirestore(
                    collectionPath: 'actives_roads',
                  ),
                ),*/
              ],
            ),
          ),
        ],
      ),
    );
  }


}

