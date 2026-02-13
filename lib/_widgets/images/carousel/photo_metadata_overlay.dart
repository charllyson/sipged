// lib/_widgets/carousel/overlays/photo_metadata_overlay.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sipged/_widgets/images/carousel/carousel_metadata.dart' as pm;

class PhotoMetadataOverlay extends StatelessWidget {
  final pm.CarouselMetadata? meta;
  const PhotoMetadataOverlay({super.key, required this.meta});

  @override
  Widget build(BuildContext context) {
    final m = meta;
    final style = const TextStyle(color: Colors.white, fontSize: 12);
    final titleStyle = const TextStyle(
      color: Colors.white,
      fontSize: 12,
      fontWeight: FontWeight.w700,
    );

    final dateStr = (m?.takenAt != null)
        ? DateFormat('dd/MM/yyyy HH:mm').format(m!.takenAt!)
        : '—';

    String fmt(double? v) => v == null ? '—' : v.toStringAsFixed(6);
    final lat = fmt(m?.lat);
    final lng = fmt(m?.lng);

    final device = [
      if ((m?.make ?? '').trim().isNotEmpty) m!.make!,
      if ((m?.model ?? '').trim().isNotEmpty) m!.model!,
    ].join(' ').trim();

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Color(0xCC000000), Color(0x66000000), Colors.transparent],
          stops: [0, 0.5, 1],
        ),
      ),
      child: DefaultTextStyle(
        style: style,
        child: Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            _kv('Data/hora', dateStr, titleStyle, style),
            _kv('Latitude', lat, titleStyle, style),
            _kv('Longitude', lng, titleStyle, style),
            _kv('Dispositivo', device.isEmpty ? '—' : device, titleStyle, style),
            if (m?.orientation != null)
              _kv('Orientação EXIF', '${m!.orientation}', titleStyle, style),
          ],
        ),
      ),
    );
  }

  Widget _kv(String k, String v, TextStyle ks, TextStyle vs) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$k: ', style: ks),
        Text(v, style: vs),
      ],
    );
  }
}
