import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:sipged/_widgets/map/markers/marker_changed_data.dart';

/// Camada responsável por renderizar:
/// 1. markers com cluster/custom builder
/// 2. markers extras simples
///
/// Refatorações aplicadas:
/// - seleção do marker via [ValueListenable], evitando rebuild amplo da página;
/// - suporte a builder reativo apenas quando a seleção mudar;
/// - isolamento dos markers extras com [RepaintBoundary];
/// - comentários e estrutura mais previsível.
class MarkerChangedLayer<T> extends StatelessWidget {
  /// Lista principal de markers tipados.
  final List<MarkerChangedData<T>>? taggedMarkers;

  /// Builder externo responsável por desenhar cluster/markers customizados.
  ///
  /// Mantido compatível com sua API atual:
  /// - lista dos markers
  /// - posição selecionada atual
  /// - callback ao selecionar marker
  final Widget Function(
      List<MarkerChangedData<T>> taggedMarkers,
      LatLng? selectedMarkerPosition,
      ValueChanged<MarkerChangedData<T>> onMarkerSelected,
      )? clusterWidgetBuilder;

  /// Seleção reativa do marker atual.
  ///
  /// Isso evita usar `setState` na tela principal apenas para trocar seleção.
  final ValueListenable<LatLng?> selectedMarkerPositionVN;

  /// Callback disparado quando um marker é selecionado.
  final ValueChanged<MarkerChangedData<T>> onMarkerSelected;

  /// Markers extras independentes (não clusterizados).
  final List<Marker>? extraMarkers;

  const MarkerChangedLayer({
    super.key,
    required this.taggedMarkers,
    required this.clusterWidgetBuilder,
    required this.selectedMarkerPositionVN,
    required this.onMarkerSelected,
    required this.extraMarkers,
  });

  @override
  Widget build(BuildContext context) {
    final tagged = taggedMarkers;
    final clusterBuilder = clusterWidgetBuilder;
    final extras = extraMarkers;

    final hasTaggedLayer =
        tagged != null && tagged.isNotEmpty && clusterBuilder != null;
    final hasExtraLayer = extras != null && extras.isNotEmpty;

    if (!hasTaggedLayer && !hasExtraLayer) {
      return const SizedBox.shrink();
    }

    final children = <Widget>[
      if (hasTaggedLayer)
        _ReactiveClusterLayer<T>(
          taggedMarkers: tagged,
          selectedMarkerPositionVN: selectedMarkerPositionVN,
          onMarkerSelected: onMarkerSelected,
          clusterWidgetBuilder: clusterBuilder,
        ),

      if (hasExtraLayer)
        IgnorePointer(
          ignoring: true,
          child: RepaintBoundary(
            child: MarkerLayer(markers: extras),
          ),
        ),
    ];

    if (children.length == 1) return children.first;

    return Stack(children: children);
  }
}

/// Sub-widget reativo isolado apenas para a parte que depende da seleção.
///
/// Assim, quando o marker selecionado muda, não precisamos reconstruir tudo
/// que estiver acima dessa camada no mapa.
class _ReactiveClusterLayer<T> extends StatelessWidget {
  final List<MarkerChangedData<T>> taggedMarkers;
  final ValueListenable<LatLng?> selectedMarkerPositionVN;
  final ValueChanged<MarkerChangedData<T>> onMarkerSelected;

  final Widget Function(
      List<MarkerChangedData<T>> taggedMarkers,
      LatLng? selectedMarkerPosition,
      ValueChanged<MarkerChangedData<T>> onMarkerSelected,
      ) clusterWidgetBuilder;

  const _ReactiveClusterLayer({
    required this.taggedMarkers,
    required this.selectedMarkerPositionVN,
    required this.onMarkerSelected,
    required this.clusterWidgetBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<LatLng?>(
      valueListenable: selectedMarkerPositionVN,
      builder: (_, selectedMarkerPosition, __) {
        return RepaintBoundary(
          child: clusterWidgetBuilder(
            taggedMarkers,
            selectedMarkerPosition,
            onMarkerSelected,
          ),
        );
      },
    );
  }
}