// lib/_services/geoJson/import_any_vector.dart
//
// Importador unificado para arquivos vetoriais de linha:
// - .geojson / .json (Feature|FeatureCollection|Line/MultiLine)
// - .kml / .kmz (Placemark LineString/MultiGeometry)
//
// Reaproveita o mesmo Preview (GeoJsonPreviewDialog) e o mesmo saneamento.
//
import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart' as archive;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:xml/xml.dart' as xml;

import 'preview_dialog.dart'; // GeoJsonPreviewDialog

class ImportVector {
  static Future<void> importAny({
    required BuildContext context,
    required String path, // mantido só pra manter assinatura
    required Future<void> Function(
        List<Map<String, dynamic>> linhasPrincipais,
        List<Map<String, dynamic>> geometrias,
        )
    onSalvar,
    required void Function()? onFinished,
    double maxJumpKm = 2.0,
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['geojson', 'json', 'kml', 'kmz'],
      );
      if (result == null) return;

      final file = result.files.first;
      final ext = (file.extension ?? '').toLowerCase();

      // Lê bytes (web/desktop)
      final bytes = file.bytes ?? await File(file.path!).readAsBytes();

      // Converte tudo para uma lista "features" (GeoJSON-like) para reutilizar o Preview
      List<Map<String, dynamic>> features;

      if (ext == 'geojson' || ext == 'json') {
        features = _featuresFromGeoJsonBytes(bytes);
      } else if (ext == 'kml' || ext == 'kmz') {
        features = await _featuresFromKmlOrKmzBytes(bytes, file.name);
      } else {
        _showSnackBar(context, 'Formato não suportado: .$ext');
        return;
      }

      if (features.isEmpty) {
        _showSnackBar(context, 'Nenhuma feature de linha encontrada.');
        return;
      }

      if (!context.mounted) return;

      // Abre o preview comum
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          return GeoJsonPreviewDialog(
            features: features,
            onSalvar: (linhas, tipos, subcolecoes) async {
              // `subcolecoes` esperado: [{'points': [{latitude, longitude}, ...]}, ...]
              final geometrias = <Map<String, dynamic>>[];

              for (final sub in subcolecoes) {
                final rawPoints = (sub['points'] as List?) ?? const [];
                geometrias.add({
                  'geometryType': 'LineString',
                  'points': rawPoints, // já em {latitude, longitude}
                });
              }

              await onSalvar(linhas, geometrias);
              onFinished?.call();

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Importação concluída.')),
                );
              }
            },
          );
        },
      );
    } catch (e) {
      _showSnackBar(context, 'Erro ao importar: $e');
    }
  }

  // ---------- GeoJSON ----------
  static List<Map<String, dynamic>> _featuresFromGeoJsonBytes(List<int> bytes) {
    final Map<String, dynamic> geoJson = json.decode(utf8.decode(bytes));
    if (geoJson['type'] == 'FeatureCollection') {
      final feats = (geoJson['features'] as List?) ?? const [];
      return feats.whereType<Map<String, dynamic>>().toList();
    }
    if (geoJson['type'] == 'Feature') {
      return [geoJson.cast<String, dynamic>()];
    }
    if (geoJson['type'] == 'LineString' || geoJson['type'] == 'MultiLineString') {
      return [
        {
          'type': 'Feature',
          'properties': const <String, dynamic>{},
          'geometry': geoJson,
        }
      ];
    }
    return const <Map<String, dynamic>>[];
  }

  // ---------- KML/KMZ ----------
  static Future<List<Map<String, dynamic>>> _featuresFromKmlOrKmzBytes(
      List<int> bytes,
      String filename,
      ) async {
    // Dependências necessárias no pubspec:
    //   xml: ^6.5.0
    //   archive: ^3.3.7
    // (não causa erro se já existirem)
    try {
      String kmlText;
      if (filename.toLowerCase().endsWith('.kmz')) {
        final archive = _lazyArchiveDecode(bytes);
        final entry = archive.firstWhere(
              (e) => e.name.toLowerCase().endsWith('.kml'),
          orElse: () => throw Exception('KMZ sem .kml interno.'),
        );
        final data = entry.content as List<int>;
        kmlText = utf8.decode(data, allowMalformed: true);
      } else {
        kmlText = utf8.decode(bytes, allowMalformed: true);
      }
      return _featuresFromKmlText(kmlText);
    } catch (e) {
      throw Exception('Erro lendo KML/KMZ: $e');
    }
  }

  static List<Map<String, dynamic>> _featuresFromKmlText(String kmlText) {
    // parse básico de KML (LineString / MultiGeometry com várias LineStrings)
    final xml = _lazyXmlParse(kmlText);

    final placemarks = xml.findAllElements('Placemark');
    final feats = <Map<String, dynamic>>[];

    for (final pm in placemarks) {
      final name = pm.getElement('name')?.innerText ?? '';
      final desc = pm.getElement('description')?.innerText ?? '';

      // ExtendedData simples (Data name/value)
      final props = <String, dynamic>{
        if (name.isNotEmpty) 'name': name,
        if (desc.isNotEmpty) 'description': desc,
      };
      final ext = pm.findElements('ExtendedData');
      for (final ed in ext) {
        for (final d in ed.findAllElements('Data')) {
          final k = d.getAttribute('name') ?? '';
          final v = d.getElement('value')?.innerText ?? '';
          if (k.isNotEmpty) props[k] = v;
        }
      }

      final multi = pm.findElements('MultiGeometry');
      final lineStrings = <List<List<double>>>[];

      void _collectFromNode(dynamic node) {
        for (final ls in node.findAllElements('LineString')) {
          final raw = ls.getElement('coordinates')?.innerText ?? '';
          final coords = _parseKmlCoordinates(raw);
          if (coords.isNotEmpty) lineStrings.add(coords);
        }
      }

      if (multi.isNotEmpty) {
        for (final m in multi) {
          _collectFromNode(m);
        }
      } else {
        _collectFromNode(pm);
      }

      if (lineStrings.isEmpty) continue;

      Map<String, dynamic> geometry;
      if (lineStrings.length == 1) {
        geometry = {'type': 'LineString', 'coordinates': lineStrings.first};
      } else {
        geometry = {'type': 'MultiLineString', 'coordinates': lineStrings};
      }

      feats.add({
        'type': 'Feature',
        'properties': props,
        'geometry': geometry,
      });
    }

    return feats;
  }

  // coords em string: "lon,lat[,alt] lon,lat[,alt] ..."
  static List<List<double>> _parseKmlCoordinates(String text) {
    final parts = text
        .trim()
        .split(RegExp(r'\s+'))
        .where((s) => s.trim().isNotEmpty)
        .toList();
    final coords = <List<double>>[];
    for (final p in parts) {
      final t = p.split(',');
      if (t.length >= 2) {
        final lon = double.tryParse(t[0].trim());
        final lat = double.tryParse(t[1].trim());
        if (lat != null && lon != null) coords.add([lon, lat]);
      }
    }
    return coords;
  }

  // -------- util: xml + zip (carregamento leve) --------
  static dynamic _lazyXmlParse(String xmlText) {
    // para evitar dependência forte no topo do arquivo
    // ignore: avoid_dynamic_calls
    return (XmlDocument.parse(xmlText));
  }

  static dynamic get XmlDocument {
    // ignore: no_leading_underscores_for_local_identifiers
    final _xml = XmlSingleton.instance;
    return _xml.document;
  }

  static dynamic _lazyArchiveDecode(List<int> bytes) {
    // ignore: avoid_dynamic_calls
    return ZipDecoder().decodeBytes(bytes);
  }

  static dynamic get ZipDecoder {
    final _arch = ArchiveSingleton.instance;
    return _arch.zipDecoder;
  }
}

// ---- singletons p/ evitar import estático (ajuda a não quebrar hot-reload) ----
class XmlSingleton {
  XmlSingleton._() {
    // late import
    // ignore: avoid_dynamic_calls
    document = (xml.XmlDocument);
  }
  static final XmlSingleton instance = XmlSingleton._();
  late dynamic document;
}

class ArchiveSingleton {
  ArchiveSingleton._() {
    // ignore: avoid_dynamic_calls
    zipDecoder = (archive.ZipDecoder);
  }
  static final ArchiveSingleton instance = ArchiveSingleton._();
  late dynamic zipDecoder;
}

// snackbar
void _showSnackBar(BuildContext context, String msg) {
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
