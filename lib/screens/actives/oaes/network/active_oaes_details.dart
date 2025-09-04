import 'package:flutter/material.dart';
import 'package:siged/_widgets/map/markers/tagged_marker.dart';
import '../../../../_blocs/actives/oaes/active_oaes_data.dart';

class ActiveOaesDetails extends StatelessWidget {
  const ActiveOaesDetails({
    super.key,
    required this.marker,
    this.onClose,
  });

  final TaggedChangedMarker<ActiveOaesData> marker;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final d = marker.data;

    final entries = <MapEntry<String, String>>[
      MapEntry('Identificação', d.identificationName ?? '-'),
      MapEntry('UF', d.state ?? '-'),
      MapEntry('Município', d.state ?? '-'),
      MapEntry('Nota', (d.score != null) ? d.score!.toStringAsFixed(1) : '-'),
      MapEntry('Ordem', d.order?.toString() ?? '-'),
      MapEntry(
        'Coordenadas',
        '${marker.point.latitude.toStringAsFixed(5)}, ${marker.point.longitude.toStringAsFixed(5)}',
      ),
      ...marker.properties.entries.map(
            (e) => MapEntry(e.key, e.value?.toString() ?? ''),
      ),
    ];

    return Column(
      children: [
        _PanelHeader(
          title: d.identificationName ?? 'Detalhes da OAE',
          onClose: onClose,
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: entries.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (ctx, i) {
              final kv = entries[i];
              return ListTile(
                dense: true,
                title: Text(
                  kv.key,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(kv.value),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PanelHeader extends StatelessWidget {
  const _PanelHeader({this.title, this.onClose});
  final String? title;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title ?? 'Detalhes',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          IconButton(
            tooltip: 'Fechar',
            icon: const Icon(Icons.close_rounded),
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}
