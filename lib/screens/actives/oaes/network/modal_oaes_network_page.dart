import 'package:flutter/material.dart';
import '../../../../_blocs/actives/oaes_bloc.dart';
import '../../../../_widgets/map/markers/tagged_marker.dart';
import '../../../../_datas/actives/oaes/oaesData.dart';
import '../../../../_widgets/map/shimmer/map_loading_shimmer.dart';
import '../../../../_widgets/map/map_generic_interactive.dart';
import '../../../../_widgets/map/markers/animated_cluster_marker_widget.dart';
import 'package:sisged/screens/commons/upBar/up_bar.dart';
import 'package:sisged/screens/commons/footBar/foot_bar.dart';

class ModalOAEsNetworkPage extends StatefulWidget {
  final List<String>? selectedRegionNames;
  final void Function(String?)? onRegionTap;
  final double? height;

  const ModalOAEsNetworkPage({
    super.key,
    this.selectedRegionNames,
    this.onRegionTap,
    this.height = 320,
  });

  @override
  State<ModalOAEsNetworkPage> createState() => _ModalOAEsNetworkPageState();
}

class _ModalOAEsNetworkPageState extends State<ModalOAEsNetworkPage> {
  bool _loading = true;
  final List<TaggedChangedMarker<OaesData>> _markers = [];

  late OaesBloc _oaesBloc;

  @override
  void initState() {
    super.initState();
    _oaesBloc = OaesBloc();
    _carregarOAEs();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _carregarOAEs() async {
    setState(() => _loading = true);
    try {
      final oaesList = await _oaesBloc.getAllOAEs();

      // 🔍 VERIFICAÇÃO DE ORDENS DUPLICADAS
      final ordersMap = <int, List<OaesData>>{};
      for (final oae in oaesList) {
        final key = oae.order ?? -1;
        ordersMap.putIfAbsent(key, () => []).add(oae);
      }

      ordersMap.forEach((order, lista) {
        if (lista.length > 1) {
          print('\n⚠️ Ordem duplicada: $order → ${lista.length} registros:');
          for (var o in lista) {
            print('  - id=${o.id}, name=${o.identificationName}, lat=${o.latitude}, lng=${o.longitude}');
          }
        }
      });

      // ✅ CONVERSÃO PARA MARKERS
      final markersConvertidos = oaesList
          .map((oae) => oae.toTaggedMarker())
          .whereType<TaggedChangedMarker<OaesData>>() // filtra nulos
          .toList();

      setState(() {
        _markers
          ..clear()
          ..addAll(markersConvertidos);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OAEs carregados com sucesso')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar OAEs: $e')),
        );
      }
    }
    setState(() => _loading = false);
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Overlay(
        initialEntries: [
          OverlayEntry(
            builder: (context) => Column(
              children: [
                const UpBar(),
                Expanded(
                  child: _loading
                      ? const MapLoadingShimmer()
                      : MapInteractivePage<OaesData>(
                    taggedMarkers: _markers,
                    clusterWidgetBuilder: (
                        markers,
                        selected,
                        onSelect,
                        ) {
                      return AnimatedClusterMarkerLayer<OaesData>(
                        taggedMarkers: markers,
                        selectedMarkerPosition: selected,
                        onMarkerSelected: onSelect,
                          markerBuilder: (context, tagged) {
                            final nota = tagged.data.score?.toDouble() ?? 0;
                            final order = tagged.data.order?.toString() ?? '';

                            return Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                border: Border.all(
                                  color: OaesData.getColorByNota(nota),
                                  width: 4,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                order,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            );
                          },
                          titleBuilder: (data) => data.identificationName ?? 'Sem nome',
                        subTitleBuilder: (data) => data.state ?? 'Não identificado',
                      );
                    },
                  ),
                ),
                const FootBar(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
