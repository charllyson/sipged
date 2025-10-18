import 'package:flutter/material.dart';

class AutoIcon extends StatelessWidget {
  const AutoIcon({
    required this.nameOrUrl,
    super.key,
  });

  final String nameOrUrl;

  /// Extrai a extensão de forma robusta (minúscula), ignorando query/hash e espaços.
  String _extractExt(String input) {
    var s = input.trim();

    // remove query e hash
    final q = s.indexOf('?');
    if (q != -1) s = s.substring(0, q);
    final h = s.indexOf('#');
    if (h != -1) s = s.substring(0, h);

    // pega só o último segmento do path
    s = s.split('/').last.trim();

    // match da última extensão no fim da string
    final m = RegExp(r'\.([a-z0-9]+)$', caseSensitive: false).firstMatch(s);
    if (m == null) return '';
    return '.${m.group(1)!.toLowerCase()}';
  }

  @override
  Widget build(BuildContext context) {
    final ext = _extractExt(nameOrUrl); // ex.: ".kml"

    switch (ext) {
      case '.pdf':
        return const Icon(Icons.picture_as_pdf);
      case '.kml':
        return const Icon(Icons.terrain); // KML
      case '.kmz':
        return const Icon(Icons.layers); // KMZ
      case '.geojson':
        return const Icon(Icons.public); // GeoJSON
      case '.json':
        return const Icon(Icons.public);
      case '.png':
        return const Icon(Icons.image);
      case '.jpg':
        return const Icon(Icons.image);
      case '.jpeg':
        return const Icon(Icons.image);
      case '.gif':
        return const Icon(Icons.image);
      case '.webp':
        return const Icon(Icons.image);
      case '.doc':
        return const Icon(Icons.description);
      case '.docx':
        return const Icon(Icons.description);
      case '.xls':
        return const Icon(Icons.table_chart);
      case '.xlsx':
        return const Icon(Icons.table_chart);
      case '.csv':
        return const Icon(Icons.table_chart);
      case '.ppt':
        return const Icon(Icons.slideshow);
      case '.pptx':
        return const Icon(Icons.slideshow);
      case '.zip':
        return const Icon(Icons.archive);
      case '.rar':
        return const Icon(Icons.archive);
      case '.7z':
        return const Icon(Icons.archive);
      case '.txt':
        return const Icon(Icons.text_snippet);
      case '.md':
        return const Icon(Icons.notes);
      default:
        return const Icon(Icons.insert_drive_file);
    }  }
}
